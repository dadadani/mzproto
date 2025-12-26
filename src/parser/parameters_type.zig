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

const types = @import("./types.zig");
const flags = @import("./flags.zig");
const std = @import("std");

pub const ParseParameterError = error{Empty};

pub const TLParameterType = union(enum) {
    Flags: struct {},

    Normal: struct {
        type: *types.TLType,
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
