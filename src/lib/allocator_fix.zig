const std = @import("std");

const FixAllocator = @This();

original: *anyopaque,
original_vtable: *const std.mem.Allocator.VTable,

pub fn alloc(self_ptr: *anyopaque, len: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
    const self: *FixAllocator = @ptrCast(@alignCast(self_ptr));
    return self.original_vtable.alloc(self.original, len, alignment, ret_addr);
}

pub fn resize(self_ptr: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
    const self: *FixAllocator = @ptrCast(@alignCast(self_ptr));
    return self.original_vtable.resize(self.original, memory, alignment, new_len, ret_addr);
}

pub fn remap(self_ptr: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    const self: *FixAllocator = @ptrCast(@alignCast(self_ptr));
    return self.original_vtable.remap(self.original, memory, alignment, new_len, ret_addr);
}

pub fn free(self_ptr: *anyopaque, memory: []u8, alignment: std.mem.Alignment, ret_addr: usize) void {
    const self: *FixAllocator = @ptrCast(@alignCast(self_ptr));
    // There's a bug on TestingAllocator, it uses functions from std.debug that do not propagate cancellation points clearly.
    //  We do this workaround until https://codeberg.org/ziglang/zig/pulls/36010 is merged (or a similar patch)
    const io = std.Options.debug_io;
    const prev = io.swapCancelProtection(.blocked);
    defer _ = io.swapCancelProtection(prev);
    return self.original_vtable.free(self.original, memory, alignment, ret_addr);
}

pub fn allocator(self: *FixAllocator) std.mem.Allocator {
    return .{
        .ptr = @ptrCast(self),
        .vtable = &.{
            .alloc = alloc,
            .resize = resize,
            .remap = remap,
            .free = free,
        },
    };
}

pub fn init(aallocator: std.mem.Allocator) FixAllocator {
    return .{
        .original = aallocator.ptr,
        .original_vtable = aallocator.vtable,
    };
}
