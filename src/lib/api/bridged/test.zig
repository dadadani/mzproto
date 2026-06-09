const std = @import("std");
const bapi = @import("mzproto_bridge");
const Client = @import("../../client.zig");

pub fn init(allocator: std.mem.Allocator, io: std.Io, config: bapi.ConstRefConfig) bapi.BridgeError!bapi.Result(*anyopaque) {
    const client = Client.init(allocator, io, config) catch |err| {
        if (err == error.PythonError) return error.PythonError;
        if (err == error.OutOfMemory) return error.OutOfMemory;
        return .{ .err = .{ .code = 500, .message = @errorName(err) } };
    };
    return .{ .ok = @ptrCast(client) };
}

pub fn deinit(ptr: *anyopaque) bapi.BridgeError!bapi.Result(void) {
    const self: *Client = @ptrCast(@alignCast(ptr));
    std.log.debug("return deinit actual funct", .{});

    self.deinit();
    return .{ .ok = {} };
}

pub fn isTerminated(ptr: *anyopaque) bool {
    const self: *Client = @ptrCast(@alignCast(ptr));
    return self.terminated.load(.acquire);
}

pub fn sendMessage(ptr: *anyopaque, text: bapi.ConstString) bapi.BridgeError!bapi.Result(bapi.Message) {
    const self: *Client = @ptrCast(@alignCast(ptr));

    const utf8 = try text.getUTF8(self.allocator);
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

pub fn testReturnEnum(ptr: *anyopaque, listmes: bapi.ConstList(bapi.Message)) bapi.BridgeError!bapi.Result(bapi.StorageBackend) {
    const self: *Client = @ptrCast(@alignCast(ptr));

    if ((try listmes.size()) > 0) {
        var get1 = try listmes.get(0);
        defer get1.deinit(self.allocator);

        std.debug.print("{d}", .{try get1.toConst().getId()});
    }

    //const self: *Client = @ptrCast(@alignCast(ptr));
    return .{ .ok = .memory_dc_bin_storage };
}

pub fn terminate(ptr: *anyopaque) bapi.BridgeError!bapi.Result(void) {
    const self: *Client = @ptrCast(@alignCast(ptr));
    std.log.debug("called terminate", .{});
    self.terminate(false);
    std.log.debug("return terminate", .{});

    return .{ .ok = {} };
}
