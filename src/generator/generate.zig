const std = @import("std");
const parser = @import("../parser/parse.zig");
const constructors = @import("../parser/constructors.zig");
const types = @import("../parser/types.zig");
const TLParameterType = @import("../parser/parameters_type.zig").TLParameterType;

//fn readTypes(constructor: *const constructors.TLConstructor) void {

//}
fn parseFile(allocator: std.mem.Allocator, definitions: *std.ArrayList(constructors.TLConstructor), filename: []const u8) !void {
    const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();

    const stat = try file.stat();
    const data = try file.readToEndAlloc(allocator, stat.size);
    defer allocator.free(data);

    var iterator = try parser.TlIterator.init(allocator, data);
    defer iterator.deinit();
    while (try iterator.next()) |constructor| {
        try definitions.append(constructor);
    }
}

/// Finds the layer version from a TL schema file.
///
/// The file should contain a comment like `//LAYER #`.
fn findLayer(filename: []const u8) !?i32 {
    const LAYER_DEF = "LAYER";
    const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();

    var in: [20]u8 = undefined;

    // readUntilDelimiterOrEof returns StreamTooLong if the slice you have passed is too small, we just ignore it
    while (file.reader().readUntilDelimiterOrEof(&in, '\n') catch "") |layer| {
        if (std.mem.startsWith(u8, layer, "//")) {
            if (std.mem.indexOf(u8, layer, LAYER_DEF)) |pos| {
                return try std.fmt.parseInt(i32, std.mem.trim(u8, layer[pos + LAYER_DEF.len ..], " "), 10);
            }
        }
    }
    return null;
}

fn tlPrimitiveName(name: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, name, "int")) {
        return "i32";
    } else if (std.mem.eql(u8, name, "long")) {
        return "i64";
    } else if (std.mem.eql(u8, name, "string") or std.mem.eql(u8, name, "bytes")) {
        return "[]const u8";
    } else if (std.mem.eql(u8, name, "double")) {
        return "f64";
    } else if (std.mem.eql(u8, name, "int128")) {
        return "i128";
    } else if (std.mem.eql(u8, name, "int256")) {
        return "i256";
    } else if (std.mem.eql(u8, name, "Bool")) {
        return "bool";
    } else {
        return null;
    }
}

fn normalizeNameAlloc(allocator: std.mem.Allocator, def: *const types.TLType, mtproto: bool) ![]const u8 {
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    if (mtproto) {
        _ = try list.appendSlice("Proto");
    }
    for (def.namespaces.items) |namespace| {
        _ = try list.append(std.ascii.toUpper(namespace[0]));
        _ = try list.appendSlice(namespace[1..]);
    }

    var i: usize = 0;
    var makeUpper = true;
    for (def.name) |c| {
        if (c == '_') {
            makeUpper = true;
            continue;
        }
        if (i == 0 or makeUpper) {
            _ = try list.append(std.ascii.toUpper(c));
            makeUpper = false;
        } else {
            _ = try list.append(c);
        }
        i += 1;
    }

    return list.toOwnedSlice();
}

fn normalizeName(writer: std.io.AnyWriter, def: anytype, mtproto: bool) !void {
    if (mtproto) {
        _ = try writer.write("Proto");
    }
    for (def.namespaces.items) |namespace| {
        _ = try writer.writeByte(std.ascii.toUpper(namespace[0]));
        _ = try writer.write(namespace[1..]);
    }

    var i: usize = 0;
    var makeUpper = true;
    for (def.name) |c| {
        if (c == '_') {
            makeUpper = true;
            continue;
        }
        if (i == 0 or makeUpper) {
            _ = try writer.writeByte(std.ascii.toUpper(c));
            makeUpper = false;
        } else {
            _ = try writer.writeByte(c);
        }
        i += 1;
    }
}

fn tlGenIdEnum(writer: std.io.AnyWriter, definitions: *const std.ArrayList(constructors.TLConstructor), mtproto_definitions: *const std.ArrayList(constructors.TLConstructor)) !void {
    _ = try writer.write("const TLID = enum(u32) {\n");

    for (mtproto_definitions.items) |def| {
        _ = try writer.write("    ");
        _ = try normalizeName(writer, &def, true);
        _ = try writer.write(" = ");
        _ = try writer.print("{d}", .{def.id});
        _ = try writer.write(",\n");
    }

    for (definitions.items) |def| {
        _ = try writer.write("    ");
        _ = try normalizeName(writer, &def, false);
        _ = try writer.write(" = ");
        _ = try writer.print("{d}", .{def.id});
        _ = try writer.write(",\n");
    }

    // hardcoded ids

    _ = try writer.write("    BoolTrue = 0x997275B5,\n");
    _ = try writer.write("    BoolFalse = 0xBC799737,\n");
    _ = try writer.write("    MessageContainer = 0x73F1F8DC,\n");
    _ = try writer.write("    FutureSalts = 0xAE500895,\n");
    _ = try writer.write("    RPCResult = 0xf35c6d01,\n");
    _ = try writer.write("    Vector = 0x1cb5c415,\n");
    _ = try writer.write("    Int = 4,\n");
    _ = try writer.write("    Long = 8,\n");

    _ = try writer.write("};\n");
}

/// Concatenates two slices of bytes by reallocating the first slice.
fn concat(allocator: std.mem.Allocator, a: []u8, b: []const u8) ![]u8 {
    var ab = try allocator.realloc(a, a.len + b.len);
    @memcpy(ab[a.len..], b);
    return ab;
}

const GenerateFieldTypeError = error{ UnsupportedIntBits, UnsupportedGenericArg, UnsupportedNestedVectors };

fn generateFieldType(allocator: std.mem.Allocator, field: TLParameterType, mtproto: bool) ![]const u8 {
    switch (field) {
        .Flags => {
            return try allocator.dupe(u8, "usize");
        },
        .Normal => {
            if (field.Normal.type.generic_ref) {
                return try allocator.dupe(u8, "TL");
            }

            var result = try allocator.dupe(u8, "");
            errdefer allocator.free(result);

            if (std.mem.eql(u8, field.Normal.type.name, "true")) {
                return try allocator.dupe(u8, "bool = false");
            }

            if (field.Normal.flag) |_| {
                result = try concat(allocator, result, "?");
            }

            var generic_arg = field.Normal.type.generic_arg;
            while (generic_arg) |garg| {
                if (garg.namespaces.items.len > 0) {
                    return GenerateFieldTypeError.UnsupportedGenericArg;
                }

                if (!std.mem.eql(u8, garg.name, "Vector")) {
                    std.debug.print("Unsupported generic arg: {s}\n", .{garg.name});
                    return GenerateFieldTypeError.UnsupportedGenericArg;
                }

                result = try concat(allocator, result, "[]const ");
                generic_arg = garg.generic_arg;
            }

            if (std.mem.eql(u8, field.Normal.type.name, "int")) {
                result = try concat(allocator, result, "i32");
            } else if (std.mem.eql(u8, field.Normal.type.name, "long")) {
                result = try concat(allocator, result, "i64");
            } else if (std.mem.eql(u8, field.Normal.type.name, "string") or std.mem.eql(u8, field.Normal.type.name, "bytes")) {
                result = try concat(allocator, result, "[]const u8");
            } else if (std.mem.eql(u8, field.Normal.type.name, "double")) {
                result = try concat(allocator, result, "f64");
            } else if (std.mem.eql(u8, field.Normal.type.name, "int128")) {
                result = try concat(allocator, result, "i128");
            } else if (std.mem.eql(u8, field.Normal.type.name, "int256")) {
                result = try concat(allocator, result, "i256");
            } else if (std.mem.eql(u8, field.Normal.type.name, "Bool")) {
                result = try concat(allocator, result, "bool");
            } else {
                const normalized = try normalizeNameAlloc(allocator, field.Normal.type, mtproto);
                defer allocator.free(normalized);

                result = try concat(allocator, result, "I");

                result = try concat(allocator, result, normalized);
            }

            if (field.Normal.flag) |_| {
                result = try concat(allocator, result, " = null");
            }

            return result;
        },
    }
}

