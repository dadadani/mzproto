const std = @import("std");

const ClientManager = @This();
const Dispatcher = @import("./proto/dispatcher.zig");
const TransportConnector = @import("../lib/transport_connector.zig");
const DcId = @import("./utils.zig").DcId;
const detectMigrateError = @import("./utils.zig").detectMigrateError;
const Storage = @import("./storage.zig").Storage;
const tl = @import("tl");
const UpdatesManager = @import("./updates_manager.zig");
const bapi = @import("mzproto_bridge");
const clientStatusToUpdate = @import("./api/helpers/updates.zig").clientStatusToUpdate;
pub const Error = error{
    DcUnavailable,
};

const log = std.log.scoped(.mzproto_client);

session_info: struct {
    lock: std.Io.RwLock = .init,

    api_id: u32,
    api_hash: []u8,

    device_model: []u8,
    system_version: []u8,
    app_version: []u8,
    system_lang_code: []u8,
    lang_pack: []u8,
    lang_code: []u8,

    pub inline fn deinit(self: *@This(), allocator: std.mem.Allocator, io: std.Io) void {
        self.lock.lockUncancelable(io);
        allocator.free(self.api_hash);
        allocator.free(self.device_model);
        allocator.free(self.system_version);
        allocator.free(self.app_version);
        allocator.free(self.system_lang_code);
        allocator.free(self.lang_pack);
        allocator.free(self.lang_code);
    }
},

internal: struct {
    lock: std.Io.RwLock = .init,

    /// The datacenter where all the requests should default to
    current_dc: DcId,

    /// The client should switch to this datacenter as the default as soon as possible
    target_dc: ?DcId = null,

    /// The id of the current user
    my_id: ?u64 = null,
    is_bot: bool = false,

    /// Signals when the client switched to the expected dc
    switch_dc_event: std.Io.Event = .unset,

    // Signals when the authorization check is completed
    authorization_check_event: std.Io.Event = .unset,

    client_status: bapi.ClientStatus,
},

dispatcher: Dispatcher,
transport_connector: TransportConnector,
storage: Storage,
updates_manager: UpdatesManager,

/// the lock is assumed to be already acquired (write)
fn pushClientStatusInternal(self: *ClientManager, allocator: std.mem.Allocator, io: std.Io, status: bapi.ClientStatus) void {
    self.internal.client_status = status;

    blk: {
        var update = clientStatusToUpdate(allocator, status) catch |err| {
            log.warn("Failed to create UpdateClientStatus.{s}: {s}", .{ @tagName(status), @errorName(err) });
            break :blk;
        };

        self.updates_manager.updates_queue.putOne(io, update) catch |err| {
            update.deinit(allocator);
            log.warn("Failed to put UpdateClientStatus.{s} to queue: {s}", .{ @tagName(status), @errorName(err) });
        };
    }
}

pub fn pushClientStatus(self: *ClientManager, allocator: std.mem.Allocator, io: std.Io, status: bapi.ClientStatus) void {
    {
        std.log.debug("locking pushClientStatus...", .{});
        self.internal.lock.lock(io) catch return;
        defer {
            std.log.debug("unlocking pushClientStatus...", .{});
            self.internal.lock.unlock(io);
        }
        self.internal.client_status = status;
    }

    blk: {
        std.log.debug("setting python value...", .{});

        var update = clientStatusToUpdate(allocator, status) catch |err| {
            log.warn("Failed to create UpdateClientStatus.{s}: {s}", .{ @tagName(status), @errorName(err) });
            break :blk;
        };

        std.log.debug("putting one...", .{});

        self.updates_manager.updates_queue.putOne(io, update) catch |err| {
            update.deinit(allocator);
            log.warn("Failed to put UpdateClientStatus.{s} to queue: {s}", .{ @tagName(status), @errorName(err) });
        };
        std.log.debug("put ok !!!!...", .{});
    }
}

pub fn importConfig(self: *ClientManager, allocator: std.mem.Allocator, io: std.Io, config: *const tl.Config) !void {
    try self.transport_connector.importConfig(allocator, io, config);
    {
        std.debug.print("locking importConfig...\n", .{});
        try self.internal.lock.lock(io);
        defer {
            std.log.debug("unlocking importConfig...", .{});
            self.internal.lock.unlock(io);
        }
        if (self.internal.target_dc) |switch_to_dc| {
            if (self.transport_connector.isAvailable(io, switch_to_dc)) {
                try self.dispatcher.setMainDc(allocator, io, switch_to_dc);

                self.internal.current_dc = switch_to_dc;
                self.internal.target_dc = null;
            }
        }
    }
}

/// The lock is assumed to be acquired (write)
fn switchMainDc(self: *ClientManager, allocator: std.mem.Allocator, io: std.Io, dc: DcId) !void {
    if (self.transport_connector.isAvailable(io, dc)) {
        try self.dispatcher.setMainDc(allocator, io, dc);
        self.internal.current_dc = dc;
        self.internal.target_dc = null;
        return;
    }
    return Error.DcUnavailable;
}

