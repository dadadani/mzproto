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

const sections = @import("./sections.zig");
const parameters = @import("./parameters.zig");
const parameters_type = @import("./parameters_type.zig");
const types = @import("./types.zig");
const utils = @import("./utils.zig");

const std = @import("std");

pub const ParseConstructorError = error{ EmptyConstructor, MissingType };

pub const TLConstructor = struct {
    namespaces: std.ArrayList([]const u8),
    name: []const u8,
    id: u32,
    params: std.ArrayList(parameters.TLParameter),
    type: *const types.TLType,
    category: sections.TLSection,
    allocator: std.mem.Allocator,

    pub fn parse(allocator: std.mem.Allocator, constructor: []const u8, section: sections.TLSection) !@This() {
        if (utils.trimWhitespace(constructor).len == 0) {
            return ParseConstructorError.EmptyConstructor;
        }

        const left, const right = try split: {
            var s = std.mem.splitSequence(u8, constructor, "=");
            const left = utils.trimWhitespace(s.next() orelse unreachable);
            if (s.next()) |right| {
                break :split .{ left, utils.trimWhitespace(right) };
            }

            break :split ParseConstructorError.MissingType;
        };

        const ty = try types.TLType.parse(allocator, right);
        errdefer ty.deinit();

        const name_id, const middle = middle: {
            if (std.mem.indexOf(u8, left, " ")) |pos| {
                break :middle .{ left[0..pos], utils.trimWhitespace(left[pos..]) };
            }

            break :middle .{ left, null };
        };

        const name, const id_str = id: {
            var split = std.mem.splitSequence(u8, name_id, "#");
            const name = split.next() orelse unreachable;
            break :id .{ name, split.next() };
        };

        var namespace = std.ArrayList([]const u8).init(allocator);
        errdefer {
            for (namespace.items) |item| {
                allocator.free(item);
            }
            namespace.deinit();
        }

        var ns_split = std.mem.splitSequence(u8, name, ".");
        while (ns_split.next()) |ns| {
            try namespace.append(try allocator.dupe(u8, ns));
        }

        const id = id: {
            if (id_str) |sid| {
                break :id try std.fmt.parseUnsigned(u32, sid, 16);
            }
            break :id try @import("./utils.zig").generateIdFromConstructor(allocator, name);
        };

        var params = std.ArrayList(parameters.TLParameter).init(allocator);
        errdefer {
            for (params.items) |param| {
                param.deinit();
            }
            params.deinit();
        }

        var type_defs = std.ArrayList([]u8).init(allocator);
        defer {
            for (type_defs.items) |item| {
                allocator.free(item);
            }
            type_defs.deinit();
        }

        var flag_defs = std.ArrayList([]const u8).init(allocator);
        defer {
            for (flag_defs.items) |item| {
                allocator.free(item);
            }
            flag_defs.deinit();
        }
        if (middle) |smiddle| {
            var split = std.mem.splitSequence(u8, smiddle, " ");
            while (split.next()) |param| {
                if (param.len == 0) {
                    continue;
                }
                const parameter = try parameters.TLParameter.parse(allocator, param);
                errdefer parameter.deinit();

                if (parameter.type_def) {
                    try type_defs.append(try allocator.dupe(u8, parameter.name));
                    parameter.deinit();
                    continue;
                }

                if (parameter.type) |t| {
                    switch (t) {
                        .Flags => {
                            try flag_defs.append(try allocator.dupe(u8, parameter.name));
                        },
                        .Normal => {
                            if (t.Normal.type.generic_ref) {
                                var found = false;
                                for (type_defs.items) |item| {
                                    if (std.mem.eql(u8, item, t.Normal.type.name)) {
                                        found = true;
                                        break;
                                    }
                                }
                                if (!found) {
                                    return parameters.ParseParameterError.MissingDefintion;
                                }
                            }

                            if (t.Normal.flag) |flag| {
                                var found = false;
                                for (flag_defs.items) |item| {
                                    if (std.mem.eql(u8, item, flag.name)) {
                                        found = true;
                                        break;
                                    }
                                }
                                if (!found) {
                                    return parameters.ParseParameterError.MissingDefintion;
                                }
                            }
                        },
                    }
                } else {
                    unreachable;
                }

                {
                    var found = false;
                    for (type_defs.items) |item| {
                        if (std.mem.eql(u8, item, parameter.name)) {
                            found = true;
                            break;
                        }
                    }
                    if (found) {
                        @constCast(ty).generic_ref = true;
                    }
                }

                try params.append(parameter);
            }
        }

        const constructor_name = namespace.pop().?;
        return .{
            .allocator = allocator,
            .namespaces = namespace,
            .name = constructor_name,
            .id = id,
            .params = params,
            .type = ty,
            .category = section,
        };
    }

    pub fn deinit(self: *const TLConstructor) void {
        for (self.namespaces.items) |item| {
            self.allocator.free(item);
        }
        self.namespaces.deinit();

        for (self.params.items) |param| {
            param.deinit();
        }
        self.params.deinit();

        self.type.deinit();
        self.allocator.free(self.name);
    }
};

test "parse constructors" {
    const allocator = std.testing.allocator;

    {
        const constructor = try TLConstructor.parse(allocator, "test.test2.flagstest flags2:# test:flags2.0?asd = aaaa", sections.TLSection.Types);
        defer constructor.deinit();

        try std.testing.expectEqualStrings(constructor.name, "flagstest");
        try std.testing.expectEqualStrings("test", constructor.namespaces.items[0]);
        try std.testing.expectEqualStrings("test2", constructor.namespaces.items[1]);

        try std.testing.expectEqualStrings("flags2", constructor.params.items[0].name);
        try std.testing.expect(!constructor.params.items[0].type_def);
        try std.testing.expect(constructor.params.items[0].type.? == parameters_type.TLParameterTypeTag.Flags);

        try std.testing.expectEqualStrings("test", constructor.params.items[1].name);
        try std.testing.expect(!constructor.params.items[1].type_def);
        try std.testing.expect(constructor.params.items[1].type.? == parameters_type.TLParameterTypeTag.Normal);
        try std.testing.expect(constructor.params.items[1].type.?.Normal.flag != null);
        try std.testing.expectEqualStrings("flags2", constructor.params.items[1].type.?.Normal.flag.?.name);
        try std.testing.expectEqual(0, constructor.params.items[1].type.?.Normal.flag.?.index);
    }
}
