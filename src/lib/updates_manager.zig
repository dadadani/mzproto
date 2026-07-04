const std = @import("std");
const ClientManager = @import("./client_manager.zig");
const UpdatesManager = @import("./updates_manager.zig");
const tl = @import("tl");
const DcId = @import("./utils.zig").DcId;

const log = std.log.scoped(.mzproto_updates);

pub const INGRESS_CAPACITY = 64;

const OwnedUpdate = struct {
    msg_id: u64,
    seqno: i32,
    value: tl.IUpdate,
    backing: []u8,
    dc_id: DcId,

    fn deinit(self: OwnedUpdate, allocator: std.mem.Allocator) void {
        allocator.free(self.backing);
    }
};

client_manager: *ClientManager,
ingress_buffer: [INGRESS_CAPACITY]OwnedUpdate,
ingress: std.Io.Queue(OwnedUpdate),

pub fn init(self: *UpdatesManager, client_manager: *ClientManager) void {
    self.client_manager = client_manager;
    self.ingress = .init(&self.ingress_buffer);
}

/// Returns whether this update is allowed to be processed while not being logged in
inline fn isAllowedUpdatePreAuth(message: std.meta.Tag(tl.IUpdate)) bool {
    return switch (message) {
        // https://core.telegram.org/api/updates#subscribing-to-updates
        .UpdateLoginToken,
        .UpdateSentPhoneCode,
        .UpdateDcOptions,
        .UpdateConfig,
        .UpdateLangPackTooLong,
        .UpdateLangPack,
        => true,
        else => false,
    };
}

pub fn pushTLMessage(self: *UpdatesManager, allocator: std.mem.Allocator, io: std.Io, dc: DcId, message: tl.ProtoMessage) !void {
    if (message.body.len < @sizeOf(u32)) return error.InvalidUpdate;

    var size: usize = 0;
    _ = tl.IUpdate.deserializeSize(message.body, &size);
    const backing = try allocator.alloc(u8, size);
    errdefer allocator.free(backing);
    const parsed, _, _ = tl.IUpdate.deserialize(message.body, backing);

    {
        try self.client_manager.internal.lock.lockShared(io);
        defer self.client_manager.internal.lock.unlockShared(io);
        if (self.client_manager.internal.my_id == null) {
            if (!isAllowedUpdatePreAuth(parsed)) {
                log.warn("Received {s} while not being logged in", .{@tagName(parsed)});
                return;
            }
        }
    }

    var owned: OwnedUpdate = .{
        .msg_id = message.msg_id,
        .seqno = message.seqno,
        .value = parsed,
        .dc_id = dc,
        .backing = backing,
    };
    errdefer owned.deinit(allocator);
    try self.ingress.putOne(io, owned);
}


pub fn worker(self: *UpdatesManager, allocator: std.mem.Allocator, io: std.Io) std.Io.Cancelable!void {
    while (true) {
        var messages: [1]OwnedUpdate = undefined;
        const count = self.ingress.get(io, &messages, 1) catch |err| switch (err) {
            error.Closed => return,
            error.Canceled => return error.Canceled,
        };
        if (count == 0) continue;
        defer messages[0].deinit(allocator);

        const mex = messages[0];

        switch (mex.value) {
            .UpdateDcOptions => |u_dc| {
                self.client_manager.transport_connector.importDcOptions(allocator, io, u_dc.dc_options, mex.dc_id.testmode) catch |err| {
                    log.warn("Failed to import dc_options from UpdateDcOptions: {s}", .{@errorName(err)});
                };
            },
            .UpdateConfig => {
                try self.client_manager.requestGetConfig(allocator, io);
            },

            else => |tlo| {
                log.warn("Unhandled {s} received", .{@tagName(tlo)});
            },
        }
    }
}

pub fn deinit(self: *UpdatesManager, allocator: std.mem.Allocator, io: std.Io) void {
    self.ingress.close(io);
    var messages: [INGRESS_CAPACITY]OwnedUpdate = undefined;
    const count = self.ingress.getUncancelable(io, &messages, 0) catch return;
    for (messages[0..count]) |message| message.deinit(allocator);
}

test {
    _ = @import("update_ordering.zig");
}
