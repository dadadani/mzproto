const types = @import("./types.zig");
const parameter_types = @import("./parameters_type.zig");
const std = @import("std");

pub const ParseParameterError = error{ MissingDefintion, NotImplemented, Empty };

pub const TLParameter = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    type_def: bool,
    type: ?parameter_types.TLParameterType,

    pub fn parse(allocator: std.mem.Allocator, in: []const u8) !TLParameter {
        if (std.mem.startsWith(u8, in, "{")) {
            if (std.mem.endsWith(u8, in, ":Type}")) {
                const dupe_name = try allocator.dupe(u8, in[1..(std.mem.indexOf(u8, in, ":") orelse unreachable)]);
                errdefer allocator.free(dupe_name);

                return .{ .name = dupe_name, .type_def = true, .type = null, .allocator = allocator };
            } else {
                return ParseParameterError.MissingDefintion;
            }
        }

        const name, const ty = try ty: {
            var split = std.mem.splitSequence(u8, in, ":");
            if (split.next()) |name| {
                if (split.next()) |ty| {
                    break :ty .{ name, ty };
                }
                break :ty ParseParameterError.NotImplemented;
            }
            break :ty ParseParameterError.Empty;
        };

        if (in.len == 0) {
            return ParseParameterError.Empty;
        }

        const dupe_name = try allocator.dupe(u8, name);
        errdefer allocator.free(dupe_name);

        const typ = try parameter_types.TLParameterType.parse(allocator, ty);
        errdefer typ.deinit();

        return .{ .name = dupe_name, .type_def = false, .type = typ, .allocator = allocator };
    }

    pub fn deinit(self: *const TLParameter) void {
        self.allocator.free(self.name);
        if (self.type) |t| {
            t.deinit();
        }
    }
};
