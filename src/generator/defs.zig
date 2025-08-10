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
