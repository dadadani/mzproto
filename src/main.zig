const std = @import("std");
const generate = @import("generator/generate.zig");
pub fn main() !void {
    try generate.main();
}

test "simple test" {

    //var mem: [4096]u8 = undefined;
    //var stackAllocator = std.heap.FixedBufferAllocator.init(&mem);
    //const allocator = stackAllocator.allocator();
    const a = @import("generator/generate.zig");
    a.tesaat();
}