fn generateDefinition(allocator: std.mem.Allocator, writer: std.io.AnyWriter, def: *const constructors.TLConstructor, mtproto: bool) !void {
    _ = try writer.write("pub const ");
    _ = try normalizeName(writer, def, mtproto);
    _ = try writer.write("= struct {\n");
    for (def.params.items) |param| {
        const name = name: {
            if (std.mem.eql(u8, param.name, "Type")) {
                break :name "Type";
            }
            if (std.mem.eql(u8, param.name, "error")) {
                break :name "Error";
            }
            if (std.mem.eql(u8, param.name, "test")) {
                break :name "Test";
            }
            break :name param.name;
        };

        const typeName = try generateFieldType(def.allocator, param.type.?, mtproto);
        defer def.allocator.free(typeName);
        if (std.mem.eql(u8, typeName, "usize")) {
            continue;
        }

        _ = try writer.print("    {s}: {s},\n", .{ name, typeName });
    }

    _ = try generateSerializedSizeFn(allocator, def, writer);
    _ = try generateDeserializedSizeFn(allocator, def, writer, mtproto);
    _ = try generateSerializeFn(allocator, def, writer);
    _ = try generateDeserializeFn(allocator, def, writer);
    _ = try generateSizeFn(allocator, def, writer);
    _ = try generateCloneFn(allocator, def, writer);
    _ = try writer.write("};\n");
}

fn tlGenBaseUnion(allocator: std.mem.Allocator, writer: std.io.AnyWriter, definitions: *const std.ArrayList(constructors.TLConstructor), mtproto_definitions: *const std.ArrayList(constructors.TLConstructor)) !void {
    for (mtproto_definitions.items) |def| {
        try generateDefinition(allocator, writer, &def, true);
    }

    for (definitions.items) |def| {
        try generateDefinition(allocator, writer, &def, false);
    }

    _ = try writer.write("pub const TL = union(TLID) {\n");

    for (mtproto_definitions.items) |def| {
        _ = try normalizeName(writer, def, true);
        _ = try writer.write(": *const ");
        _ = try normalizeName(writer, def, true);
        _ = try writer.write(",\n");
    }

    for (definitions.items) |def| {
        _ = try normalizeName(writer, def, false);
        _ = try writer.write(": *const ");
        _ = try normalizeName(writer, def, false);
        _ = try writer.write(",\n");
    }

    // hardcoded ids
    _ = try writer.write("    BoolTrue: bool,\n");
    _ = try writer.write("    BoolFalse: bool,\n");
    _ = try writer.write("    MessageContainer: *const base.MessageContainer(TL),\n");
    _ = try writer.write("    FutureSalts: *const base.FutureSalts,\n");
    _ = try writer.write("    RPCResult: *const base.RPCResult(TL),\n");
    _ = try writer.write("    Vector: *const base.Vector(TL),\n");
    _ = try writer.write("    Int: i32,\n");
    _ = try writer.write("    Long: i64,\n");

    _ = try writer.write("    pub fn cloneSize(self: *const @This(), size: *usize) void {\n        @setEvalBranchQuota(1000000);\n        switch (self.*) {\n        .BoolTrue, .BoolFalse, .Int => return,\n        .Long => return,\n        inline else => |x| x.cloneSize(size),\n        }\n    }\n");

    _ = try writer.write("    pub fn clone(self: *const @This(), dest: []u8, size: *usize) TL {\n        @setEvalBranchQuota(1000000);\n        switch (self.*) {\n            .BoolTrue, .BoolFalse, .Int, .Long => return self.*,\n            .MessageContainer => |x| {\n                return .{ .MessageContainer = x.clone(dest, size) };\n            },\n            .FutureSalts => |x| {\n                return .{ .FutureSalts = x.clone(dest, size) };\n            },\n            .RPCResult => |x| {\n                return .{ .RPCResult = x.clone(dest, size) };\n            },\n            .Vector => |x| {\n                return .{ .Vector = x.clone(dest, size) };\n            },\n");

    for (mtproto_definitions.items) |def| {
        _ = try writer.write("            .");
        _ = try normalizeName(writer, def, true);
        _ = try writer.write(" => |x| {\n");
        _ = try writer.write("                return .{ .");
        _ = try normalizeName(writer, def, true);
        _ = try writer.write(" = x.clone(dest, size) };\n            },\n");
    }

    for (definitions.items) |def| {
        _ = try writer.write("            .");
        _ = try normalizeName(writer, def, false);
        _ = try writer.write(" => |x| {\n");
        _ = try writer.write("                return .{ .");
        _ = try normalizeName(writer, def, false);
        _ = try writer.write(" = x.clone(dest, size) };\n            },\n");
    }

    _ = try writer.write("        }\n    }\n");

    _ = try writer.write("    pub fn serializedSize(self: *const @This()) usize {\n        @setEvalBranchQuota(1000000);\n        switch (self.*) {\n        .BoolTrue, .BoolFalse, .Int => return 4,\n        .Long => return 8,\n        inline else => |x| return x.serializedSize(),\n        }\n    }\n");

    _ = try writer.write("    pub fn serialize(self: *const @This(), dest: []u8) usize {\n        @setEvalBranchQuota(1000000);\n        switch (self.*) {\n        .BoolTrue => return base.serializeInt(@as(u32, 0x997275b5), dest),\n        .BoolFalse => return base.serializeInt(@as(u32, 0xbc799737), dest),\n        .Int => |x| return base.serializeInt(x, dest),\n        .Long => |x| return base.serializeInt(x, dest),\n        inline else => |x| return x.serialize(dest),\n        }\n    }\n");

    //    _ = try writer.write("    pub fn deinit(self: *const @This(), allocator: std.mem.Allocator) void {\n        switch (self.*) {\n");

    //    for (definitions.items) |def| {
    //        _ = try writer.write("        .");
    //        _ = try normalizeName(writer, def, false);
    //        _ = try writer.write(" => { self.");
    //        _ = try normalizeName(writer, def, false);
    //        _ = try writer.write(".deinit(allocator); },\n");
    //    }
    //    _ = try writer.write("        }\n");
    //    _ = try writer.write("    }\n");

    /////

    _ = try writer.write("    pub fn deserialize(src: []const u8, dest: []u8, cursor: *usize, written: *usize) TL {\n");

    _ = try writer.write("        const id = std.mem.readInt(u32, @ptrCast(src[cursor.*..cursor.*+4]), std.builtin.Endian.little);\n        cursor.* += 4;\n");
    //        switch (@as(ChatEnumID, @enumFromInt(id))) {
    _ = try writer.write("        switch (id) {\n");

    _ = try writer.write("            0x73F1F8DC => {\n                const deserialized = base.MessageContainer(TL).deserialize(src, dest, cursor, written);\n                return .{ .MessageContainer = deserialized };\n            },\n");
    _ = try writer.write("            0xAE500895 => {\n                const deserialized = base.FutureSalts.deserialize(src, dest, cursor, written);\n                return .{ .FutureSalts = deserialized };\n            },\n");
    _ = try writer.write("            0xf35c6d01 => {\n                const deserialized = base.RPCResult(TL).deserialize(src, dest, cursor, written);\n                return .{ .RPCResult = deserialized };\n            },\n");
    _ = try writer.write("            0x1cb5c415 => {\n                const deserialized = base.Vector(TL).deserialize(src, dest, cursor, written);\n                return .{ .Vector = deserialized };\n            },\n");
    _ = try writer.write("            0x997275B5 => {\n                return .{ .BoolTrue = true };\n            },\n");
    _ = try writer.write("            0xBC799737 => {\n                return .{ .BoolFalse = false };\n            },\n");

    for (mtproto_definitions.items) |def| {
        _ = try writer.print("            {d} => {{\n                const deserialized = ", .{def.id});
        _ = try normalizeName(writer, def, true);
        _ = try writer.write(".deserialize(src, dest, cursor, written);\n");
        _ = try writer.write("                return .{ .");
        _ = try normalizeName(writer, def, true);
        _ = try writer.write(" = deserialized };\n            },\n");
    }

    for (definitions.items) |def| {
        _ = try writer.print("            {d} => {{\n                const deserialized = ", .{def.id});
        _ = try normalizeName(writer, def, false);
        _ = try writer.write(".deserialize(src, dest, cursor, written);\n");
        _ = try writer.write("                return .{ .");
        _ = try normalizeName(writer, def, false);
        _ = try writer.write(" = deserialized };\n            },\n");
    }

    _ = try writer.write("            else => {\n                @panic(\"Unable to find valid id for this constructor\");\n            },\n");

    _ = try writer.write("        }\n");
    _ = try writer.write("    }\n");

    //////

    _ = try writer.write("    pub fn deserializedSize(src: []const u8, cursor: *usize, size: *usize) void {\n");

    _ = try writer.write("        const id = std.mem.readInt(u32, @ptrCast(src[cursor.*..cursor.*+4]), std.builtin.Endian.little);\n        cursor.* += 4;\n");
    //        switch (@as(ChatEnumID, @enumFromInt(id))) {
    _ = try writer.write("        switch (id) {\n");

    _ = try writer.write("            0x73F1F8DC => {\n                base.MessageContainer(TL).deserializedSize(src, cursor, size);\n            },\n");
    _ = try writer.write("            0xAE500895 => {\n                base.FutureSalts.deserializedSize(src, cursor, size);\n            },\n");
    _ = try writer.write("            0xf35c6d01 => {\n                base.RPCResult(TL).deserializedSize(src, cursor, size);\n            },\n");
    _ = try writer.write("            0x1cb5c415 => {\n                base.Vector(TL).deserializedSize(src, cursor, size);\n            },\n");
    _ = try writer.write("            0x997275B5, 0xBC799737 => {},\n");

    for (mtproto_definitions.items) |def| {
        _ = try writer.print("            {d} => {{\n                ", .{def.id});
        _ = try normalizeName(writer, def, true);
        _ = try writer.write(".deserializedSize(src, cursor, size);\n            },\n");
    }

    for (definitions.items) |def| {
        _ = try writer.print("            {d} => {{\n                ", .{def.id});
        _ = try normalizeName(writer, def, false);
        _ = try writer.write(".deserializedSize(src, cursor, size);\n            },\n");
    }

    _ = try writer.write("            else => {\n                @panic(\"Unable to find valid id for this constructor\");\n            },\n        }\n");
    _ = try writer.write("    }\n");

    _ = try writer.write("};\n");
}

