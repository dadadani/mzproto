//   Copyright (c) 2025 Daniele Cortesi <https://github.com/dadadani>
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

const std = @import("std");
const sections = @import("./sections.zig");

pub const ParseTypeError = error{MissingGenericArg};

pub const TLType = struct {
    allocator: std.mem.Allocator,
    namespaces: std.ArrayList([]const u8),
    name: []const u8,
    bare: bool,
    generic_ref: bool,
    generic_arg: ?*const @This(),

    pub fn parse(allocator: std.mem.Allocator, in: []const u8) !*const TLType {
        const genericRef = trim: {
            if (std.mem.startsWith(u8, in, "!")) {
                break :trim .{ std.mem.trimLeft(u8, in, "!"), true };
            }
            break :trim .{ in, false };
        };

        const genericArg = try split: {
            if (std.mem.indexOf(u8, genericRef[0], "<")) |pos| {
                if (!std.mem.endsWith(u8, genericRef[0], ">")) {
                    break :split ParseTypeError.MissingGenericArg;
                }
                break :split .{
                    genericRef[0][0..pos],
                    try TLType.parse(allocator, genericRef[0][pos + 1 .. genericRef[0].len - 1]),
                };
            } else {
                break :split .{
                    genericRef[0],
                    null,
                };
            }
        };
        errdefer {
            if (genericArg[1]) |generic_arg| {
                generic_arg.deinit();
            }
        }

        var namespaces = std.ArrayList([]const u8).init(allocator);
        errdefer {
            for (namespaces.items) |item| {
                allocator.free(item);
            }
            namespaces.deinit();
        }
        var split_ns = std.mem.splitSequence(u8, genericArg[0], ".");

        while (split_ns.next()) |ns| {
            try namespaces.append(try allocator.dupe(u8, ns));
        }

        const name = namespaces.pop().?;

        const bare = blk: {
            if (std.ascii.isLower(name[0])) {
                break :blk true;
            } else {
                break :blk false;
            }
        };

        const res = try allocator.create(TLType);
        errdefer allocator.free(res);
        res.* = .{
            .allocator = allocator,
            .namespaces = namespaces,
            .name = name,
            .bare = bare,
            .generic_ref = genericRef[1],
            .generic_arg = genericArg[1],
        };
        return res;
    }

    pub fn deinit(self: *const TLType) void {
        defer self.allocator.destroy(self);

        for (self.namespaces.items) |item| {
            self.allocator.free(item);
        }
        self.namespaces.deinit();

        self.allocator.free(self.name);

        if (self.generic_arg) |generic_arg| {
            generic_arg.deinit();
        }
    }
};
