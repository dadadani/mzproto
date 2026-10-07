const tl = @import("tl");
const base = @import("tl_base");
const std = @import("std");

pub fn Owned(comptime Codec: type) type {
    return struct {
        ptr: []align(Codec.out_alignment) u8,
        data: base.Ref(Codec, .boxed).Read,

        pub fn decode(allocator: std.mem.Allocator, input: []const u8) !@This() {
            const layout = try Codec.measure(input);
            const ptr = try allocator.alignedAlloc(u8, .fromByteUnits(Codec.out_alignment), layout.object_bytes);
            errdefer allocator.free(ptr);
            return .{ .ptr = ptr, .data = try Codec.decodeExact(input, ptr) };
        }

        pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
            allocator.free(self.ptr);
        }
    };
}

/// The result is retained with the pending request; the response owns the buffer.
pub const Response = struct {
    ptr: []u8,
    alignment: std.mem.Alignment,
    data: union(enum) {
        result: base.DecodedResult,
        rpc_error: *const tl.rpc_error.Decoded,
        msgs_state_info: *const tl.msgs_state_info.Decoded,
    },

    pub fn decode(allocator: std.mem.Allocator, ops: base.ResultOps, body: []const u8) !Response {
        if (tl.identify(body) == .rpc_error) {
            const owned = try Owned(tl.rpc_error).decode(allocator, body);
            return .{ .ptr = owned.ptr, .alignment = .fromByteUnits(tl.rpc_error.out_alignment), .data = .{ .rpc_error = owned.data } };
        }
        const layout = try ops.measure(body);
        const alignment: std.mem.Alignment = .fromByteUnits(ops.out_alignment);
        const allocation = allocator.rawAlloc(layout.object_bytes, alignment, @returnAddress()) orelse return error.OutOfMemory;
        const ptr = allocation[0..layout.object_bytes];
        errdefer allocator.rawFree(ptr, alignment, @returnAddress());
        return .{ .ptr = ptr, .alignment = alignment, .data = .{ .result = try ops.decodeExact(body, ptr) } };
    }

    pub fn from(self: Response, comptime Function: type) !Function.Result.Read {
        return switch (self.data) {
            .result => |result| result.from(Function),
            else => error.UnexpectedResponse,
        };
    }

    pub fn deinit(self: Response, allocator: std.mem.Allocator) void {
        allocator.rawFree(self.ptr, self.alignment, @returnAddress());
    }
};

pub fn Ring(comptime T: type, comptime N: usize) type {
    return struct {
        const Self = @This();

        buf: [N]T = undefined,
        head: usize = 0, // index of oldest element
        len: usize = 0,

        pub fn push(self: *Self, value: T) void {
            if (self.len < N) {
                const tail = (self.head + self.len) % N;
                self.buf[tail] = value;
                self.len += 1;
            } else {
                // full: overwrite oldest
                self.buf[self.head] = value;
                self.head = (self.head + 1) % N;
            }
        }

        pub fn pop(self: *Self) ?T {
            if (self.len == 0) return null;
            const v = self.buf[self.head];
            self.head = (self.head + 1) % N;
            self.len -= 1;
            return v;
        }

        pub fn at(self: *const Self, i: usize) ?T {
            if (i >= self.len) return null;
            return self.buf[(self.head + i) % N];
        }

        pub inline fn contains(self: *const Self, value: T) bool {
            return std.mem.containsAtLeast(T, &self.buf, 1, &[_]T{value});
        }
    };
}

test "owned RPC results preserve vector types and do not borrow wire memory" {
    const allocator = std.testing.allocator;
    var wire: [128]u8 = undefined;
    const items = [_]tl.User{.{ .userEmpty = &.{ .id = 42 } }};
    const encoded = try tl.@"users.getUsers".TLResult.serialize(&items, &wire);
    const response = try Response.decode(allocator, base.ResultOps.forType(tl.@"users.getUsers"), encoded);
    defer response.deinit(allocator);
    @memset(&wire, 0);
    const users = try response.from(tl.@"users.getUsers");
    try std.testing.expectEqual(42, users[0].userEmpty.id);
    try std.testing.expectEqual(0, @intFromPtr(response.ptr.ptr) % response.alignment.toByteUnits());
    try std.testing.expectError(error.UnexpectedResultType, response.from(tl.ping));
}

test "RPC errors stay separate and invalid results release their workspace" {
    const allocator = std.testing.allocator;
    const ops = base.ResultOps.forType(tl.ping);
    var wire: [128]u8 = undefined;
    const encoded = try tl.rpc_error.serialize(&.{ .error_code = 400, .error_message = "BAD_REQUEST" }, &wire);
    const response = try Response.decode(allocator, ops, encoded);
    defer response.deinit(allocator);
    @memset(&wire, 0);
    try std.testing.expectEqualStrings("BAD_REQUEST", response.data.rpc_error.error_message);
    try std.testing.expectError(error.UnexpectedResponse, response.from(tl.ping));
    const pong = try tl.pong.serialize(&.{ .ping_id = 1, .msg_id = 2 }, &wire);
    try std.testing.expectError(error.InvalidData, Response.decode(allocator, ops, wire[0 .. pong.len + 4]));
    try std.testing.expectError(error.EndOfInput, Response.decode(allocator, ops, pong[0 .. pong.len - 1]));
    const wrong = try tl.future_salt.serialize(&.{ .valid_since = 1, .valid_until = 2, .salt = 3 }, &wire);
    try std.testing.expectError(error.InvalidConstructor, Response.decode(allocator, ops, wrong));
}