/// Lazy way of IDing the type of a constructor by doing the crc32 of it
fn constructorTypeHash(def: *const types.TLType, mtproto: bool) u32 {
    var hash = std.hash.Crc32.init();
    if (mtproto) {
        hash.update("Proto");
    }

    for (def.namespaces.items) |namespace| {
        hash.update(namespace);
    }

    var generic_arg = def.generic_arg;
    while (generic_arg) |garg| {
        hash.update(garg.name);
        generic_arg = garg.generic_arg;
    }

    hash.update(def.name);

    return hash.final();
}

fn safeParamName(in: []const u8) []const u8 {
    if (std.mem.eql(u8, in, "Type")) {
        return "Type";
    }
    if (std.mem.eql(u8, in, "error")) {
        return "Error";
    }
    if (std.mem.eql(u8, in, "test")) {
        return "Test";
    }
    return in;
}

fn generateSerializeFnFlags(flag_name: []const u8, def: *const constructors.TLConstructor, writer: std.io.AnyWriter) !void {
    var found = false;
    for (def.params.items) |param| {
        if (param.type_def)
            continue;
        switch (param.type.?) {
            .Normal => if (param.type.?.Normal.flag) |flag| {
                if (std.mem.eql(u8, flag_name, flag.name)) {
                    if (!found) {
                        found = true;
                        _ = try writer.print("        var flag_{s}: usize = 0;\n", .{flag_name});
                    }

                    if (std.mem.eql(u8, param.type.?.Normal.type.name, "true")) {
                        _ = try writer.print("        if (self.{s}) {{\n             flag_{s} = flag_{s} | 1 << {d};\n        }}\n", .{ safeParamName(param.name), flag_name, flag_name, flag.index });
                    } else {
                        _ = try writer.print("        if (self.{s}) |_| {{\n             flag_{s} = flag_{s} | 1 << {d};\n        }}\n", .{ safeParamName(param.name), flag_name, flag_name, flag.index });
                    }
                }
            },
            .Flags => {},
        }
    }

    if (!found) {
        _ = try writer.print("        written += base.serializeInt(@as(u32, 0), dest[written..]);\n", .{});

        return;
    }
    _ = try writer.write("\n");

    _ = try writer.print("        written += base.serializeInt(flag_{s}, dest[written..]);\n", .{flag_name});
}

