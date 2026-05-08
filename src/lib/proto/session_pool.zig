const SessionPool = @This();
const DcId = @import("../utils.zig").DcId;
const std = @import("std");
const Session = @import("session.zig");
const ClientManager = @import("../client_manager.zig");
const TransportConnector = @import("../transport_connector.zig");
const tl = @import("../tl/api.zig");
const Deserialized = @import("./utils.zig").Deserialized;

const log = std.log.scoped(.mzproto_sessionpool);
const AUTOSCALE_TARGET_INFLIGHT_PER_SESSION: u32 = 8;
const AUTOSCALE_SCALE_UP_COOLDOWN_SECONDS: u64 = 1;

pool: std.ArrayListUnmanaged(struct { *Session, *std.Io.Future(std.Io.Cancelable!void), std.Io.Timestamp }) = .empty,
// How many sessions should always be kept alive
min_sessions: u8 = 0,
// The pool will not create more sessions than the specified value
max_sessions: u8 = 0,
last_autoscale_up: ?std.Io.Timestamp = null,

mutex: std.Io.Mutex = .init,
dc_id: DcId,
auth_key: *const [256]u8,
client_manager: *ClientManager,

check_mutex: std.Io.Mutex = .init,

/// The mutex is assumed to already be acquired.
fn maybeScaleUpLocked(self: *SessionPool, allocator: std.mem.Allocator, io: std.Io) !void {
    if (self.max_sessions == 0 or self.pool.items.len == 0 or self.pool.items.len >= self.max_sessions) {
        return;
    }

    var total_pending: u32 = 0;
    for (self.pool.items) |item| {
        total_pending += item[0].pending_requests.load(.acquire);
    }

    const scale_threshold: u32 = @as(u32, @intCast(self.pool.items.len)) * AUTOSCALE_TARGET_INFLIGHT_PER_SESSION;
    if (total_pending < scale_threshold) {
        return;
    }

    const now = std.Io.Clock.now(.boot, io);
    if (self.last_autoscale_up) |last_up| {
        const cooldown_end = last_up.addDuration(.fromSeconds(AUTOSCALE_SCALE_UP_COOLDOWN_SECONDS) );
        if (cooldown_end.withClock(.boot).compare(.gt, now.withClock(.boot))) {
            return;
        }
    }

    try self.pool.ensureUnusedCapacity(allocator, 1);
    const old_len = self.pool.items.len;
    const session, const future = try self.createSession(allocator, io);
    self.pool.appendAssumeCapacity(.{ session, future, now });
    self.last_autoscale_up = now;

    log.debug("Autoscaled session pool from {d} to {d}, pending requests: {d}", .{ old_len, self.pool.items.len, total_pending });
}

fn createSession(self: *SessionPool, allocator: std.mem.Allocator, io: std.Io) !struct { *Session, *std.Io.Future(std.Io.Cancelable!void) } {
    const session = try allocator.create(Session);
    errdefer allocator.destroy(session);

    try session.init(io, self.client_manager, self.auth_key, self.dc_id, 0);
    errdefer {
        session.destroyRequests(allocator, io);
        session.deinit(io, allocator);
    }

    const future = try allocator.create(std.Io.Future(std.Io.Cancelable!void));
    errdefer {
        future.cancel(io) catch {};
        allocator.destroy(future);
    }

    // future.* = try session.sessionSupervisor(allocator, io, self.transport_connector);
    future.* = try io.concurrent(Session.sessionSupervisor, .{ session, allocator, io });

    return .{ session, future };
}

pub fn setMinSessions(self: *SessionPool, allocator: std.mem.Allocator, io: std.Io, value: u8) !void {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    std.debug.assert(self.max_sessions >= value);

    log.debug("Setting min sessions to {d}", .{value});

    if (self.pool.items.len < value) {
        log.debug("Need to create {d} sessions", .{value - self.pool.items.len});

        try self.pool.ensureUnusedCapacity(allocator, value - self.pool.items.len);

        for (0..value - self.pool.items.len) |_| {
            const session, const future = try self.createSession(allocator, io);
            self.pool.appendAssumeCapacity(.{ session, future, std.Io.Clock.now(.boot, io) });
        }
    }
    self.min_sessions = value;
}

