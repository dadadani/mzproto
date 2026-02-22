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