fn generateDeserializeFn(allocator: std.mem.Allocator, def: *const constructors.TLConstructor, writer: std.io.AnyWriter) !void {
    _ = try writer.write("    pub fn deserialize(src: []const u8, dest: []u8, cursor: *usize, written: *usize) *@This() {\n");
    if (def.params.items.len == 0) {
        _ = try writer.write("        _ = src;\n        //_ = dest;\n        _ = cursor;\n        const alignment = base.ensureAligned(written.*, @alignOf(*@This()));\n    const result = @as(*@This(), @alignCast(@ptrCast(dest[written.*+alignment..].ptr)));\n        written.* += alignment + @sizeOf(@This());\n    return result;\n    }\n");
        return;
    }

    _ = try writer.print("        const alignment = base.ensureAligned(written.*, @alignOf(*@This()));\n        var result = @as(*@This(), @alignCast(@ptrCast(dest[written.*+alignment..].ptr)));\n        written.* += alignment + @sizeOf(@This());\n", .{});

    for (def.params.items) |param| {
        if (param.type_def) {
            _ = try writer.write("        //IMPLEMENT TYPEDEF\n");
            continue;
        }

        switch (param.type.?) {
            .Flags => {
                _ = try writer.print("        var flag_{s}: usize = 0;\n        cursor.* += base.deserializeInt(usize, src[cursor.*..], &flag_{s});\n", .{ param.name, param.name });
            },
            .Normal => {
                if (param.type_def) {
                    _ = try writer.write("        //IMPLEMENT TYPEDEF\n");
                    continue;
                }

                if (param.type.?.Normal.flag != null and std.mem.eql(u8, param.type.?.Normal.type.name, "true")) {
                    _ = try writer.print("        result.{s} = (flag_{s} & (1 << {d})) != 0;\n", .{ safeParamName(param.name), param.type.?.Normal.flag.?.name, param.type.?.Normal.flag.?.index });
                    continue;
                }

                if (param.type.?.Normal.flag) |_| {
                    _ = try writer.print("        if ((flag_{s} & (1 << {d})) != 0) {{\n", .{ param.type.?.Normal.flag.?.name, param.type.?.Normal.flag.?.index });
                }

                var param_name = try concat(allocator, try allocator.dupe(u8, "result."), safeParamName(param.name));
                defer allocator.free(param_name);

                if (param.type.?.Normal.flag) |_| {
                    if (std.mem.eql(u8, param.type.?.Normal.type.name, "int") or std.mem.eql(u8, param.type.?.Normal.type.name, "long") or std.mem.eql(u8, param.type.?.Normal.type.name, "double") or std.mem.eql(u8, param.type.?.Normal.type.name, "int128") or std.mem.eql(u8, param.type.?.Normal.type.name, "int256") or std.mem.eql(u8, param.type.?.Normal.type.name, "string") or std.mem.eql(u8, param.type.?.Normal.type.name, "bytes")) {
                        _ = try writer.print("        {s} = undefined;\n", .{param_name});
                        param_name = try concat(allocator, param_name, ".?");
                    }
                }

                if (param.type.?.Normal.type.generic_arg) |generic_arg| {
                    // TODO: Maybe implement multidimensional vectors support. Telegram has never added them into the TL scheme for over 10+ years, so I don't bother right now.
                    if (generic_arg.generic_arg != null) {
                        return GenerateFieldTypeError.UnsupportedGenericArg;
                    }
                    _ = try writer.print("        {{\n          const len = base.vectorLen(src[cursor.*..], cursor);\n", .{});

                    if (!std.mem.eql(u8, param.type.?.Normal.type.name, "Bool")) {
                        _ = try writer.print("        written.* += base.ensureAligned(written.*, @alignOf(@TypeOf({s})));\n", .{param_name});
                    }

                    _ = try writer.print("        const {s}_vector = @constCast(@as(@TypeOf(result.{s}), @alignCast(std.mem.bytesAsSlice(base.unwrapType(@TypeOf(result.{s})), dest[written.* .. written.* + (len * @sizeOf(base.unwrapType(@TypeOf(result.{s}))))]))));\n", .{ safeParamName(param.name), safeParamName(param.name), safeParamName(param.name), safeParamName(param.name) });

                    _ = try writer.print("        written.* += @sizeOf(base.unwrapType(@TypeOf({s}))) * len;\n", .{param_name});

                    _ = try writer.print("        for (0..len) |i| {{\n", .{});

                    allocator.free(param_name);
                    if (param.type.?.Normal.flag != null) {
                        param_name = try std.fmt.allocPrint(allocator, "{s}_vector.?[i]", .{safeParamName(param.name)});
                    } else {
                        param_name = try std.fmt.allocPrint(allocator, "{s}_vector[i]", .{safeParamName(param.name)});
                    }
                }

                if (std.mem.eql(u8, param.type.?.Normal.type.name, "int") or std.mem.eql(u8, param.type.?.Normal.type.name, "long") or std.mem.eql(u8, param.type.?.Normal.type.name, "double") or std.mem.eql(u8, param.type.?.Normal.type.name, "int128") or std.mem.eql(u8, param.type.?.Normal.type.name, "int256")) {
                    _ = try writer.print("        cursor.* += base.deserializeInt(base.unwrapType(@TypeOf({s})), src[cursor.*..], &{s});\n", .{ param_name, param_name });
                } else if (std.mem.eql(u8, param.type.?.Normal.type.name, "string") or std.mem.eql(u8, param.type.?.Normal.type.name, "bytes")) {
                    _ = try writer.print("        {s} = dest[written.*..];\n        cursor.* += base.deserializeString(src[cursor.*..], &{s});\n        written.* += {s}.len;\n", .{ param_name, param_name, param_name });
                } else if (std.mem.eql(u8, param.type.?.Normal.type.name, "Bool")) {
                    _ = try writer.print("        {s} = base.deserializeBool(src[cursor.*..], cursor);\n", .{param_name});
                } else {
                    _ = try writer.print("        {s} = base.unwrapType(@TypeOf({s})).deserialize(src, dest, cursor, written);\n", .{ param_name, param_name });
                }

                if (param.type.?.Normal.type.generic_arg) |_| {
                    _ = try writer.print("        }}\n        result.{s} = {s}_vector;\n        }}\n", .{ safeParamName(param.name), safeParamName(param.name) });
                }

                if (param.type.?.Normal.flag) |_| {
                    _ = try writer.print("        }}\n        else {{\n         result.{s} = null;\n        }}", .{safeParamName(param.name)});
                }

                _ = try writer.write("\n");
            },
        }
    }

    _ = try writer.write("\n    return result;\n    }\n");
}

