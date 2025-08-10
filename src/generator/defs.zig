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
const constructors = @import("../parser/constructors.zig");
const utils = @import("./utils.zig");
const deserialize = @import("./deserialize.zig");
const serialize = @import("./serialize.zig");
const clone = @import("./clone.zig");

pub fn generateDef(allocator: std.mem.Allocator, constructor: constructors.TLConstructor, file: *std.io.Writer, mtproto: bool) !void {
    const name = try utils.normalizeName(allocator, constructor, mtproto);
    defer allocator.free(name);

    try file.print(
        \\pub const {s} = struct {{
        \\
    , .{name});

    for (constructor.params.items) |param| {
        if (param.type_def) {
            @panic("TODO: type_def");
        }
        if (param.type.? == .Flags) {
            continue;
        }

        const ty = try utils.parameterTypeToZig(allocator, param.type.?, mtproto);
        defer allocator.free(ty);

        try file.print(
            \\    {s}: {s},
            \\
        , .{ utils.safeStrParam(param.name), ty });
    }

    try deserialize.generateConstructorDeserializeSize(allocator, constructor, name, file, mtproto);
    try deserialize.generateConstructorDeserialize(allocator, constructor, name, file, mtproto);

    try serialize.generateConstructorSerializeSize(allocator, constructor, name, file, mtproto);
    try serialize.generateConstructorSerialize(allocator, constructor, name, file, mtproto);

    try clone.generateConstructorCloneSize(allocator, constructor, name, file, mtproto);
    try clone.generateConstructorClone(allocator, constructor, name, file, mtproto);

    try file.print(
        \\
        \\}};
        \\
    , .{});
}
