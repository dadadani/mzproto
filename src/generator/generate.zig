const std = @import("std");
const parser = @import("../parser/parse.zig");
const constructors = @import("../parser/constructors.zig");
const types = @import("../parser/types.zig");
const TLParameterType = @import("../parser/parameters_type.zig").TLParameterType;

const base = @import("./base.zig");

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
    _ = try writer.write("    RPCResult = 0xF35C6D01,\n");
    _ = try writer.write("    Vector = 0xF35C6D01,\n");
    _ = try writer.write("    GZipPacked = 0x3072CFA1,\n");
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
                return try allocator.dupe(u8, "*const TL");
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

                //result = try concat(allocator, result, "*const ");

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

    _ = try generateSizeFn(allocator, def, writer);
    _ = try generateSerializeFn(allocator, def, writer);
    _ = try generateDeserializeFn(allocator, def, writer);
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
    _ = try writer.write("    BoolTrue: true,\n");
    _ = try writer.write("    BoolFalse: false,\n");
    _ = try writer.write("    MessageContainer: *const MessageContainer,\n");
    _ = try writer.write("    FutureSalts: *const FutureSalts,\n");
    _ = try writer.write("    RPCResult: *const RPCResult,\n");
    _ = try writer.write("    Vector: *const Vector,\n");
    _ = try writer.write("    GZipPacked: unreachable,\n");
    _ = try writer.write("    Int: i32,\n");
    _ = try writer.write("    Long: i64,\n");

    _ = try writer.write("    pub fn serializedSize(self: *const @This()) usize {\n        switch (self.*) {\n");

    for (definitions.items) |def| {
        _ = try writer.write("        .");
        _ = try normalizeName(writer, def, false);
        _ = try writer.write(" => { return self.");
        _ = try normalizeName(writer, def, false);
        _ = try writer.write(".serializedSize(); },\n");
    }
    _ = try writer.write("        }\n");
    _ = try writer.write("    }\n");

    _ = try writer.write("    pub fn serialize(self: *const @This(), dest: []u8) usize {\n        switch (self.*) {\n");

    for (definitions.items) |def| {
        _ = try writer.write("        .");
        _ = try normalizeName(writer, def, false);
        _ = try writer.write(" => { return self.");
        _ = try normalizeName(writer, def, false);
        _ = try writer.write(".serialize(dest); },\n");
    }
    _ = try writer.write("        }\n");
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
    _ = try writer.write("    pub fn deserialize(allocator: std.mem.Allocator, src: []const u8) std.mem.Allocator.Error!struct {usize, *@This()} {\n");

    if (def.params.items.len == 0) {
        _ = try writer.write("        _ = src;\n        return .{ 0, try allocator.create(@This()) };\n    }\n");
        return;
    }
    _ = try writer.write("        var result = try allocator.create(@This());\n        var read: usize = 0;\n");

    for (def.params.items) |param| {
        if (param.type_def) {
            _ = try writer.write("        //IMPLEMENT TYPEDEF\n");
            continue;
        }

        switch (param.type.?) {
            .Flags => {
                _ = try writer.print("        var flag_{s}: usize = 0;\n        read += base.deserializeInt(usize, src[read..], &flag_{s});\n", .{ param.name, param.name });
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
                    param_name = try concat(allocator, param_name, ".?");
                }

                var generic_arg = param.type.?.Normal.type.generic_arg;
                var generic_arg_cnt: usize = 0;
                while (generic_arg) |garg| {
                    if (garg.namespaces.items.len > 0) {
                        return GenerateFieldTypeError.UnsupportedGenericArg;
                    }

                    if (!std.mem.eql(u8, garg.name, "Vector")) {
                        return GenerateFieldTypeError.UnsupportedGenericArg;
                    }

                    _ = try writer.print("        const vector_len_{s}{d} = base.vectorLen(src[read..], &read);\n", .{ param.name, generic_arg_cnt });
                    _ = try writer.print("        const vector_{s}{d} = try allocator.alloc(base.unwrapType(@TypeOf({s})), vector_len_{s}{d});\n        errdefer allocator.free(vector_{s}{d});\n", .{ param.name, generic_arg_cnt, param_name, param.name, generic_arg_cnt, param.name, generic_arg_cnt });

                    _ = try writer.print("        for (0..vector_len_{s}{d}) |vector_{s}{d}_i| {{\n", .{ param.name, generic_arg_cnt, param.name, generic_arg_cnt });

                    allocator.free(param_name);
                    param_name = try std.fmt.allocPrint(allocator, "vector_{s}{d}[vector_{s}{d}_i]", .{ param.name, generic_arg_cnt, param.name, generic_arg_cnt });

                    generic_arg = garg.generic_arg;
                    generic_arg_cnt += 1;
                }

                if (std.mem.eql(u8, param.type.?.Normal.type.name, "int") or std.mem.eql(u8, param.type.?.Normal.type.name, "long") or std.mem.eql(u8, param.type.?.Normal.type.name, "double") or std.mem.eql(u8, param.type.?.Normal.type.name, "int128") or std.mem.eql(u8, param.type.?.Normal.type.name, "int256")) {
                    _ = try writer.print("        read += base.deserializeInt(@TypeOf({s}), src[read..], &{s});\n", .{ param_name, param_name });
                } else if (std.mem.eql(u8, param.type.?.Normal.type.name, "string") or std.mem.eql(u8, param.type.?.Normal.type.name, "bytes")) {
                    _ = try writer.print("        read += try base.deserializeString(allocator, src[read..], &{s});\n", .{param_name});
                } else if (std.mem.eql(u8, param.type.?.Normal.type.name, "Bool")) {
                    _ = try writer.print("        {s} = base.deserializeBool(src[read..], &read);\n", .{param_name});
                } else {
                    _ = try writer.print("        {{ const deserialized = try @TypeOf({s}).deserialize(allocator, src[read..]); read += deserialized[0]; {s} = deserialized[1]; }}\n", .{ param_name, param_name });
                }

                generic_arg = param.type.?.Normal.type.generic_arg;
                while (generic_arg) |garg| {
                    generic_arg_cnt -= 1;

                    _ = try writer.write("        }\n");

                    if (generic_arg_cnt == 0) {
                        _ = try writer.print("        result.{s} = vector_{s}{d};\n", .{ safeParamName(param.name), param.name, generic_arg_cnt });
                    }
                    generic_arg = garg.generic_arg;
                }

                if (param.type.?.Normal.flag) |_| {
                    _ = try writer.write("        }\n");
                }

                _ = try writer.write("\n");
            },
        }
    }

    _ = try writer.write("        return .{read, result};\n    }\n");
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

