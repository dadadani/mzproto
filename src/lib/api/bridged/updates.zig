const std = @import("std");
const bapi = @import("mzproto_bridge");
const Client = @import("../../client.zig");
const UpdatesManager = @import("../../updates_manager.zig");

pub fn nextUpdate(client_ptr: *anyopaque, blocking: bool) !bapi.Result(?bapi.Update) {
    const self: *Client = @ptrCast(@alignCast(client_ptr));

    var buf: [1]bapi.Update = undefined;

    const read = self.client_manager.updates_manager.updates_queue.get(self.io, &buf, if (blocking) 1 else 0) catch |err| {
        if (err == std.Io.QueueClosedError.Closed) {
            return .{ .ok = null };
        }
        return .{ .err = .{ .code = 600, .message = "QUEUE_ERROR" } };
    };

    if (read == 0) {
        return .{ .ok = null };
    }

    return .{ .ok = buf[0] };
}
