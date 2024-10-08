const std = @import("std");
const parser = @import("../parser/parse.zig");
const constructors = @import("../parser/constructors.zig");
const types = @import("../parser/types.zig");
const TLParameterType = @import("../parser/parameters_type.zig").TLParameterType;

const base = @import("./base.zig");

//fn readTypes(constructor: *const constructors.TLConstructor) void {

//}

const TLConstructorIDs = enum(u32) {
    A = 32,
    B = 36,
    C = 29,
    D = 1,
};

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

    _ = try writer.write("};\n");
}

/// Concatenates two slices of bytes by reallocating the first slice.
fn concat(allocator: std.mem.Allocator, a: []u8, b: []const u8) ![]u8 {
    var ab = try allocator.realloc(a, a.len + b.len);
    @memcpy(ab[a.len..], b);
    return ab;
}

const GenerateFieldTypeError = error{ UnsupportedIntBits, UnsupportedGenericArg };

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
            } else if (std.mem.eql(u8, field.Normal.type.name, "Bool") or std.mem.eql(u8, field.Normal.type.name, "true")) {
                result = try concat(allocator, result, "bool");
            } else {
                const normalized = try normalizeNameAlloc(allocator, field.Normal.type, mtproto);
                defer allocator.free(normalized);

                result = try concat(allocator, result, normalized);
            }

            return result;
        },
    }
}

fn generateDefinition(writer: std.io.AnyWriter, def: *const constructors.TLConstructor, mtproto: bool) !void {
    _ = try writer.write("    ");
    _ = try normalizeName(writer, def, mtproto);
    _ = try writer.write(": struct {\n");
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

        _ = try writer.print("        {s}: {s},\n", .{ name, typeName });
    }
    _ = try writer.write("    },\n");
}

fn tlGenBaseUnion(writer: std.io.AnyWriter, definitions: *const std.ArrayList(constructors.TLConstructor), mtproto_definitions: *const std.ArrayList(constructors.TLConstructor)) !void {
    _ = try writer.write("const TL = union(TLID) {\n");

    for (mtproto_definitions.items) |def| {
        try generateDefinition(writer, &def, true);
    }

    for (definitions.items) |def| {
        try generateDefinition(writer, &def, false);
    }

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

    while (iterator.next()) |asd| {
        _ = try writer.write("const ");
        _ = try normalizeName(writer, asd.value_ptr.items[0].type, false);
        _ = try writer.write(" = union(TLID) {\n");
        for (asd.value_ptr.items) |def| {
            _ = try writer.write("    ");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(": TL.");
            _ = try normalizeName(writer, def, false);
            _ = try writer.write(",\n");
        }
        _ = try writer.write("};\n");
    }

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

        try tlGenIdEnum(file.writer().any(), &definitions, &mtproto_definitions);
        try tlGenBaseUnion(file.writer().any(), &definitions, &mtproto_definitions);
        try tlGenerateBoxedUnion(allocator.allocator(), file.writer().any(), &definitions, &mtproto_definitions);
    }
    _ = allocator.detectLeaks();
}