fn generateSerializeFn(allocator: std.mem.Allocator, def: *const constructors.TLConstructor, writer: std.io.AnyWriter) !void {
    //    var flags = std.StringArrayHashMap(usize).init(allocator);
    //    defer flags.deinit();
    _ = try writer.write("    pub fn serialize(self: *const @This(), dest: []u8) usize {\n        var written: usize = 0;\n");

    _ = try writer.print("        written += base.serializeInt(@as(u32, {d}), dest[written..]);\n", .{def.id});

    if (def.params.items.len == 0) {
        _ = try writer.write("        _ = self;\n        return 4;\n    }\n");
        return;
    }

    for (def.params.items) |param| {
        if (param.type_def) {
            _ = try writer.write("        //IMPLEMENT TYPEDEF\n");
            continue;
        }

        switch (param.type.?) {
            .Flags => {
                try generateSerializeFnFlags(param.name, def, writer);
            },
            .Normal => {
                if (param.type.?.Normal.flag != null and std.mem.eql(u8, param.type.?.Normal.type.name, "true")) {
                    //objc.{a.parameterName} = objc.{a.parameterName} or FlagBit(1) shl FlagBit({a.index})")
                    //    _ = try writer.print("if (self.{s}) {{\n            flag_{s} = flag_{s} | 1 << {d};\n        }}\n", .{ param.name, param.name, param.type.?.Normal.flag.index });
                    continue;
                }

                _ = try writer.print("        const param{s} = self.{s};\n", .{ param.name, safeParamName(param.name) });

                var paramName = try concat(allocator, try allocator.dupe(u8, "param"), param.name);
                defer allocator.free(paramName);

                if (param.type.?.Normal.flag) |_| {
                    _ = try writer.print("        if ({s}) |{s}flag| {{\n", .{ paramName, paramName });
                    paramName = try concat(allocator, paramName, "flag");
                }

                var generic_arg = param.type.?.Normal.type.generic_arg;
                while (generic_arg) |garg| {
                    if (garg.namespaces.items.len > 0) {
                        return GenerateFieldTypeError.UnsupportedGenericArg;
                    }

                    if (!std.mem.eql(u8, garg.name, "Vector")) {
                        return GenerateFieldTypeError.UnsupportedGenericArg;
                    }

                    _ = try writer.print("        written += base.serializeInt(@as(u32, 0x1cb5c415), dest[written..]);\n", .{});
                    _ = try writer.print("        written += base.serializeInt({s}.len, dest[written..]);\n", .{paramName});
                    generic_arg = garg.generic_arg;

                    _ = try writer.print("        for ({s}) |{s}item| {{\n", .{ paramName, paramName });
                    paramName = try concat(allocator, paramName, "item");
                }

                if (std.mem.eql(u8, param.type.?.Normal.type.name, "int") or std.mem.eql(u8, param.type.?.Normal.type.name, "long") or std.mem.eql(u8, param.type.?.Normal.type.name, "double") or std.mem.eql(u8, param.type.?.Normal.type.name, "int128") or std.mem.eql(u8, param.type.?.Normal.type.name, "int256")) {
                    _ = try writer.print("        written += base.serializeInt({s}, dest[written..]);\n", .{paramName});
                } else if (std.mem.eql(u8, param.type.?.Normal.type.name, "string") or std.mem.eql(u8, param.type.?.Normal.type.name, "bytes")) {
                    _ = try writer.print("        written += base.serializeString({s}, dest[written..]);\n", .{paramName});
                } else if (std.mem.eql(u8, param.type.?.Normal.type.name, "Bool")) {
                    _ = try writer.print("        written += base.serializeInt(if ({s}) @as(u32, 0x997275b5) else @as(u32, 0xbc799737), dest[written..]);\n", .{paramName});
                } else {
                    _ = try writer.print("        written += {s}.serialize(dest[written..]);\n", .{paramName});
                }

                generic_arg = param.type.?.Normal.type.generic_arg;
                while (generic_arg) |garg| {
                    _ = try writer.write("        }\n");
                    generic_arg = garg.generic_arg;
                }

                if (param.type.?.Normal.flag) |_| {
                    _ = try writer.write("        }\n");
                }

                _ = try writer.write("\n");

                //_ = try writer.print("        //IMPLEMENT NORMAL\n", .{});
            },
        }
    }
    //_ = allocator;

    _ = try writer.write("        return written;\n    }\n");
}

fn generateDeserializedSizeFn(allocator: std.mem.Allocator, def: *const constructors.TLConstructor, writer: std.io.AnyWriter, mtproto: bool) !void {
    _ = try writer.write("    pub fn deserializedSize(src: []const u8, cursor: *usize, size: *usize) void {\n");
    if (def.params.items.len == 0) {
        _ = try writer.write("        _ = src; _ = cursor;\n        size.* += base.ensureAligned(size.*, @alignOf(*@This())) + @sizeOf(@This());\n    }");
        return;
    }

    _ = try writer.write("\n        size.* += base.ensureAligned(size.*, @alignOf(*@This())) + @sizeOf(@This());\n");
    var srcUsed = false;
    var sizeMutated = true;

    for (def.params.items) |param| {
        if (param.type_def) {
            _ = try writer.write("        //IMPLEMENT TYPEDEF\n");
            continue;
        }
        switch (param.type.?) {
            .Flags => {
                srcUsed = true;
                _ = try writer.print("        var flag_{s}: usize = 0;\n        cursor.* += base.deserializeInt(usize, src[cursor.*..], &flag_{s});\n", .{ param.name, param.name });
            },
            .Normal => {
                if (param.type.?.Normal.flag != null and std.mem.eql(u8, param.type.?.Normal.type.name, "true")) {
                    _ = try writer.print("        // true flag\n\n", .{});
                    continue;
                }

                if (param.type.?.Normal.flag) |_| {
                    _ = try writer.print("        if ((flag_{s} & (1 << {d})) != 0) {{\n", .{ param.type.?.Normal.flag.?.name, param.type.?.Normal.flag.?.index });
                }

                if (param.type.?.Normal.type.generic_arg) |generic_arg| {
                    // TODO: Maybe implement multidimensional vectors support. Telegram has never added them into the TL scheme for over 10+ years, so I don't bother right now.
                    if (generic_arg.generic_arg != null) {
                        return GenerateFieldTypeError.UnsupportedGenericArg;
                    }
                    srcUsed = true;
                    sizeMutated = true;
                    _ = try writer.print("        {{\n           const len = base.vectorLen(src[cursor.*..], cursor);\n", .{});

                    if (std.mem.eql(u8, param.type.?.Normal.type.name, "string") or std.mem.eql(u8, param.type.?.Normal.type.name, "bytes")) {
                        _ = try writer.write("        size.* += base.ensureAligned(size.*, @alignOf([]const []const u8));\n        size.* += len * @sizeOf([]const u8);\n        for (0..len) |_| {\n          size.* += base.strDeserializedSize(src[cursor.*..], cursor);\n        }");
                    } else if (tlPrimitiveName(param.type.?.Normal.type.name)) |primitive| {
                        if (std.mem.eql(u8, primitive, "bool")) {
                            _ = try writer.print("        size.* += len * @sizeOf({s});\n        cursor.* += len * 4;\n", .{primitive});
                        } else {
                            _ = try writer.print("        size.* += base.ensureAligned(size.*, @alignOf({s}));\n        size.* += len * @sizeOf({s});\n        cursor.* += len * @sizeOf({s});\n", .{ primitive, primitive, primitive });
                        }
                    } else {
                        const normalized = try normalizeNameAlloc(allocator, param.type.?.Normal.type, mtproto);
                        defer allocator.free(normalized);
                        _ = try writer.print("        size.* += base.ensureAligned(size.*, @alignOf([]I{s})) + (len * @sizeOf(I{s}));\n        for (0..len) |_| {{\n          I{s}.deserializedSize(src, cursor, size);\n        }}", .{ normalized, normalized, normalized });
                    }

                    _ = try writer.write("        }");
                } else {
                    if (std.mem.eql(u8, param.type.?.Normal.type.name, "string") or std.mem.eql(u8, param.type.?.Normal.type.name, "bytes")) {
                        srcUsed = true;
                        sizeMutated = true;
                        _ = try writer.write("          size.* += base.strDeserializedSize(src[cursor.*..], cursor);");
                    } else if (tlPrimitiveName(param.type.?.Normal.type.name)) |primitive| {
                        if (std.mem.eql(u8, primitive, "bool")) {
                            _ = try writer.print("        cursor.* += 4;", .{});
                        } else {
                            _ = try writer.print("        cursor.* += @sizeOf({s});\n", .{primitive});
                        }
                    } else {
                        srcUsed = true;
                        sizeMutated = true;
                        if (param.type.?.Normal.type.generic_ref) {
                            _ = try writer.print("          TL.deserializedSize(src, cursor, size);", .{});
                        } else {
                            const normalized = try normalizeNameAlloc(allocator, param.type.?.Normal.type, mtproto);
                            defer allocator.free(normalized);
                            _ = try writer.print("          I{s}.deserializedSize(src, cursor, size);", .{normalized});
                        }
                    }
                }

                if (param.type.?.Normal.flag) |_| {
                    _ = try writer.write("        }");
                }
            },
        }

        _ = try writer.write("\n");
    }

    if (!srcUsed) {
        _ = try writer.write("        _ = src;\n");
    }

    if (!sizeMutated) {
        _ = try writer.write("        size = size;\n");
    }

    _ = try writer.write("        \n    }\n");
}

