const std = @import("std");

pub const ParseFlagError = error{InvalidFlag};

pub const TLFlag = struct {
    name: []const u8,
    index: usize,
    allocator: std.mem.Allocator,

    pub fn parse(allocator: std.mem.Allocator, in: []const u8) !TLFlag {
        if (std.mem.indexOf(u8, in, ".")) |index| {
            const name = try allocator.dupe(u8, in[0..index]);
            errdefer allocator.free(name);
            return .{ .allocator = allocator, .name = name, .index = try std.fmt.parseUnsigned(usize, in[index + 1 ..], 10) };
        } else {
            return ParseFlagError.InvalidFlag;
        }
    }

    pub fn deinit(self: *const TLFlag) void {
        self.allocator.free(self.name);
    }
};