fn generateSizeFn(allocator: std.mem.Allocator, def: *const constructors.TLConstructor, writer: std.io.AnyWriter) !void {
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

        _ = try writer.write("    pub fn deserialize(allocator: std.mem.Allocator, src: []const u8) std.mem.Allocator.Error!struct {usize, I");
        _ = try normalizeName(writer, ty.value_ptr.items[0].type, false);
        _ = try writer.write("} {\n");

        _ = try writer.write("        const id = std.mem.readInt(u32, src[0..4], std.builtin.Endian.little);\n");
        //        switch (@as(ChatEnumID, @enumFromInt(id))) {
        _ = try writer.write("        switch (@as(");
        _ = try normalizeName(writer, ty.value_ptr.items[0].type, false);
        _ = try writer.write("EnumID, @enumFromInt(id))) {\n");

        for (ty.value_ptr.items) |def| {
            _ = try writer.write("            .");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(" => {\n                const deserialized = try ");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(".deserialize(allocator, src[4..]);\n");
            _ = try writer.write("                return .{ deserialized[0] + 4, .{ .");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(" = deserialized[1] } };\n            },\n");
        }

        _ = try writer.write("        }\n");
        _ = try writer.write("    }\n");

        _ = try writer.write("};\n");
    }

    // Not needed
    _ = mtproto_definitions;
}