fn generateSerializedSizeFn(allocator: std.mem.Allocator, def: *const constructors.TLConstructor, writer: std.io.AnyWriter) !void {
    _ = try writer.write("    pub fn serializedSize(self: *const @This()) usize {\n");
    if (def.params.items.len == 0) {
        _ = try writer.write("        _ = self;\n        return 4;\n    }");
        return;
    }
    _ = try writer.write("        var result: usize = 4; // id\n");
    var usedSelf = false;

    for (def.params.items) |param| {
        _ = try writer.print("        // {s}\n", .{param.name});
        if (param.type_def) {
            _ = try writer.print("        result += self.{s}.serializedSize();\n", .{safeParamName(param.name)});
        } else {
            switch (param.type.?) {
                .Flags => {
                    _ = try writer.print("        result += 4; // {s}\n", .{param.name});
                },
                .Normal => {
                    if (param.type.?.Normal.flag != null and std.mem.eql(u8, param.type.?.Normal.type.name, "true")) {
                        _ = try writer.print("        // true flag\n\n", .{});
                        continue;
                    }
                    _ = try writer.print("        const param{s} = self.{s};\n", .{ param.name, safeParamName(param.name) });
                    var paramName = try concat(allocator, try allocator.dupe(u8, "param"), param.name);
                    defer allocator.free(paramName);
                    if (param.type.?.Normal.flag) |_| {
                        _ = try writer.print("        if ({s}) |{s}flag| {{\n", .{ paramName, paramName });
                        paramName = try concat(allocator, paramName, "flag");
                    }

                    var generic_arg = param.type.?.Normal.type.generic_arg;
                    while (generic_arg) |garg| {
                        if (garg.namespaces.items.len > 0) {
                            return GenerateFieldTypeError.UnsupportedGenericArg;
                        }

                        if (!std.mem.eql(u8, garg.name, "Vector")) {
                            return GenerateFieldTypeError.UnsupportedGenericArg;
                        }

                        _ = try writer.print("        result += 8; // vector id & size\n", .{});
                        _ = try writer.print("        for ({s}) |{s}item| {{\n", .{ paramName, paramName });

                        paramName = try concat(allocator, paramName, "item");

                        generic_arg = garg.generic_arg;
                    }

                    if (std.mem.eql(u8, param.type.?.Normal.type.name, "int") or std.mem.eql(u8, param.type.?.Normal.type.name, "long") or std.mem.eql(u8, param.type.?.Normal.type.name, "double") or std.mem.eql(u8, param.type.?.Normal.type.name, "int128") or std.mem.eql(u8, param.type.?.Normal.type.name, "int256")) {
                        _ = try writer.print("        result += @sizeOf(@TypeOf({s}));", .{paramName});
                    } else if (std.mem.eql(u8, param.type.?.Normal.type.name, "string") or std.mem.eql(u8, param.type.?.Normal.type.name, "bytes")) {
                        _ = try writer.print("        result += base.strSerializedSize({s});", .{paramName});
                    } else if (std.mem.eql(u8, param.type.?.Normal.type.name, "Bool")) {
                        _ = try writer.print("        _ = {s};\n        result += 4;", .{paramName});
                    } else {
                        _ = try writer.print("        result += {s}.serializedSize();\n", .{paramName});
                    }
                    usedSelf = true;
                    generic_arg = param.type.?.Normal.type.generic_arg;
                    while (generic_arg) |garg| {
                        _ = try writer.write("        }\n");
                        generic_arg = garg.generic_arg;
                    }

                    if (param.type.?.Normal.flag) |_| {
                        _ = try writer.write("        }\n");
                    }

                    _ = try writer.write("\n");
                },
            }
        }
    }
    if (!usedSelf) {
        _ = try writer.write("\n        _ = self;\n");
    }
    _ = try writer.write("        return result;\n    }\n");
}

fn generateCloneFn(allocator: std.mem.Allocator, def: *const constructors.TLConstructor, writer: std.io.AnyWriter) !void {
    _ = try writer.write("    pub fn clone(self: *const @This(), dest: []u8, size: *usize) *const @This() {\n");
    if (def.params.items.len == 0) {
        _ = try writer.write("        size.* += base.ensureAligned(size.*, @alignOf(@TypeOf(self)));\n        @memcpy(dest[size.*..size.*+@sizeOf(@This())], @as([*]const u8, @ptrCast(self))[0..@sizeOf(@This())]);\n        const result = @as(*@This(), @alignCast(@ptrCast(dest[size.*..size.*+@sizeOf(@This())].ptr)));\n        size.* += @sizeOf(@This());\n        return result;\n    }\n");
        return;
    }
    _ = try writer.write("\n        size.* += base.ensureAligned(size.*, @alignOf(@TypeOf(self)));\n        @memcpy(dest[size.*..size.*+@sizeOf(@This())], @as([*]const u8, @ptrCast(self))[0..@sizeOf(@This())]);\n        const result = @as(*@This(), @alignCast(@ptrCast(dest[size.*..size.*+@sizeOf(@This())].ptr)));\n        size.* += @sizeOf(@This());\n");

    for (def.params.items) |param| {
        if (param.type_def) {
            //_ = try writer.write("        //IMPLEMENT TYPEDEF\n");
            continue;
        }

        switch (param.type.?) {
            .Normal => {
                if (std.mem.eql(u8, param.type.?.Normal.type.name, "true")) {
                    continue;
                }
                if (param.type.?.Normal.type.generic_arg == null and std.mem.eql(u8, param.type.?.Normal.type.name, "int") or std.mem.eql(u8, param.type.?.Normal.type.name, "long") or std.mem.eql(u8, param.type.?.Normal.type.name, "double") or std.mem.eql(u8, param.type.?.Normal.type.name, "int128") or std.mem.eql(u8, param.type.?.Normal.type.name, "int256") or std.mem.eql(u8, param.type.?.Normal.type.name, "Bool")) {
                    continue;
                }

                var param_name = try concat(allocator, try allocator.dupe(u8, "self."), safeParamName(param.name));
                defer allocator.free(param_name);

                if (param.type.?.Normal.flag) |_| {
                    _ = try writer.print("        if (self.{s} != null) {{\n", .{safeParamName(param.name)});

                    allocator.free(param_name);
                    param_name = try std.fmt.allocPrint(allocator, "self.{s}.?", .{safeParamName(param.name)});
                }

                if (param.type.?.Normal.type.generic_arg) |generic_arg| {

                    // TODO: Maybe implement multidimensional vectors support. Telegram has never added them into the TL scheme for over 10+ years, so I don't bother right now.
                    if (generic_arg.generic_arg != null) {
                        return GenerateFieldTypeError.UnsupportedGenericArg;
                    }

                    if (std.mem.eql(u8, param.type.?.Normal.type.name, "string") or std.mem.eql(u8, param.type.?.Normal.type.name, "bytes")) {
                        //
                        _ = try writer.print("        {{\n        size.* += base.ensureAligned(size.*, @alignOf(@TypeOf({s})));\n        const {s}_vector: [][]const u8 = @alignCast(std.mem.bytesAsSlice([]const u8, dest[size.*..size.*+(@sizeOf([]const u8) * {s}.len)]));\n        size.* += (@sizeOf([]const u8) * {s}.len);\n        for(0..{s}.len) |i| {{\n        {s}_vector[i] = dest[size.*..size.*+{s}[i].len];\n           @memcpy(@constCast({s}_vector[i]), {s}[i]);\n        size.* += {s}[i].len;\n        }}\n        result.{s} = {s}_vector;\n        }}", .{ param_name, safeParamName(param.name), param_name, param_name, param_name, safeParamName(param.name), param_name, safeParamName(param.name), param_name, param_name, safeParamName(param.name), safeParamName(param.name) });
                    } else if (tlPrimitiveName(param.type.?.Normal.type.name)) |primitive| {
                        //
                        _ = try writer.print("        size.* += base.ensureAligned(size.*, @alignOf(@TypeOf({s})));\n        result.{s} = @alignCast(std.mem.bytesAsSlice({s}, dest[size.* .. size.* + (@sizeOf({s}) * {s}.len)]));\n        @memcpy(@constCast(result.{s}{s}), {s});\n        size.* += (@sizeOf({s}) * {s}.len);\n", .{ param_name, safeParamName(param.name), primitive, primitive, param_name, safeParamName(param.name), if (param.type.?.Normal.flag != null) ".?" else "", param_name, primitive, param_name });
                    } else {
                        //
                        _ = try writer.print("        {{\n        size.* += base.ensureAligned(size.*, @alignOf(@TypeOf({s})));\n        const {s}_vector = @constCast(@as(@TypeOf({s}), @alignCast(std.mem.bytesAsSlice(base.unwrapType(@TypeOf({s})), dest[size.* .. size.* + (@sizeOf(base.unwrapType(@TypeOf({s}))) * {s}.len)]))));\n        size.* += (@sizeOf(base.unwrapType(@TypeOf({s}))) * {s}.len);\n        for(0..{s}.len) |i| {{\n        {s}_vector[i] = {s}[i].clone(dest, size);\n        }}\n        result.{s} = {s}_vector;\n        }}", .{ param_name, safeParamName(param.name), param_name, param_name, param_name, param_name, param_name, param_name, param_name, safeParamName(param.name), param_name, safeParamName(param.name), safeParamName(param.name) });
                    }
                } else {
                    if (std.mem.eql(u8, param.type.?.Normal.type.name, "string") or std.mem.eql(u8, param.type.?.Normal.type.name, "bytes")) {
                        _ = try writer.print("        result.{s} = dest[size.*..size.*+{s}.len];\n        @memcpy(@constCast(result.{s}{s}), {s});\n        size.* += {s}.len;\n", .{ safeParamName(param.name), param_name, safeParamName(param.name), if (param.type.?.Normal.flag != null) ".?" else "", param_name, param_name });
                    } else {
                        _ = try writer.print("        result.{s} = {s}.clone(dest, size);\n", .{ safeParamName(param.name), param_name });
                    }
                }
            },
            else => continue,
        }

        if (param.type.?.Normal.flag) |_| {
            _ = try writer.write("        }\n");
        }

        _ = try writer.write("\n");
    }

    _ = try writer.write("        return result;\n    }\n");
}

