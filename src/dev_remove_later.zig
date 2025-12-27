const std = @import("std");
const mzproto = @import("mzproto");
pub fn main() !void {
    try mzproto.generate_dev();
}