pub fn main() !void {
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

        const file = try std.fs.cwd().createFile("api.zig", .{});
        defer file.close();

        _ = try file.write("//! WARNING!\n//! This file is automatically generated from the TL schema.\n//! Do not modify it manually.\n\n");

        _ = try file.write("\nconst base = @import(\"base.zig\");\nconst std = @import(\"std\");\n");

        try tlGenIdEnum(file.writer().any(), &definitions, &mtproto_definitions);
        try tlGenBaseUnion(allocator.allocator(), file.writer().any(), &definitions, &mtproto_definitions);
        try tlGenerateBoxedUnion(allocator.allocator(), file.writer().any(), &definitions, &mtproto_definitions);

        _ = try file.write("pub const ProtoMessage = struct {\n    msg_id: u64,\n    seqno: i32,\n    body: TL,\n\n    pub fn serializedSize(self: *const @This()) usize {\n        return 16 + self.body.serializedSize();\n    }\n\n    pub fn serialize(self: *const @This(), dest: []u8) usize {\n        var written: usize = 0;\n        written += base.serializeLong(self.msg_id, dest[written..]);\n        written += base.serializeInt(self.seqno, dest[written..]);\n\n        const tlWritten = self.body.serialize(dest[written + 4 ..]);\n\n        written += base.serializeInt(tlWritten, dest[written..]);\n        return written + tlWritten;\n    }\n\n    pub fn deserialize(allocator: std.mem.Allocator, src: []const u8) std.mem.Allocator.Error!struct { usize, *@This() } {\n        var result = try allocator.create(@This());\n        var read: usize = 0;\n        read += base.deserializeLong(src[read..], &result.msg_id);\n        read += base.deserializeInt(src[read..], &result.seqno);\n\n        var bodyLength: i32 = undefined;\n        read += base.deserializeInt(src[read..], &bodyLength);\n\n        result.body = try TL.deserialize(allocator, src[read .. read + bodyLength])[1];\n        read += bodyLength;\n\n        return .{ read, result };\n    }\n};");
        _ = try file.write("pub const FutureSalts = struct {\n    req_msg_id: u64,\n    now: u32,\n    salts: []const base.FutureSalt,\n\n    pub fn serializedSize(self: *const @This()) usize {\n        return 20 + (self.salts.len * 16);\n    }\n\n    pub fn serialize(self: *const @This(), dest: []u8) usize {\n        var written: usize = 0;\n        written += base.serializeInt(@as(u32, 0xae500895), dest[written..]);\n        written += base.serializeInt(self.req_msg_id, dest[written..]);\n        written += base.serializeInt(self.now, dest[written..]);\n        written += base.serializeInt(self.salts.len, dest[written..]);\n        for (self.salts) |salt| {\n            written += base.serializeInt(salt.valid_since, dest[written..]);\n            written += base.serializeInt(salt.valid_until, dest[written..]);\n            written += base.serializeInt(salt.salt, dest[written..]);\n        }\n        return written;\n    }\n\n    pub fn deserialize(allocator: std.mem.Allocator, src: []const u8) std.mem.Allocator.Error!struct { usize, *@This() } {\n        var result = try allocator.create(@This());\n        var read: usize = 0;\n        read += base.deserializeInt(u64, src[read..], &result.req_msg_id);\n        read += base.deserializeInt(u32, src[read..], &result.now);\n\n        const len = base.deserializeInt(u32, src[read..], &read);\n        result.salts = try allocator.alloc(base.FutureSalt, len);\n\n        for (0..len) |i| {\n            read += base.deserializeInt(u32, src[read..], &result.salts[i].valid_since);\n            read += base.deserializeInt(u32, src[read..], &result.salts[i].valid_until);\n            read += base.deserializeInt(u64, src[read..], &result.salts[i].salt);\n        }\n\n        return .{ read, result };\n    }\n};\n");
    }
    _ = allocator.detectLeaks();
}