pub fn setMaxSessions(self: *SessionPool, io: std.Io, value: u8) !void {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    std.debug.assert(value >= self.min_sessions);

    log.debug("Setting max sessions to {d}", .{value});

    self.max_sessions = value;
}

fn removeOneOld(self: *SessionPool, io: std.Io) ?struct { *Session, *std.Io.Future(std.Io.Cancelable!void), std.Io.Timestamp } {
    self.mutex.lockUncancelable(io);
    defer self.mutex.unlock(io);

    if (self.min_sessions >= self.pool.items.len) {
        return null;
    }

    for (0..self.pool.items.len) |i| {
        const idx = self.pool.items.len - 1 - i;
        const session, const supervisor, const last_usage = self.pool.items[idx];
        if (std.Io.Clock.now(.boot, io).withClock(.boot).compare(.gt, last_usage.withClock(.boot).addDuration(.{ .clock = .boot, .raw = .fromSeconds(120) }))) {
            _ = self.pool.swapRemove(idx);
            return .{ session, supervisor, last_usage };
        }
    }

    return null;
}

pub fn check(self: *SessionPool, allocator: std.mem.Allocator, io: std.Io) !void {
    try self.check_mutex.lock(io);
    defer self.check_mutex.unlock(io);

    while (self.removeOneOld(io)) |item| {
        const session, const supervisor, _ = item;

        session.gracefulShutdown(io);
        supervisor.cancel(io) catch {};
        session.destroyRequests(allocator, io);
        session.deinit(io, allocator);

        allocator.destroy(supervisor);
        allocator.destroy(session);
    }
}

/// Sends a message to the least busy session in the pool
pub fn send(self: *SessionPool, allocator: std.mem.Allocator, io: std.Io, message: tl.TL) !Deserialized {
    const session = blk: {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);

        if (self.pool.items.len <= 0) {
            log.debug("No active sessions for this pool, creating one", .{});
            std.debug.assert(self.min_sessions > 0);

            try self.pool.ensureUnusedCapacity(allocator, 0);
            const session, const future = try self.createSession(allocator, io);
            self.pool.appendAssumeCapacity(.{ session, future, std.Io.Clock.now(.boot, io) });
            break :blk session;
        }

        try self.maybeScaleUpLocked(allocator, io);

        var match: ?*struct { *Session, *std.Io.Future(std.Io.Cancelable!void), std.Io.Timestamp } = null;
        var num_requests: u32 = std.math.maxInt(u32);
        for (self.pool.items) |*item| {
            const check_requests = item[0].pending_requests.load(.acquire);
            if (check_requests < num_requests) {
                match = item;
                num_requests = check_requests;
            }
        }

        match.?[2] = std.Io.Clock.now(.boot, io);

        break :blk match.?[0];
    };

    return session.send(io, allocator, message, null, false);
}

pub fn deinit(self: *SessionPool, allocator: std.mem.Allocator, io: std.Io, graceful: bool) void {
    // keep the mutex always locked, since this pool shouldn't be used ever again
    self.mutex.lockUncancelable(io);
    self.check_mutex.lockUncancelable(io);

    log.debug("shutting down sessions", .{});

    while (self.pool.pop()) |item| {
        const session, const supervisor, _ = item;
        if (graceful) {
            session.gracefulShutdown(io);
        }
        supervisor.cancel(io) catch {};

        session.destroyRequests(allocator, io);

        session.deinit(io, allocator);

        allocator.destroy(supervisor);
        allocator.destroy(session);
    }
    self.min_sessions = 0;
    self.max_sessions = 0;
    self.pool.deinit(allocator);
}
