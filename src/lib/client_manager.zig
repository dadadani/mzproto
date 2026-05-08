const std = @import("std");

const ClientManager = @This();
const Dispatcher = @import("./proto/dispatcher.zig");
const TransportConnector = @import("../lib/transport_connector.zig");
const DcId = @import("./utils.zig").DcId;
const Storage = @import("./storage.zig").Storage;
const tl = @import("tl/api.zig");

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
    mutex: std.Io.Mutex = .init,

    /// The datacenter where all the requests should default to
    current_dc: DcId,

    /// The client should switch to this datacenter as the default as soon as possible
    target_dc: ?DcId = null,
},

dispatcher: Dispatcher,
transport_connector: TransportConnector,
storage: Storage,

pub fn importConfig(self: *ClientManager, allocator: std.mem.Allocator, io: std.Io, config: *const tl.Config) !void {
    try self.transport_connector.importConfig(allocator, io, config);
    {
        try self.internal.mutex.lock(io);
        defer self.internal.mutex.unlock(io);
        if (self.internal.target_dc) |switch_to_dc| {
            if (self.transport_connector.isAvailable(io, switch_to_dc)) {
                try self.dispatcher.setMainDc(allocator, io, switch_to_dc);

                self.internal.current_dc = switch_to_dc;
                self.internal.target_dc = null;
            }
        }
    }
}

pub fn currentDc(self: *ClientManager, io: std.Io) !DcId {
    try self.internal.mutex.lock(io);
    defer self.internal.mutex.unlock(io);
    return self.internal.current_dc;
}

pub fn probeLoggedIn(self: *ClientManager, allocator: std.mem.Allocator, io: std.Io) !bool {
    const dc = try self.currentDc(io);
    const user = try self.dispatcher.send(allocator, io, dc, .common, tl.TL{ .UsersGetFullUser = &.{ .id = .{ .InputUserSelf = &.{} } } });
    defer user.deinit(allocator);
    if (user.data == .ProtoRpcError) {
        return false;
    }
    if (user.data == .UserFull) {
        return true;
    }
    return false;
}

pub fn deinit(self: *ClientManager, allocator: std.mem.Allocator, io: std.Io) void {
    self.session_info.deinit(allocator, io);
    {
        self.internal.mutex.lockUncancelable(io);
        self.dispatcher.deinit(allocator, io, true);
        self.transport_connector.deinit(allocator, io);
        self.storage.deinit(allocator, io);
    }
}
