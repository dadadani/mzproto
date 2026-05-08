const Dispatcher = @This();
const SessionPool = @import("./session_pool.zig");
const std = @import("std");
const DcId = @import("../utils.zig").DcId;
const TransportConnector = @import("../transport_connector.zig");
const Storage = @import("../storage.zig").Storage;
const tl = @import("../tl/api.zig");
const AuthKey = @import("./auth_key.zig");
const log = std.log.scoped(.mzproto_dispatcher);
const ClientManager = @import("../client_manager.zig");
const Deserialized = @import("./utils.zig").Deserialized;
const SessionPools = struct {
    auth_key: [256]u8,
    main: SessionPool,
    media: SessionPool,

    pub inline fn deinit(self: *SessionPools, allocator: std.mem.Allocator, io: std.Io, graceful: bool) void {
        self.main.deinit(allocator, io, graceful);
        self.media.deinit(allocator, io, graceful);
        allocator.destroy(self);
    }
};

mutex: std.Io.Mutex = .init,
map: std.AutoHashMapUnmanaged(DcId, *SessionPools) = .empty,
main_dc: DcId,
connector: *TransportConnector,
storage: *Storage,
client_manager: *ClientManager,

pub const MessageType = enum {
    common,
    media,
};

pub const Error = error{
    UnavailableDc,
};

/// The mutex is assumed to already be acquired.
fn createPools(self: *Dispatcher, allocator: std.mem.Allocator, io: std.Io, dc: DcId) !*SessionPools {
    if (!self.connector.isAvailable(io, dc)) {
        return Error.UnavailableDc;
    }

    const pools = try allocator.create(SessionPools);
    errdefer allocator.destroy(pools);

    const auth_key = (try self.storage.getDC(io, dc)) orelse key: {
        log.debug("{f} generating new permanent key", .{dc});
        const transport = (try self.connector.connectTo(allocator, io, dc)).?;
        defer transport.deinit(io);

        const gen_key = try AuthKey.generate(allocator, io, transport.transport, dc.id, dc.media, dc.testmode, false, null);

        try self.storage.putDC(allocator, io, dc, gen_key.auth_key);

        break :key gen_key.auth_key;
    };

    pools.* = .{
        .auth_key = auth_key,
        .main = undefined,
        .media = undefined,
    };

    pools.main = SessionPool{
        .dc_id = dc,
        .auth_key = &pools.auth_key,
        .client_manager = self.client_manager,
    };
    pools.media = SessionPool{
        .dc_id = dc,
        .auth_key = &pools.auth_key,
        .client_manager = self.client_manager,
    };

    return pools;
}

pub fn send(self: *Dispatcher, allocator: std.mem.Allocator, io: std.Io, dc: DcId, message_type: MessageType, message: tl.TL) !Deserialized {
    const pool = blk: {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);

        if (self.map.get(dc)) |pools| {
            switch (message_type) {
                .common => break :blk &pools.main,
                .media => break :blk &pools.media,
            }
        } else {
            try self.map.ensureUnusedCapacity(allocator, 1);
            const pools = try self.createPools(allocator, io, dc);
            errdefer pools.deinit(allocator, io, false);
            // TODO: implement tmp_sessions support
            try pools.main.setMaxSessions(io, 1);
            try pools.main.setMinSessions(allocator, io, if (self.main_dc == dc) 1 else 0);

            try pools.media.setMaxSessions(io, 5);
            try pools.media.setMinSessions(allocator, io, 0);
            self.map.putAssumeCapacity(dc, pools);
            switch (message_type) {
                .common => break :blk &pools.main,
                .media => break :blk &pools.media,
            }
        }
    };

    return pool.send(allocator, io, message);
}

pub fn setMainDc(self: *Dispatcher, allocator: std.mem.Allocator, io: std.Io, dc: DcId) !void {
    log.debug("Switching main dc -> {f}", .{dc});
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    if (self.map.get(dc)) |pools| {
        try pools.main.setMinSessions(allocator, io, 1);
    } else {
        try self.map.ensureUnusedCapacity(allocator, 1);
        const pools = try self.createPools(allocator, io, dc);
        errdefer pools.deinit(allocator, io, false);
        // TODO: implement tmp_sessions support
        try pools.main.setMaxSessions(io, 1);
        try pools.main.setMinSessions(allocator, io, 1);

        try pools.media.setMaxSessions(io, 5);
        try pools.media.setMinSessions(allocator, io, 0);
        self.map.putAssumeCapacity(dc, pools);
    }

    if (self.map.get(self.main_dc)) |pools| {
        try pools.main.setMinSessions(allocator, io, 0);
    }

    self.main_dc = dc;
}

pub fn deinit(self: *Dispatcher, allocator: std.mem.Allocator, io: std.Io, graceful: bool) void {
    self.mutex.lockUncancelable(io);

    var it = self.map.iterator();
    while (it.next()) |pools| {
        pools.value_ptr.*.deinit(allocator, io, graceful);
    }
    self.map.deinit(allocator);
}
