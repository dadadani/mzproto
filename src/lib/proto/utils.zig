const tl = @import("../tl/api.zig");
const std = @import("std");

pub const Deserialized = struct {
    ptr: []u8,
    data: tl.TL,
};

pub const DeserializedMessage = struct {
    ptr: []align(@alignOf(tl.ProtoMessage)) u8,
    data: *tl.ProtoMessage,
};
