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
