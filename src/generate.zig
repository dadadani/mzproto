const std = @import("std");
const generate = @import("generator/tlgen/main.zig");
pub fn main(init: std.process.Init) !void {
    try generate.main(init);
}
