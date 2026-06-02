const std = @import("std");
const bapi = @import("mzproto_bridge");
const Client = @import("../../client.zig");

pub fn init(allocator: std.mem.Allocator, io: std.Io, config: bapi.ConstRefConfig) bapi.Result(*anyopaque) {
    const client = Client.init(allocator, io, config) catch |err| {
        return .{ .err = .{ .code = 500, .message = @errorName(err) } };
    };
    return .{ .ok = @ptrCast(client) };
}

pub fn deinit(ptr: *anyopaque) bapi.Result(void) {
    const self: *Client = @ptrCast(@alignCast(ptr));
    self.deinit();
    return .{ .ok = {} };
}

pub fn sendMessage(ptr: *anyopaque, text: bapi.ConstString) bapi.Result(bapi.Message) {
    const self: *Client = @ptrCast(@alignCast(ptr));

    const utf8 = text.getUTF8(self.allocator) catch {
        return .{ .err = .{ .code = 500, .message = "failed to load string" } };
    };
    defer if (!bapi.STRINGS_ARE_NO_COPY) self.allocator.free(@constCast(utf8));

    std.debug.print("testing.... field: {d} {s}\n", .{ self.client_manager.session_info.api_id, utf8 });
    var message = bapi.Message.init(self.allocator) catch {
        return .{ .err = .{ .code = 500, .message = "failed to create message" } };
    };
    var ref = message.toRef();
    ref.setId(self.allocator, @intCast(utf8.len)) catch {
        message.deinit(self.allocator);
        return .{ .err = .{ .code = 500, .message = "failed to set message id" } };
    };
    return .{ .ok = message };
}

pub fn testReturnEnum(ptr: *anyopaque) bapi.Result(bapi.StorageBackend) {
    _ = ptr;
    //const self: *Client = @ptrCast(@alignCast(ptr));
    return .{ .ok = .memory_dc_bin_storage };
}

pub fn terminate(ptr: *anyopaque) bapi.Result(void) {
    return deinit(ptr);
}
