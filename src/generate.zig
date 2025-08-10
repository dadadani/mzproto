const std = @import("std");
const generate = @import("generator/main.zig");
pub fn main() !void {
    try generate.main();
}
