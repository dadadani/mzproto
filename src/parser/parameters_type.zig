const types = @import("./types.zig");
const flags = @import("./flags.zig");
const std = @import("std");

pub const ParseParameterError = error{Empty};

pub const TLParameterTypeTag = enum { Flags, Normal };

pub const TLParameterType = union(TLParameterTypeTag) {
    Flags: struct {},

    Normal: struct {
        type: *const types.TLType,
        flag: ?flags.TLFlag,
    },

    pub fn parse(allocator: std.mem.Allocator, in: []const u8) !TLParameterType {
        if (in.len == 0) {
            return ParseParameterError.Empty;
        }

        if (std.mem.eql(u8, in, "#")) {
            return .{ .Flags = .{} };
        }

        const ty, const flag = pm: {
            if (std.mem.indexOf(u8, in, "?")) |pos| {
                break :pm .{ try types.TLType.parse(allocator, in[pos + 1 ..]), try flags.TLFlag.parse(allocator, in[0..pos]) };
            } else {
                break :pm .{ try types.TLType.parse(allocator, in), null };
            }
        };

        return .{ .Normal = .{ .type = ty, .flag = flag } };
    }

    pub fn deinit(self: *const TLParameterType) void {
        switch (self.*) {
            .Flags => {},
            .Normal => {
                self.Normal.type.deinit();
                if (self.Normal.flag) |f| {
                    f.deinit();
                }
            },
        }
    }
};