fn generateSizeFn(allocator: std.mem.Allocator, def: *const constructors.TLConstructor, writer: std.io.AnyWriter) !void {
    _ = try writer.write("    pub fn cloneSize(self: *const @This(), size: *usize) void {\n");
    if (def.params.items.len == 0) {
        _ = try writer.write("        size.* += base.ensureAligned(size.*, @alignOf(@TypeOf(self))) + @sizeOf(@This());\n    }\n");
        return;
    }
    _ = try writer.write("\n        size.* += base.ensureAligned(size.*, @alignOf(@TypeOf(self))) + @sizeOf(@This());\n");

    for (def.params.items) |param| {
        if (param.type_def) {
            //_ = try writer.write("        //IMPLEMENT TYPEDEF\n");
            continue;
        }

        switch (param.type.?) {
            .Normal => {
                if (std.mem.eql(u8, param.type.?.Normal.type.name, "true")) {
                    continue;
                }
                if (param.type.?.Normal.type.generic_arg == null and std.mem.eql(u8, param.type.?.Normal.type.name, "int") or std.mem.eql(u8, param.type.?.Normal.type.name, "long") or std.mem.eql(u8, param.type.?.Normal.type.name, "double") or std.mem.eql(u8, param.type.?.Normal.type.name, "int128") or std.mem.eql(u8, param.type.?.Normal.type.name, "int256") or std.mem.eql(u8, param.type.?.Normal.type.name, "Bool")) {
                    continue;
                }

                var param_name = try concat(allocator, try allocator.dupe(u8, "self."), safeParamName(param.name));
                defer allocator.free(param_name);

                if (param.type.?.Normal.flag) |_| {
                    _ = try writer.print("        if (self.{s} != null) {{\n", .{safeParamName(param.name)});

                    allocator.free(param_name);
                    param_name = try std.fmt.allocPrint(allocator, "self.{s}.?", .{safeParamName(param.name)});
                }

                if (param.type.?.Normal.type.generic_arg) |generic_arg| {

                    // TODO: Maybe implement multidimensional vectors support. Telegram has never added them into the TL scheme for over 10+ years, so I don't bother right now.
                    if (generic_arg.generic_arg != null) {
                        return GenerateFieldTypeError.UnsupportedGenericArg;
                    }

                    if (std.mem.eql(u8, param.type.?.Normal.type.name, "string") or std.mem.eql(u8, param.type.?.Normal.type.name, "bytes")) {
                        _ = try writer.print("        size.* += base.ensureAligned(size.*, @alignOf(@TypeOf({s}))) + (@sizeOf([]const u8) * {s}.len);\n         for ({s}) |item| {{\n           size.* += item.len;\n         }}\n", .{ param_name, param_name, param_name });
                    } else if (tlPrimitiveName(param.type.?.Normal.type.name)) |primitive| {
                        _ = try writer.print("        size.* += base.ensureAligned(size.*, @alignOf(@TypeOf({s}))) + (@sizeOf({s}) * {s}.len);\n", .{ param_name, primitive, param_name });
                    } else {
                        _ = try writer.print("        size.* += base.ensureAligned(size.*, @alignOf(@TypeOf({s}))) + (@sizeOf(base.unwrapType(@TypeOf({s}))) * {s}.len);\n        for ({s}) |item| {{\n         item.cloneSize(size);\n        }}", .{ param_name, param_name, param_name, param_name });
                    }
                } else {
                    if (std.mem.eql(u8, param.type.?.Normal.type.name, "string") or std.mem.eql(u8, param.type.?.Normal.type.name, "bytes")) {
                        _ = try writer.print("        size.* += {s}.len;\n", .{param_name});
                    } else {
                        _ = try writer.print("        size.* += base.ensureAligned(size.*, @alignOf(@TypeOf({s})));\n        {s}.cloneSize(size);\n", .{ param_name, param_name });
                    }
                }
            },
            else => continue,
        }

        if (param.type.?.Normal.flag) |_| {
            _ = try writer.write("        }\n");
        }

        _ = try writer.write("\n");
    }

    _ = try writer.write("    }\n");
}

