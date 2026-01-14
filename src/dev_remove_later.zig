const std = @import("std");
const mzproto = @import("mzproto");
pub fn main(init: std.process.Init) !void {
    try mzproto.generate_dev(init);
}