pub fn probeLoggedIn(self: *ClientManager, allocator: std.mem.Allocator, io: std.Io) !bool {
    const dc = blk: {
        const is_set = is_set: {
            log.debug("locking (shared) probeLoggedIn...\n", .{});
            try self.internal.lock.lockShared(io);
            defer {
                log.debug("unlocking (shared) probeLoggedIn...\n", .{});
                self.internal.lock.unlockShared(io);
            }
            break :is_set self.internal.switch_dc_event.isSet();
        };

        if (!is_set) {
            try self.internal.switch_dc_event.wait(io);
        }
        break :blk self.internal.current_dc;
    };

    const des = try self.dispatcher.send(allocator, io, dc, .common, tl.TL{ .UsersGetUsers = &.{ .id = &.{.{ .InputUserSelf = &.{} }} } });
    defer des.deinit(allocator);
    if (des.data == .ProtoRpcError) {
        return false;
    }
    if (des.data == .Vector and des.data.Vector.len >= 1 and des.data.Vector[0] == .User) {
        std.log.debug("locking probeLoggedIn...", .{});
        try self.internal.lock.lock(io);
        defer {
            std.log.debug("unlocking probeLoggedIn...", .{});
            self.internal.lock.unlock(io);
        }

        const user = des.data.Vector[0].User;
        self.internal.my_id = user.id;
        self.internal.is_bot = user.bot;

        self.internal.authorization_check_event.set(io);

        return true;
    }
    return false;
}

fn authenticateInternal(self: *ClientManager, allocator: std.mem.Allocator, io: std.Io, token: []const u8, testmode: bool) !bapi.Result(void) {

    //_ = allocator;
    //_ = token;
    //return .{ .ok = void{} };
    const r, const dc_selected = blk: {
        log.debug("locking (shared) authenticateInternal...\n", .{});
        try self.session_info.lock.lockShared(io);
        defer {
            log.debug("unlocking (shared) authenticateInternal...\n", .{});
            self.session_info.lock.unlockShared(io);
        }

        const r = try self.dispatcher.send(allocator, io, self.internal.current_dc, .common, tl.TL{ .AuthImportBotAuthorization = &.{ .flags = 0, .api_id = self.session_info.api_id, .api_hash = self.session_info.api_hash, .bot_auth_token = token } });
        break :blk .{ r, self.internal.current_dc };
    };
    defer r.deinit(allocator);

    if (r.data == .ProtoRpcError) {
        const err = r.data.ProtoRpcError;
        if (detectMigrateError(err.error_message)) |dc| {
            {
                log.debug("locking authenticateInternal...", .{});
                try self.internal.lock.lock(io);
                defer {
                    std.log.debug("unlocking authenticateInternal...", .{});
                    self.internal.lock.unlock(io);
                }
                try self.switchMainDc(allocator, io, DcId{ .id = dc, .testmode = testmode });
            }
            return self.authenticateInternal(allocator, io, token, testmode);
        }
        return .{ .err = .{ .code = err.error_code, .message = allocator.dupe(u8, err.error_message) catch "UNKNOWN_ERROR", .owned = true } };
    }

    if (r.data == .AuthAuthorization) {
        const authorization = r.data.AuthAuthorization;
        if (authorization.user == .UserEmpty) {
            @branchHint(.unlikely);
            if (!try probeLoggedIn(self, allocator, io)) {
                return .{ .err = .{ .code = 500, .message = "LOGIN_FAILED" } };
            }
        }
        if (authorization.user == .User) {
            const user = authorization.user.User;
            log.debug("locking authenticateInternal...", .{});
            try self.internal.lock.lock(io);
            defer {
                log.debug("unlocking authenticateInternal...", .{});
                self.internal.lock.unlock(io);
            }
            self.internal.my_id = user.id;
            self.internal.is_bot = user.bot;
        }
        try self.storage.setPreferredDC(io, dc_selected);
        self.pushClientStatusInternal(allocator, io, .ready);
    }

    return .{ .ok = {} };
}

pub fn authenticateBot(self: *ClientManager, allocator: std.mem.Allocator, io: std.Io, token: []const u8) !bapi.Result(void) {
    const testmode = blk: {
        log.debug("locking authenticateBot...", .{});
        try self.internal.lock.lock(io);
        defer {
            log.debug("unlocking authenticateBot...", .{});
            self.internal.lock.unlock(io);
        }

        if (self.internal.client_status != .waiting_authorization or self.internal.my_id != null) {
            return .{ .err = .{ .code = 400, .message = "NOT_READY" } };
        }

        self.pushClientStatusInternal(allocator, io, .logging_in);
        break :blk self.internal.current_dc.testmode;
    };

    defer {
        log.debug("locking authenticateBot defer...", .{});
        self.internal.lock.lockUncancelable(io);
        defer {
            log.debug("unlocking authenticateBot defer...", .{});
            self.internal.lock.unlock(io);
        }

        if (self.internal.client_status == .logging_in) {
            self.pushClientStatusInternal(allocator, io, .waiting_authorization);
        }
    }

    return self.authenticateInternal(allocator, io, token, testmode);
}

pub fn deinit(self: *ClientManager, allocator: std.mem.Allocator, io: std.Io, comptime graceful: bool) void {
    log.debug("deinit session info", .{});

    self.session_info.deinit(allocator, io);
    {
        log.debug("internal lock", .{});

        self.internal.lock.lockUncancelable(io);
        log.debug("dispatcher deinit", .{});

        self.dispatcher.deinit(allocator, io, graceful);
        log.debug("transport deinit", .{});

        self.transport_connector.deinit(allocator, io);
        log.debug("updates manager deinit", .{});

        self.updates_manager.deinit(allocator, io);
        log.debug("storage deinit", .{});

        self.storage.deinit(allocator, io);
    }
}
