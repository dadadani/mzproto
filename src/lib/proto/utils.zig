const tl = @import("../tl/api.zig");
const std = @import("std");

pub const Deserialized = struct {
    ptr: []u8,
    alignment: std.mem.Alignment = .of(u8),
    data: tl.TL,

    pub inline fn deinit(self: Deserialized, allocator: std.mem.Allocator) void {
        allocator.vtable.free(allocator.ptr, self.ptr, self.alignment, @returnAddress());
    }
};

pub const DeserializedMessage = struct {
    ptr: []align(@alignOf(tl.ProtoMessage)) u8,
    data: *tl.ProtoMessage,
};
