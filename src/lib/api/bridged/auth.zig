const std = @import("std");
const bapi = @import("mzproto_bridge");
const Client = @import("../../client.zig");
const UpdatesManager = @import("../../updates_manager.zig");

pub fn authenticateBot(client_ptr: *anyopaque, input_token: bapi.ConstString) !bapi.Result(void) {
    const self: *Client = @ptrCast(@alignCast(client_ptr));

    const token = try input_token.getUTF8(self.allocator);
    defer {
        if (bapi.PREFERRED_STRING_ENCODING != .utf8 or !bapi.STRINGS_ARE_NO_COPY) {
            self.allocator.free(token);
        }
    }

    return self.client_manager.authenticateBot(self.allocator, self.io, token) catch |err| {
        return .{ .err = .{ .code = 600, .message = @errorName(err) } };
    };
}