fn tlGenerateBoxedUnion(allocator: std.mem.Allocator, writer: std.io.AnyWriter, definitions: *const std.ArrayList(constructors.TLConstructor), mtproto_definitions: *const std.ArrayList(constructors.TLConstructor)) !void {
    var typess = std.AutoArrayHashMap(u32, std.ArrayList(constructors.TLConstructor)).init(allocator);
    defer {
        var iterator = typess.iterator();
        while (iterator.next()) |entry| {
            entry.value_ptr.deinit();
        }
        typess.deinit();
    }

    for (definitions.items) |def| {
        if (def.category == .Functions) {
            continue;
        }
        const hash = constructorTypeHash(def.type, false);
        if (typess.getEntry(hash)) |entry| {
            try entry.value_ptr.append(def);
        } else {
            var list = std.ArrayList(constructors.TLConstructor).init(allocator);
            try list.append(def);
            try typess.put(hash, list);
        }
    }

    var iterator = typess.iterator();

    while (iterator.next()) |ty| {
        _ = try writer.write("const ");
        _ = try normalizeName(writer, ty.value_ptr.items[0].type, false);
        _ = try writer.write("EnumID = enum(u32) {\n");
        for (ty.value_ptr.items) |def| {
            _ = try writer.write("    ");
            _ = try normalizeName(writer, def, false);
            _ = try writer.print(" = {d},\n", .{def.id});
        }
        _ = try writer.write("};\n");

        _ = try writer.write("pub const I");
        _ = try normalizeName(writer, ty.value_ptr.items[0].type, false);
        _ = try writer.write(" = union(");
        _ = try normalizeName(writer, ty.value_ptr.items[0].type, false);
        _ = try writer.write("EnumID) {\n");
        for (ty.value_ptr.items) |def| {
            _ = try writer.write("    ");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(": *const ");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(",\n");
        }

        _ = try writer.write("    pub fn serializedSize(self: *const @This()) usize {\n        switch (self.*) {\n");

        for (ty.value_ptr.items) |def| {
            _ = try writer.write("                .");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(" => { return self.");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(".serializedSize(); },\n");
        }
        _ = try writer.write("        }\n");
        _ = try writer.write("    }\n");

        _ = try writer.write("    pub fn cloneSize(self: *const @This(), size: *usize) void {\n        switch (self.*) {\n");

        for (ty.value_ptr.items) |def| {
            _ = try writer.write("                .");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(" => { return self.");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(".cloneSize(size); },\n");
        }
        _ = try writer.write("        }\n");
        _ = try writer.write("    }\n");

        _ = try writer.write("    pub fn clone(self: *const @This(), dest: []u8, size: *usize) @This() {\n        switch (self.*) {\n");

        for (ty.value_ptr.items) |def| {
            _ = try writer.write("                .");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(" => { return .{ .");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(" = self.");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(".clone(dest, size) }; },\n");
        }
        _ = try writer.write("        }\n");
        _ = try writer.write("    }\n");

        _ = try writer.write("    pub fn serialize(self: *const @This(), dest: []u8) usize {\n        switch (self.*) {\n");

        for (ty.value_ptr.items) |def| {
            _ = try writer.write("                .");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(" => { return self.");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(".serialize(dest); },\n");
        }
        _ = try writer.write("        }\n");
        _ = try writer.write("    }\n");

        _ = try writer.write("    pub fn deserialize(src: []const u8, dest: []u8, cursor: *usize, written: *usize) I");
        _ = try normalizeName(writer, ty.value_ptr.items[0].type, false);
        _ = try writer.write(" {\n");

        _ = try writer.write("        const id = std.mem.readInt(u32, @ptrCast(src[cursor.*..cursor.*+4]), std.builtin.Endian.little);\n        cursor.* += 4;\n");
        //        switch (@as(ChatEnumID, @enumFromInt(id))) {
        _ = try writer.write("        switch (@as(");
        _ = try normalizeName(writer, ty.value_ptr.items[0].type, false);
        _ = try writer.write("EnumID, @enumFromInt(id))) {\n");

        for (ty.value_ptr.items) |def| {
            _ = try writer.write("            .");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(" => {\n                const deserialized = ");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(".deserialize(src, dest, cursor, written);\n");
            _ = try writer.write("                return .{ .");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(" = deserialized };\n            },\n");
        }

        _ = try writer.write("        }\n");
        _ = try writer.write("    }\n");

        //pub fn deserializedSize(src: []const u8, cursor: *usize) usize {

        _ = try writer.write("    pub fn deserializedSize(src: []const u8, cursor: *usize, size: *usize) void {\n");

        _ = try writer.write("        const id = std.mem.readInt(u32, @ptrCast(src[cursor.*..cursor.*+4]), std.builtin.Endian.little);\n        cursor.* += 4;");
        //        switch (@as(ChatEnumID, @enumFromInt(id))) {
        _ = try writer.write("        switch (@as(");
        _ = try normalizeName(writer, ty.value_ptr.items[0].type, false);
        _ = try writer.write("EnumID, @enumFromInt(id))) {\n");

        for (ty.value_ptr.items) |def| {
            _ = try writer.write("            .");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(" => {\n                ");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(".deserializedSize(src, cursor, size);\n            },\n");
        }

        _ = try writer.write("        }\n");
        _ = try writer.write("    }\n");

        _ = try writer.write("};\n");
    }

    // Not needed
    _ = mtproto_definitions;
}

pub fn main() !void {
    std.debug.print("Generating from TL schema...\n", .{});
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};
    {
        const layer = try findLayer("schema/api.tl");
        if (layer == null) {
            @panic("Unable to get layer version from schema");
        }

        var definitions = std.ArrayList(constructors.TLConstructor).init(allocator.allocator());
        defer {
            for (definitions.items) |constructor| {
                constructor.deinit();
            }
            definitions.deinit();
        }

        var mtproto_definitions = std.ArrayList(constructors.TLConstructor).init(allocator.allocator());
        defer {
            for (mtproto_definitions.items) |constructor| {
                constructor.deinit();
            }
            mtproto_definitions.deinit();
        }

        try parseFile(allocator.allocator(), &definitions, "schema/api.tl");
        try parseFile(allocator.allocator(), &mtproto_definitions, "schema/mtproto.tl");

        const file = try std.fs.cwd().createFile("../lib/tl/api.zig", .{});
        defer file.close();

        _ = try file.write("//! WARNING!\n//! This file is automatically generated from the TL schema.\n//! Do not modify it manually.\n\n");

        _ = try file.write("\nconst base = @import(\"base.zig\");\nconst std = @import(\"std\");\n");

        try tlGenIdEnum(file.writer().any(), &definitions, &mtproto_definitions);
        try tlGenBaseUnion(allocator.allocator(), file.writer().any(), &definitions, &mtproto_definitions);
        try tlGenerateBoxedUnion(allocator.allocator(), file.writer().any(), &definitions, &mtproto_definitions);

        _ = try file.write("pub const ProtoMessage = base.ProtoMessage(TL);\n");
        _ = try file.write("pub const MessageContainer = base.MessageContainer(TL);\n");
        _ = try file.write("pub const FutureSalt = base.FutureSalt;\n");
        _ = try file.write("pub const FutureSalts = base.FutureSalts;\n");
        _ = try file.write("pub const RPCResult = base.RPCResult(TL);\n");
        _ = try file.write("pub const Vector = base.Vector(TL);\n");
        _ = try file.writer().print("pub const LAYER_VERSION: i32 = {d};\n", .{layer.?});
    }
    _ = allocator.detectLeaks();
}
