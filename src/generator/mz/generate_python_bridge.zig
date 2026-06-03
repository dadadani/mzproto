const std = @import("std");
const Parser = @import("./parser.zig");
const utils = @import("common.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len != 3) std.process.fatal("wrong number of arguments", .{});

    const schema_src = blk: {
        const schema_file = try std.Io.Dir.cwd().openFile(io, args[1], .{ .mode = .read_only });
        defer schema_file.close(io);

        const stat = try schema_file.stat(io);
        var reader = schema_file.reader(io, &.{});
        break :blk try reader.interface.readAlloc(allocator, @intCast(stat.size));
    };

    var schema = try Parser.Schema.parseOwned(allocator, schema_src);
    defer schema.deinit();

    const out = try std.Io.Dir.cwd().createFile(io, args[2], .{ .truncate = true });
    defer out.close(io);

    var buffer: [4096]u8 = undefined;
    var writer = out.writer(io, &buffer);

    try emit(allocator, &writer.interface, &schema);
    try writer.flush();
}

fn emitDoc(writer: *std.Io.Writer, doc: ?[]u8) !void {
    if (doc) |value| {
        var iterator = std.mem.splitScalar(u8, value, '\n');
        while (iterator.next()) |line| {
            if (line.len == 0) {
                try writer.writeAll("///\n");
            } else {
                try writer.print("/// {s}\n", .{line});
            }
        }
    }
}

fn fieldNameOwned(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    return utils.snakeCaseOwned(allocator, name);
}

fn bridgeTypeOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr, comptime is_const: bool) ![]u8 {
    return switch (type_expr.*) {
        .optional => |child| blk: {
            const inner = try bridgeTypeOwned(allocator, schema, child, is_const);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "?{s}", .{inner});
        },
        .reference => |child| switch (child.*) {
            .named => |name| switch (utils.classifyNamed(schema, name)) {
                .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "{s}{s}", .{ if (is_const) "ConstRef" else "Ref", name }),
                else => bridgeTypeOwned(allocator, schema, child, is_const),
            },
            else => bridgeTypeOwned(allocator, schema, child, is_const),
        },
        .list => |child| blk: {
            const inner = try bridgeTypeOwned(allocator, schema, child, is_const);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "{s}List({s})", .{ if (is_const) "Const" else "", inner });
        },
        .function => allocator.dupe(u8, "void"),
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_bool => allocator.dupe(u8, "bool"),
            .builtin_u32 => allocator.dupe(u8, "u32"),
            .builtin_u64, .builtin_time => allocator.dupe(u8, "u64"),
            .builtin_i32 => allocator.dupe(u8, "i32"),
            .builtin_i64 => allocator.dupe(u8, "i64"),
            .builtin_string => allocator.dupe(u8, if (is_const) "ConstString" else "String"),
            .builtin_bytes => allocator.dupe(u8, if (is_const) "ConstBytes" else "Bytes"),
            .enum_decl, .struct_decl, .union_decl, .opaque_decl => allocator.dupe(u8, name),
            else => allocator.dupe(u8, name),
        },
    };
}

fn setterTypeOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) ![]u8 {
    return bridgeTypeOwned(allocator, schema, type_expr, false);
}

fn typeUsesWrapper(schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) bool {
    return switch (type_expr.*) {
        .optional => |child| typeUsesWrapper(schema, child),
        .reference, .list => true,
        .function => false,
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_string, .builtin_bytes, .struct_decl, .union_decl, .opaque_decl => true,
            else => false,
        },
    };
}

fn getterInnerTypeOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr, comptime is_const: bool) ![]u8 {
    if (type_expr.* == .optional) return bridgeTypeOwned(allocator, schema, type_expr.optional, is_const);
    return bridgeTypeOwned(allocator, schema, type_expr, is_const);
}

fn emitGetterBody(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr, field_name: []const u8, comptime is_const: bool) !void {
    const inner_ty = try getterInnerTypeOwned(allocator, schema, type_expr, is_const);
    defer allocator.free(inner_ty);

    if (type_expr.* == .optional) {
        if (typeUsesWrapper(schema, type_expr.optional)) {
            try writer.print("        return optionalFieldWrapper({s}, self.source, \"{s}\");\n", .{ inner_ty, field_name });
        } else {
            try writer.print("        return optionalFieldValue({s}, self.source, \"{s}\");\n", .{ inner_ty, field_name });
        }
        return;
    }

    if (typeUsesWrapper(schema, type_expr)) {
        try writer.print("        return fieldWrapper({s}, self.source, \"{s}\");\n", .{ inner_ty, field_name });
    } else {
        try writer.print("        return fieldValue({s}, self.source, \"{s}\");\n", .{ inner_ty, field_name });
    }
}

fn emitSetterBody(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr, field_name: []const u8) !void {
    const inner_ty = try getterInnerTypeOwned(allocator, schema, type_expr, false);
    defer allocator.free(inner_ty);

    if (type_expr.* == .optional) {
        try writer.print("        _ = allocator;\n        try setOptionalFieldValue({s}, self.source, \"{s}\", value);\n", .{ inner_ty, field_name });
    } else {
        try writer.print("        _ = allocator;\n        try setFieldValue({s}, self.source, \"{s}\", value);\n", .{ inner_ty, field_name });
    }
}

fn emitCommonOwnedWrapperMethods(writer: *std.Io.Writer, name: []const u8, comptime owned: bool) !void {
    try writer.writeAll(
        \\    source: ValueSource,
    );
    if (owned) try writer.writeAll("    owned: bool,\n");
    try writer.writeAll("\n");
    if (owned) {
        try writer.print(
            \\    pub fn fromOwned(object: ?*python.PyObject) @This() {{ return .{{ .source = .{{ .direct = object }}, .owned = true }}; }}
            \\    pub fn fromNewRef(object: ?*python.PyObject) @This() {{ return .fromOwned(pyNewRef(object)); }}
            \\    pub fn fromBorrowedObject(object: ?*python.PyObject) @This() {{ return .{{ .source = .{{ .direct = object }}, .owned = false }}; }}
            \\    pub fn fromBorrowedSource(source: ValueSource) @This() {{ return .{{ .source = source, .owned = false }}; }}
            \\    pub fn newRef(self: @This()) BridgeError!?*python.PyObject {{ return sourceGetOwned(self.source); }}
            \\    pub fn resolveOwned(self: *@This()) BridgeError!?*python.PyObject {{
            \\        if (self.owned) {{
            \\            const object = switch (self.source) {{
            \\                .direct => |object| object,
            \\                .attr => try sourceGetOwned(self.source),
            \\            }};
            \\            self.* = .fromBorrowedObject(null);
            \\            return object;
            \\        }}
            \\        return try self.newRef();
            \\    }}
            \\
        , .{});
        _ = name;
    } else {
        try writer.writeAll(
            \\    pub fn fromOwned(object: ?*python.PyObject) @This() { return .{ .source = .{ .direct = object } }; }
            \\    pub fn fromBorrowedObject(object: ?*python.PyObject) @This() { return .{ .source = .{ .direct = object } }; }
            \\    pub fn fromBorrowedSource(source: ValueSource) @This() { return .{ .source = source }; }
            \\    pub fn newRef(self: @This()) BridgeError!?*python.PyObject { return sourceGetOwned(self.source); }
            \\    pub fn resolveOwned(self: @This()) BridgeError!?*python.PyObject { return self.newRef(); }
            \\
        );
        _ = name;
    }
}

fn emitGetters(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, fields: []const Parser.Field, comptime is_const: bool) !void {
    for (fields) |field| {
        if (field.type_expr.* == .function) continue;
        const suffix = try utils.pascalCaseOwned(allocator, field.name);
        defer allocator.free(suffix);
        const field_name = try fieldNameOwned(allocator, field.name);
        defer allocator.free(field_name);
        const return_ty = try bridgeTypeOwned(allocator, schema, field.type_expr, is_const);
        defer allocator.free(return_ty);

        try writer.print("    pub inline fn get{s}(self: *const @This()) BridgeError!{s} {{\n", .{ suffix, return_ty });
        try emitGetterBody(writer, allocator, schema, field.type_expr, field_name, is_const);
        try writer.writeAll("    }\n\n");
    }
}

fn emitUnionGetters(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, fields: []const Parser.Field, comptime is_const: bool) !void {
    for (fields) |field| {
        if (field.type_expr.* == .function) continue;
        const suffix = try utils.pascalCaseOwned(allocator, field.name);
        defer allocator.free(suffix);
        const field_name = try fieldNameOwned(allocator, field.name);
        defer allocator.free(field_name);
        const return_ty = try bridgeTypeOwned(allocator, schema, field.type_expr, is_const);
        defer allocator.free(return_ty);

        try writer.print("    pub inline fn get{s}(self: *const @This()) BridgeError!{s} {{\n", .{ suffix, return_ty });
        if (field.type_expr.* == .named and utils.classifyNamed(schema, field.type_expr.named) == .struct_decl) {
            try writer.print("        if (sourceIsInstance(self.source, \"{s}\")) return {s}.fromBorrowedSource(self.source);\n", .{ field.type_expr.named, return_ty });
        }
        try emitGetterBody(writer, allocator, schema, field.type_expr, field_name, is_const);
        try writer.writeAll("    }\n\n");
    }
}

fn emitSetters(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, fields: []const Parser.Field, union_fields: ?[]const Parser.Field) !void {
    for (fields) |field| {
        if (field.type_expr.* == .function) continue;
        const suffix = try utils.pascalCaseOwned(allocator, field.name);
        defer allocator.free(suffix);
        const field_name = try fieldNameOwned(allocator, field.name);
        defer allocator.free(field_name);
        const input_ty = try setterTypeOwned(allocator, schema, field.type_expr);
        defer allocator.free(input_ty);

        try writer.print("    pub inline fn set{s}(self: @This(), allocator: std.mem.Allocator, value: {s}) BridgeError!void {{\n", .{ suffix, input_ty });
        try emitSetterBody(writer, allocator, schema, field.type_expr, field_name);
        if (union_fields) |all_fields| {
            for (all_fields) |other| {
                if (std.mem.eql(u8, other.name, field.name)) continue;
                const other_name = try fieldNameOwned(allocator, other.name);
                defer allocator.free(other_name);
                try writer.print("        deleteField(self.source, \"{s}\");\n", .{other_name});
            }
        }
        try writer.writeAll("    }\n\n");
    }
}

fn emitObjectWrapper(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, name: []const u8, fields: []const Parser.Field, comptime is_opaque: bool, doc: ?[]u8) !void {
    try emitDoc(writer, doc);
    try writer.print("pub const {s} = struct {{\n", .{name});
    try emitCommonOwnedWrapperMethods(writer, name, true);
    try writer.print(
        \\    pub const Plain = @This();
        \\    pub const Ref = Ref{s};
        \\    pub const ConstRef = ConstRef{s};
        \\
        \\    pub inline fn init(allocator: std.mem.Allocator) BridgeError!{s} {{
        \\        _ = allocator;
        \\        return .fromOwned(try createPublicObjectOwned("{s}"));
        \\    }}
        \\
    , .{ name, name, name, name });
    if (is_opaque) {
        try writer.writeAll("    pub inline fn deinit(self: *@This()) void {\n        releaseSource(self.source, self.owned);\n        self.* = .fromBorrowedObject(null);\n    }\n\n");
        try writer.writeAll("    pub inline fn getPtr(self: *const @This()) BridgeError!*anyopaque {\n        return try fieldPtr(self.source, \"ptr\");\n    }\n\n");
    } else {
        try writer.writeAll("    pub inline fn deinit(self: *@This(), allocator: std.mem.Allocator) void {\n        _ = allocator;\n        releaseSource(self.source, self.owned);\n        self.* = .fromBorrowedObject(null);\n    }\n\n");
        try emitGetters(writer, allocator, schema, fields, false);
    }
    try writer.print("    pub inline fn toRef(self: *@This()) Ref{s} {{ return .{{ .source = self.source, .owned = false }}; }}\n", .{name});
    try writer.print("    pub inline fn toConst(self: *const @This()) ConstRef{s} {{ return .{{ .source = self.source }}; }}\n", .{name});
    try writer.writeAll("};\n\n");

    try writer.print("pub const Ref{s} = struct {{\n", .{name});
    try emitCommonOwnedWrapperMethods(writer, name, true);
    try writer.print(
        \\    pub const Plain = {s};
        \\    pub const Ref = @This();
        \\    pub const ConstRef = ConstRef{s};
        \\
        \\    pub inline fn init(allocator: std.mem.Allocator) BridgeError!Ref{s} {{
        \\        var object = try {s}.init(allocator);
        \\        return .fromOwned(try object.resolveOwned());
        \\    }}
        \\
        \\    pub inline fn deinit(self: @This(), allocator: std.mem.Allocator) void {{
        \\        _ = allocator;
        \\        releaseSource(self.source, self.owned);
        \\    }}
        \\
    , .{ name, name, name, name });
    if (is_opaque) {
        try writer.writeAll("    pub inline fn getPtr(self: @This()) BridgeError!*anyopaque {\n        return try fieldPtr(self.source, \"ptr\");\n    }\n\n");
        try writer.writeAll("    pub inline fn setPtr(self: @This(), ptr: *anyopaque) BridgeError!void {\n        try setFieldPtr(self.source, \"ptr\", ptr);\n    }\n\n");
    } else {
        try emitGetters(writer, allocator, schema, fields, false);
        try emitSetters(writer, allocator, schema, fields, if (is_opaque) null else null);
    }
    try writer.print("    pub inline fn toConst(self: @This()) ConstRef{s} {{ return .{{ .source = self.source }}; }}\n", .{name});
    try writer.writeAll("};\n\n");

    try writer.print("pub const ConstRef{s} = struct {{\n", .{name});
    try emitCommonOwnedWrapperMethods(writer, name, false);
    try writer.print(
        \\    pub const Plain = {s};
        \\    pub const Ref = Ref{s};
        \\    pub const ConstRef = @This();
        \\
    , .{ name, name });
    if (is_opaque) {
        try writer.writeAll("    pub inline fn getPtr(self: @This()) BridgeError!*anyopaque {\n        return try fieldPtr(self.source, \"ptr\");\n    }\n\n");
    } else {
        try emitGetters(writer, allocator, schema, fields, true);
    }
    try writer.writeAll("};\n\n");
}

fn emitUnionWrapper(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, decl: Parser.UnionDecl) !void {
    const name = decl.name;
    try emitDoc(writer, decl.doc);
    try writer.print("pub const {s} = struct {{\n", .{name});
    try emitCommonOwnedWrapperMethods(writer, name, true);
    try writer.print(
        \\    pub const Plain = @This();
        \\    pub const Ref = Ref{s};
        \\    pub const ConstRef = ConstRef{s};
        \\
        \\    pub inline fn init(allocator: std.mem.Allocator) BridgeError!{s} {{
        \\        _ = allocator;
        \\        return .fromOwned(try createDictOwned());
        \\    }}
        \\    pub inline fn deinit(self: *@This(), allocator: std.mem.Allocator) void {{
        \\        _ = allocator;
        \\        releaseSource(self.source, self.owned);
        \\        self.* = .fromBorrowedObject(null);
        \\    }}
        \\
    , .{ name, name, name });
    try emitUnionGetters(writer, allocator, schema, decl.fields.items, false);
    try writer.print("    pub inline fn toRef(self: *@This()) Ref{s} {{ return .{{ .source = self.source, .owned = false }}; }}\n", .{name});
    try writer.print("    pub inline fn toConst(self: *const @This()) ConstRef{s} {{ return .{{ .source = self.source }}; }}\n", .{name});
    try writer.writeAll("};\n\n");

    try writer.print("pub const Ref{s} = struct {{\n", .{name});
    try emitCommonOwnedWrapperMethods(writer, name, true);
    try writer.print(
        \\    pub const Plain = {s};
        \\    pub const Ref = @This();
        \\    pub const ConstRef = ConstRef{s};
        \\
        \\    pub inline fn init(allocator: std.mem.Allocator) BridgeError!Ref{s} {{
        \\        var object = try {s}.init(allocator);
        \\        return .fromOwned(try object.resolveOwned());
        \\    }}
        \\    pub inline fn deinit(self: @This(), allocator: std.mem.Allocator) void {{
        \\        _ = allocator;
        \\        releaseSource(self.source, self.owned);
        \\    }}
        \\
    , .{ name, name, name, name });
    try emitUnionGetters(writer, allocator, schema, decl.fields.items, false);
    try emitSetters(writer, allocator, schema, decl.fields.items, decl.fields.items);
    try writer.print("    pub inline fn toConst(self: @This()) ConstRef{s} {{ return .{{ .source = self.source }}; }}\n", .{name});
    try writer.writeAll("};\n\n");

    try writer.print("pub const ConstRef{s} = struct {{\n", .{name});
    try emitCommonOwnedWrapperMethods(writer, name, false);
    try writer.print(
        \\    pub const Plain = {s};
        \\    pub const Ref = Ref{s};
        \\    pub const ConstRef = @This();
        \\
    , .{ name, name });
    try emitUnionGetters(writer, allocator, schema, decl.fields.items, true);
    try writer.writeAll("};\n\n");
}

fn emitEnumDecl(writer: *std.Io.Writer, allocator: std.mem.Allocator, decl: Parser.EnumDecl) !void {
    try emitDoc(writer, decl.doc);
    try writer.print("pub const {s} = enum(u32) {{\n", .{decl.name});
    for (decl.items.items) |item| {
        try emitDoc(writer, item.doc);
        const name = try utils.snakeCaseOwned(allocator, item.name);
        defer allocator.free(name);
        try writer.print("    {s} = {d},\n", .{ name, item.value });
    }
    try writer.writeAll("\n    pub fn init() @This() {\n");
    if (decl.items.items.len > 0) {
        const first = try utils.snakeCaseOwned(allocator, decl.items.items[0].name);
        defer allocator.free(first);
        try writer.print("        return .{s};\n", .{first});
    } else {
        try writer.writeAll("        return @enumFromInt(0);\n");
    }
    try writer.writeAll("    }\n};\n\n");
}

fn emitEnumToPyOwned(writer: *std.Io.Writer, schema: *const Parser.Schema) !void {
    try writer.writeAll("fn enumToPyOwned(comptime T: type, value: T) BridgeError!?*python.PyObject {\n");
    for (schema.declarations.items) |decl| {
        switch (decl) {
            .enum_decl => |enum_decl| {
                try writer.print("    if (T == {s}) return createPublicEnumOwned(\"{s}\", @intFromEnum(value));\n", .{ enum_decl.name, enum_decl.name });
            },
            else => {},
        }
    }
    try writer.writeAll("    return pyObjectFromU64(@intFromEnum(value));\n}\n\n");
}

pub fn emit(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema) !void {
    try writer.writeAll(
        \\///! mzproto - bridge between Python objects and runtime Zig code
    \\///!
    \\///! Automatically generated. do not edit
    \\
    \\
    \\const std = @import("std");
    \\const python = @import("python");
    \\
    \\
    \\pub const BridgeError = std.mem.Allocator.Error || error{PythonError};
    \\
    \\
    \\const PreferredEncoding = enum {
    \\    utf8,
    \\    utf16,
    \\};
    \\
    \\
    \\pub const STRINGS_ARE_NO_COPY = false;
    \\pub const BYTES_ARE_NO_COPY = false;
    \\pub const PREFERRED_STRING_ENCODING: PreferredEncoding = .utf8;
    \\pub const OBJECTS_ALWAYS_REFERENCED = true;
    \\
    \\
    \\pub const MzError = struct {
    \\    code: u32,
    \\    message: []const u8,
    \\    owned: bool = false,
    \\
    \\
    \\    pub fn deinit(self: *MzError, allocator: std.mem.Allocator) void {
    \\        if (self.owned and self.message.len > 0) allocator.free(@constCast(self.message));
    \\        self.* = undefined;
    \\    }
    \\};
    \\
    \\
    \\fn hasDeinit(comptime T: type) bool {
    \\    return switch (@typeInfo(T)) {
    \\        .@"struct", .@"union", .@"enum", .@"opaque" => @hasDecl(T, "deinit"),
    \\        else => false,
    \\    };
    \\}
    \\
    \\
    \\pub fn Result(comptime T: type) type {
    \\    return union(enum) {
    \\        ok: T,
    \\        err: MzError,
    \\
    \\
    \\        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    \\            switch (self.*) {
    \\                .err => |*err| err.deinit(allocator),
    \\                .ok => |*ok| if (hasDeinit(T)) ok.deinit(allocator),
    \\            }
    \\        }
    \\    };
    \\}
    \\
    \\
    \\pub const ValueSource = union(enum) {
    \\    direct: ?*python.PyObject,
    \\    attr: struct {
    \\        parent: ?*python.PyObject,
    \\        name: [:0]const u8,
    \\    },
    \\};
    \\
    \\var public_class_cache: ?*python.PyObject = null;
    \\
    \\
    \\fn withGil(comptime T: type, func: fn () T) T {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    return func();
    \\}
    \\
    \\
    \\fn pyClearError() void {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    python.PyErr_Clear();
    \\}
    \\
    \\
    \\fn setTypeError(message: [*:0]const u8) void {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    python.PyErr_SetString(python.PyExc_TypeError, message);
    \\}
    \\
    \\
    \\fn pyNewRef(object: ?*python.PyObject) ?*python.PyObject {
    \\    if (object == null) return null;
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    return @ptrCast(python.Py_NewRef(@ptrCast(object)));
    \\}
    \\
    \\
    \\fn pyDecref(object: ?*python.PyObject) void {
    \\    if (object == null) return;
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    python.Py_DecRef(@ptrCast(object));
    \\}
    \\
    \\
    \\pub fn getPublicClassOwned(class_name: [:0]const u8) ?*python.PyObject {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\
    \\    const cache = public_class_cache orelse blk: {
    \\        const new_cache: ?*python.PyObject = @ptrCast(python.PyDict_New());
    \\        if (new_cache == null) return null;
    \\        public_class_cache = new_cache;
    \\        break :blk new_cache;
    \\    };
    \\
    \\    const cached = python.PyDict_GetItemString(@ptrCast(cache), class_name.ptr);
    \\    if (cached != null) return @ptrCast(python.Py_NewRef(cached));
    \\
    \\    const module = python.PyImport_ImportModule("mzproto");
    \\    if (module == null) return null;
    \\    defer python.Py_DecRef(module);
    \\
    \\    const class = python.PyObject_GetAttrString(module, class_name.ptr);
    \\    if (class == null) return null;
    \\    if (python.PyDict_SetItemString(@ptrCast(cache), class_name.ptr, class) != 0) {
    \\        python.Py_DecRef(class);
    \\        return null;
    \\    }
    \\    return @ptrCast(class);
    \\}
    \\
    \\
    \\fn pyIsNone(object: ?*python.PyObject) bool {
    \\    if (object == null) return true;
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    return python.Py_IsNone(@ptrCast(object)) != 0;
    \\}
    \\
    \\
    \\fn pyNoneOwned() ?*python.PyObject {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    return @ptrCast(python.Py_NewRef(python.Py_None));
    \\}
    \\
    \\
    \\fn objectGetOptionalOwned(object: ?*python.PyObject, name: [:0]const u8) BridgeError!?*python.PyObject {
    \\    if (object == null) return null;
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\
    \\
    \\    const attr = python.PyObject_GetAttrString(@ptrCast(object), name.ptr);
    \\    if (attr != null) return @ptrCast(attr);
    \\    python.PyErr_Clear();
    \\    return null;
    \\}
    \\
    \\
    \\fn objectGetRequiredOwned(object: ?*python.PyObject, name: [:0]const u8) BridgeError!?*python.PyObject {
    \\    return (try objectGetOptionalOwned(object, name)) orelse {
    \\        setTypeError("expected object with required mzproto field");
    \\        return error.PythonError;
    \\    };
    \\}
    \\
    \\
    \\fn objectSetOwned(object: ?*python.PyObject, name: [:0]const u8, value: ?*python.PyObject) BridgeError!void {
    \\    if (object == null or value == null) return error.PythonError;
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\
    \\
    \\    if (python.PyObject_SetAttrString(@ptrCast(object), name.ptr, @ptrCast(value)) == 0) return;
    \\    return error.PythonError;
    \\}
    \\
    \\
    \\fn objectDelete(object: ?*python.PyObject, name: [:0]const u8) void {
    \\    if (object == null) return;
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\
    \\
    \\    if (python.PyObject_DelAttrString(@ptrCast(object), name.ptr) == 0) return;
    \\    python.PyErr_Clear();
    \\    _ = python.PyMapping_DelItemString(@ptrCast(object), name.ptr);
    \\    python.PyErr_Clear();
    \\}
    \\
    \\
    \\pub fn sourceGetOwned(source: ValueSource) BridgeError!?*python.PyObject {
    \\    return switch (source) {
    \\        .direct => |object| pyNewRef(object),
    \\        .attr => |field| objectGetRequiredOwned(field.parent, field.name),
    \\    };
    \\}
    \\
    \\
    \\pub fn sourceGetOptionalOwned(source: ValueSource) BridgeError!?*python.PyObject {
    \\    return switch (source) {
    \\        .direct => |object| pyNewRef(object),
    \\        .attr => |field| objectGetOptionalOwned(field.parent, field.name),
    \\    };
    \\}
    \\
    \\
    \\pub fn sourceGetRequiredOwned(source: ValueSource) BridgeError!?*python.PyObject {
    \\    return (try sourceGetOptionalOwned(source)) orelse error.PythonError;
    \\}
    \\
    \\
    \\pub fn sourceAttr(source: ValueSource, name: [:0]const u8) ValueSource {
    \\    return switch (source) {
    \\        .direct => |object| .{ .attr = .{ .parent = object, .name = name } },
    \\        .attr => .{ .direct = null },
    \\    };
    \\}
    \\
    \\
    \\pub fn sourceChildOwned(source: ValueSource, name: [:0]const u8) BridgeError!?*python.PyObject {
    \\    const owner = try sourceGetOwned(source);
    \\    defer pyDecref(owner);
    \\    return try objectGetOptionalOwned(owner, name);
    \\}
    \\
    \\
    \\fn sourceIsInstance(source: ValueSource, class_name: [:0]const u8) bool {
    \\    const object = sourceGetOptionalOwned(source) catch return false;
    \\    defer pyDecref(object);
    \\    if (object == null) return false;
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    const class = getPublicClassOwned(class_name);
    \\    if (class == null) {
    \\        python.PyErr_Clear();
    \\        return false;
    \\    }
    \\    defer python.Py_DecRef(class);
    \\
    \\
    \\    const result = python.PyObject_IsInstance(@ptrCast(object), class);
    \\    if (result < 0) {
    \\        python.PyErr_Clear();
    \\        return false;
    \\    }
    \\    return result != 0;
    \\}
    \\
    \\
    \\pub fn sourceLength(source: ValueSource) BridgeError!usize {
    \\    const object = try sourceGetRequiredOwned(source);
    \\    defer pyDecref(object);
    \\    if (object == null) return error.PythonError;
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    const size = python.PyObject_Length(@ptrCast(object));
    \\    if (size < 0) {
    \\        return error.PythonError;
    \\    }
    \\    return @intCast(size);
    \\}
    \\
    \\
    \\fn sourceSequenceItemOwned(source: ValueSource, index: usize) BridgeError!?*python.PyObject {
    \\    const object = try sourceGetRequiredOwned(source);
    \\    defer pyDecref(object);
    \\    if (object == null) return error.PythonError;
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    const item = python.PySequence_GetItem(@ptrCast(object), @intCast(index));
    \\    if (item == null) return error.PythonError;
    \\    return @ptrCast(item);
    \\}
    \\
    \\
    \\pub fn createDictOwned() BridgeError!?*python.PyObject {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\
    \\
    \\    const object = python.PyDict_New();
    \\    if (object == null) return error.PythonError;
    \\    return @ptrCast(object);
    \\}
    \\
    \\
    \\fn createPublicObjectOwned(class_name: [:0]const u8) BridgeError!?*python.PyObject {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\
    \\
    \\    const class = getPublicClassOwned(class_name);
    \\    if (class == null) return error.PythonError;
    \\    defer python.Py_DecRef(class);
    \\
    \\
    \\    const new_fn = python.PyObject_GetAttrString(class, "__new__");
    \\    if (new_fn == null) return error.PythonError;
    \\    defer python.Py_DecRef(new_fn);
    \\
    \\
    \\    const args = python.PyTuple_New(1);
    \\    if (args == null) return error.PythonError;
    \\    defer python.Py_DecRef(args);
    \\
    \\
    \\    if (python.PyTuple_SetItem(args, 0, python.Py_NewRef(class)) != 0) return error.PythonError;
    \\    const object = python.PyObject_CallObject(new_fn, args);
    \\    if (object == null) return error.PythonError;
    \\    return @ptrCast(object);
    \\}
    \\
    \\
    \\fn createPublicEnumOwned(class_name: [:0]const u8, value: u64) BridgeError!?*python.PyObject {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\
    \\
    \\    const class = getPublicClassOwned(class_name);
    \\    if (class == null) return error.PythonError;
    \\    defer python.Py_DecRef(class);
    \\
    \\
    \\    const args = python.PyTuple_New(1);
    \\    if (args == null) return error.PythonError;
    \\    defer python.Py_DecRef(args);
    \\
    \\
    \\    const integer = python.PyLong_FromUnsignedLongLong(@intCast(value));
    \\    if (integer == null) return error.PythonError;
    \\    if (python.PyTuple_SetItem(args, 0, integer) != 0) return error.PythonError;
    \\    const object = python.PyObject_CallObject(class, args);
    \\    if (object == null) return error.PythonError;
    \\    return @ptrCast(object);
    \\}
    \\
    \\
    \\fn createListOwned(len: usize) BridgeError!?*python.PyObject {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\
    \\
    \\    const object = python.PyList_New(@intCast(len));
    \\    if (object == null) return error.PythonError;
    \\    return @ptrCast(object);
    \\}
    \\
    \\
    \\fn listSetOwned(list_object: ?*python.PyObject, index: usize, value: ?*python.PyObject) BridgeError!void {
    \\    if (list_object == null or value == null) return error.PythonError;
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\
    \\
    \\    if (python.PyList_SetItem(@ptrCast(list_object), @intCast(index), @ptrCast(value)) != 0) {
    \\        python.Py_DecRef(@ptrCast(value));
    \\        return error.PythonError;
    \\    }
    \\}
    \\
    \\
    \\fn utf8CopyFromObject(allocator: std.mem.Allocator, object: ?*python.PyObject) BridgeError![]u8 {
    \\    if (object == null) return error.PythonError;
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\
    \\
    \\    var size: python.Py_ssize_t = 0;
    \\    const utf8 = python.PyUnicode_AsUTF8AndSize(@ptrCast(object), &size);
    \\    if (utf8 != null) {
    \\        return try allocator.dupe(u8, utf8[0..@intCast(size)]);
    \\    }
    \\    python.PyErr_Clear();
    \\
    \\
    \\    var bytes_ptr: [*c]u8 = undefined;
    \\    var bytes_len: python.Py_ssize_t = 0;
    \\    if (python.PyBytes_AsStringAndSize(@ptrCast(object), &bytes_ptr, &bytes_len) == 0) {
    \\        return try allocator.dupe(u8, bytes_ptr[0..@intCast(bytes_len)]);
    \\    }
    \\    return error.PythonError;
    \\}
    \\
    \\
    \\fn utf16CopyFromObject(allocator: std.mem.Allocator, object: ?*python.PyObject) BridgeError![]u8 {
    \\    if (object == null) return error.PythonError;
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\
    \\
    \\    const encoded = python.PyUnicode_AsUTF16String(@ptrCast(object));
    \\    if (encoded == null) {
    \\        python.PyErr_Clear();
    \\        return try utf8CopyFromObject(allocator, object);
    \\    }
    \\    defer python.Py_DecRef(encoded);
    \\
    \\
    \\    var bytes_ptr: [*c]u8 = undefined;
    \\    var bytes_len: python.Py_ssize_t = 0;
    \\    if (python.PyBytes_AsStringAndSize(encoded, &bytes_ptr, &bytes_len) != 0) {
    \\        return error.PythonError;
    \\    }
    \\    return try allocator.dupe(u8, bytes_ptr[0..@intCast(bytes_len)]);
    \\}
    \\
    \\
    \\fn bytesCopyFromObject(allocator: std.mem.Allocator, object: ?*python.PyObject) BridgeError![]u8 {
    \\    if (object == null) return error.PythonError;
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\
    \\
    \\    var bytes_ptr: [*c]u8 = undefined;
    \\    var bytes_len: python.Py_ssize_t = 0;
    \\    if (python.PyBytes_AsStringAndSize(@ptrCast(object), &bytes_ptr, &bytes_len) == 0) {
    \\        return try allocator.dupe(u8, bytes_ptr[0..@intCast(bytes_len)]);
    \\    }
    \\    python.PyErr_Clear();
    \\
    \\
    \\    const coerced = python.PyBytes_FromObject(@ptrCast(object));
    \\    if (coerced == null) return error.PythonError;
    \\    defer python.Py_DecRef(coerced);
    \\    if (python.PyBytes_AsStringAndSize(coerced, &bytes_ptr, &bytes_len) != 0) return error.PythonError;
    \\    return try allocator.dupe(u8, bytes_ptr[0..@intCast(bytes_len)]);
    \\}
    \\
    \\
    \\fn pyObjectFromBool(value: bool) BridgeError!?*python.PyObject {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    const object = python.PyBool_FromLong(if (value) 1 else 0);
    \\    if (object == null) return error.PythonError;
    \\    return @ptrCast(object);
    \\}
    \\
    \\
    \\fn pyObjectFromI32(value: i32) BridgeError!?*python.PyObject {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    const object = python.PyLong_FromLong(@intCast(value));
    \\    if (object == null) return error.PythonError;
    \\    return @ptrCast(object);
    \\}
    \\
    \\
    \\fn pyObjectFromI64(value: i64) BridgeError!?*python.PyObject {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    const object = python.PyLong_FromLongLong(@intCast(value));
    \\    if (object == null) return error.PythonError;
    \\    return @ptrCast(object);
    \\}
    \\
    \\
    \\fn pyObjectFromU32(value: u32) BridgeError!?*python.PyObject {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    const object = python.PyLong_FromUnsignedLongLong(@intCast(value));
    \\    if (object == null) return error.PythonError;
    \\    return @ptrCast(object);
    \\}
    \\
    \\
    \\fn pyObjectFromU64(value: u64) BridgeError!?*python.PyObject {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    const object = python.PyLong_FromUnsignedLongLong(@intCast(value));
    \\    if (object == null) return error.PythonError;
    \\    return @ptrCast(object);
    \\}
    \\
    \\
    \\fn pyObjectFromPtr(ptr: *anyopaque) BridgeError!?*python.PyObject {
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    const object = python.PyLong_FromVoidPtr(ptr);
    \\    if (object == null) return error.PythonError;
    \\    return @ptrCast(object);
    \\}
    \\
    \\
    \\fn pyBoolFromObject(object: ?*python.PyObject) BridgeError!bool {
    \\    if (object == null or pyIsNone(object)) {
    \\        setTypeError("expected bool");
    \\        return error.PythonError;
    \\    }
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    const value = python.PyObject_IsTrue(@ptrCast(object));
    \\    if (value < 0) return error.PythonError;
    \\    return value != 0;
    \\}
    \\
    \\
    \\fn pyOptionalBool(object: ?*python.PyObject) BridgeError!?bool {
    \\    if (object == null or pyIsNone(object)) return null;
    \\    return try pyBoolFromObject(object);
    \\}
    \\
    \\
    \\fn pyI64FromObject(object: ?*python.PyObject) BridgeError!i64 {
    \\    if (object == null or pyIsNone(object)) {
    \\        setTypeError("expected int");
    \\        return error.PythonError;
    \\    }
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    const value = python.PyLong_AsLongLong(@ptrCast(object));
    \\    if (value == -1 and python.PyErr_Occurred() != null) return error.PythonError;
    \\    return @intCast(value);
    \\}
    \\
    \\
    \\fn pyI32FromObject(object: ?*python.PyObject) BridgeError!i32 {
    \\    const value = try pyI64FromObject(object);
    \\    if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) {
    \\        setTypeError("int out of range for i32");
    \\        return error.PythonError;
    \\    }
    \\    return @intCast(value);
    \\}
    \\
    \\
    \\fn pyU64FromObject(object: ?*python.PyObject) BridgeError!u64 {
    \\    if (object == null or pyIsNone(object)) {
    \\        setTypeError("expected int");
    \\        return error.PythonError;
    \\    }
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    const value = python.PyLong_AsUnsignedLongLong(@ptrCast(object));
    \\    if (python.PyErr_Occurred() != null) return error.PythonError;
    \\    return value;
    \\}
    \\
    \\
    \\fn pyU32FromObject(object: ?*python.PyObject) BridgeError!u32 {
    \\    const value = try pyU64FromObject(object);
    \\    if (value > std.math.maxInt(u32)) {
    \\        setTypeError("int out of range for u32");
    \\        return error.PythonError;
    \\    }
    \\    return @intCast(value);
    \\}
    \\
    \\
    \\fn pyEnumFromObject(comptime T: type, object: ?*python.PyObject) BridgeError!T {
    \\    const raw = try pyU64FromObject(object);
    \\    inline for (@typeInfo(T).@"enum".fields) |field| {
    \\        if (raw == field.value) return @enumFromInt(raw);
    \\    }
    \\    setTypeError("invalid enum value");
    \\    return error.PythonError;
    \\}
    \\
    \\
    \\fn pyPtrFromObject(object: ?*python.PyObject) BridgeError!*anyopaque {
    \\    if (object == null or pyIsNone(object)) {
    \\        setTypeError("expected pointer");
    \\        return error.PythonError;
    \\    }
    \\
    \\
    \\    const state = python.PyGILState_Ensure();
    \\    defer python.PyGILState_Release(state);
    \\    const ptr = python.PyLong_AsVoidPtr(@ptrCast(object));
    \\    if (ptr == null and python.PyErr_Occurred() != null) return error.PythonError;
    \\    return ptr orelse {
    \\        setTypeError("expected pointer");
    \\        return error.PythonError;
    \\    };
    \\}
    \\
    \\
    \\pub inline fn releaseSource(source: ValueSource, owned: bool) void {
    \\    if (!owned) return;
    \\    switch (source) {
    \\        .direct => |object| pyDecref(object),
    \\        .attr => {},
    \\    }
    \\}
    \\
    \\
    \\fn defaultBridgeValue(comptime T: type) T {
    \\    return switch (@typeInfo(T)) {
    \\        .optional => null,
    \\        .bool => false,
    \\        .int, .comptime_int => 0,
    \\        .@"enum" => @as(T, @enumFromInt(0)),
    \\        else => if (@hasDecl(T, "fromBorrowedObject")) T.fromBorrowedObject(null) else unreachable,
    \\    };
    \\}
    \\
    \\
    \\inline fn bridgeValueToPyOwned(comptime T: type, value: T) BridgeError!?*python.PyObject {
    \\    if (T == bool) return pyObjectFromBool(value);
    \\    if (T == i32) return pyObjectFromI32(value);
    \\    if (T == i64) return pyObjectFromI64(value);
    \\    if (T == u32) return pyObjectFromU32(value);
    \\    if (T == u64) return pyObjectFromU64(value);
    \\    if (@typeInfo(T) == .@"enum") return enumToPyOwned(T, value);
    \\    if (@hasDecl(T, "newRef")) return try value.newRef();
    \\    @compileError("unsupported Python bridge conversion");
    \\}
    \\
    \\
    \\pub inline fn pyObjectToBridgeValue(comptime T: type, object: ?*python.PyObject) BridgeError!T {
    \\    if (T == bool) return try pyBoolFromObject(object);
    \\    if (T == i32) return try pyI32FromObject(object);
    \\    if (T == i64) return try pyI64FromObject(object);
    \\    if (T == u32) return try pyU32FromObject(object);
    \\    if (T == u64) return try pyU64FromObject(object);
    \\    if (@typeInfo(T) == .@"enum") return try pyEnumFromObject(T, object);
    \\    if (@hasDecl(T, "fromOwned")) return T.fromOwned(object);
    \\    @compileError("unsupported Python bridge reverse conversion");
    \\}
    \\
    \\
    \\pub const ConstString = struct {
    \\    source: ValueSource,
    \\
    \\
    \\    pub fn fromBorrowedObject(object: ?*python.PyObject) @This() {
    \\        return .{ .source = .{ .direct = object } };
    \\    }
    \\
    \\
    \\    pub fn fromBorrowedSource(source: ValueSource) @This() {
    \\        return .{ .source = source };
    \\    }
    \\
    \\
    \\    pub fn fromOwned(object: ?*python.PyObject) @This() {
    \\        return .{ .source = .{ .direct = object } };
    \\    }
    \\
    \\
    \\    pub fn newRef(self: @This()) BridgeError!?*python.PyObject {
    \\        return sourceGetOwned(self.source);
    \\    }
    \\
    \\
    \\    pub fn resolveOwned(self: @This()) BridgeError!?*python.PyObject {
    \\        return try self.newRef();
    \\    }
    \\
    \\
    \\    pub inline fn getUTF8(self: @This(), allocator: std.mem.Allocator) BridgeError![]const u8 {
    \\        return try self.getUTF8Copy(allocator);
    \\    }
    \\
    \\
    \\    pub inline fn getUTF8Copy(self: @This(), allocator: std.mem.Allocator) BridgeError![]u8 {
    \\        const object = try sourceGetRequiredOwned(self.source);
    \\        defer pyDecref(object);
    \\        return try utf8CopyFromObject(allocator, object);
    \\    }
    \\
    \\
    \\    pub inline fn getUTF16(self: @This(), allocator: std.mem.Allocator) BridgeError![]const u8 {
    \\        return try self.getUTF16Copy(allocator);
    \\    }
    \\
    \\
    \\    pub inline fn getUTF16Copy(self: @This(), allocator: std.mem.Allocator) BridgeError![]u8 {
    \\        const object = try sourceGetRequiredOwned(self.source);
    \\        defer pyDecref(object);
    \\        return try utf16CopyFromObject(allocator, object);
    \\    }
    \\
    \\
    \\    pub inline fn size(self: @This()) BridgeError!usize {
    \\        return try sourceLength(self.source);
    \\    }
    \\};
    \\
    \\
    \\pub const String = struct {
    \\    source: ValueSource,
    \\    owned: bool,
    \\
    \\
    \\    pub fn fromOwned(object: ?*python.PyObject) @This() {
    \\        return .{ .source = .{ .direct = object }, .owned = true };
    \\    }
    \\
    \\
    \\    pub fn fromNewRef(object: ?*python.PyObject) @This() {
    \\        return .fromOwned(pyNewRef(object));
    \\    }
    \\
    \\
    \\    pub fn fromBorrowedObject(object: ?*python.PyObject) @This() {
    \\        return .{ .source = .{ .direct = object }, .owned = false };
    \\    }
    \\
    \\
    \\    pub fn fromBorrowedSource(source: ValueSource) @This() {
    \\        return .{ .source = source, .owned = false };
    \\    }
    \\
    \\
    \\    pub fn newRef(self: @This()) BridgeError!?*python.PyObject {
    \\        return sourceGetOwned(self.source);
    \\    }
    \\
    \\
    \\    pub fn resolveOwned(self: *@This()) BridgeError!?*python.PyObject {
    \\        if (self.owned) {
    \\            const object = switch (self.source) {
    \\                .direct => |object| object,
    \\                .attr => try sourceGetOwned(self.source),
    \\            };
    \\            self.* = .fromBorrowedObject(null);
    \\            return object;
    \\        }
    \\        return try self.newRef();
    \\    }
    \\
    \\
    \\    pub inline fn initUTF8(allocator: std.mem.Allocator, src: []u8) BridgeError!String {
    \\        _ = allocator;
    \\        const state = python.PyGILState_Ensure();
    \\        defer python.PyGILState_Release(state);
    \\        const object = python.PyUnicode_FromStringAndSize(@ptrCast(src.ptr), @intCast(src.len));
    \\        if (object == null) return error.PythonError;
    \\        return .fromOwned(@ptrCast(object));
    \\    }
    \\
    \\
    \\    pub inline fn initUTF16(allocator: std.mem.Allocator, src: []u8) BridgeError!String {
    \\        _ = allocator;
    \\        const state = python.PyGILState_Ensure();
    \\        defer python.PyGILState_Release(state);
    \\
    \\
    \\        var byteorder: c_int = 0;
    \\        const object = python.PyUnicode_DecodeUTF16(@ptrCast(src.ptr), @intCast(src.len), null, &byteorder);
    \\        if (object == null) return error.PythonError;
    \\        return .fromOwned(@ptrCast(object));
    \\    }
    \\
    \\
    \\    pub inline fn getUTF8(self: *const String, allocator: std.mem.Allocator) BridgeError![]const u8 {
    \\        return try self.getUTF8Copy(allocator);
    \\    }
    \\
    \\
    \\    pub inline fn getUTF8Copy(self: *const String, allocator: std.mem.Allocator) BridgeError![]u8 {
    \\        const object = try sourceGetRequiredOwned(self.source);
    \\        defer pyDecref(object);
    \\        return try utf8CopyFromObject(allocator, object);
    \\    }
    \\
    \\
    \\    pub inline fn getUTF8Owned(self: *String, allocator: std.mem.Allocator) BridgeError![]u8 {
    \\        const copied = try self.getUTF8Copy(allocator);
    \\        self.deinit(allocator);
    \\        return copied;
    \\    }
    \\
    \\
    \\    pub inline fn getUTF16(self: *const String, allocator: std.mem.Allocator) BridgeError![]const u8 {
    \\        return try self.getUTF16Copy(allocator);
    \\    }
    \\
    \\
    \\    pub inline fn getUTF16Copy(self: *const String, allocator: std.mem.Allocator) BridgeError![]u8 {
    \\        const object = try sourceGetRequiredOwned(self.source);
    \\        defer pyDecref(object);
    \\        return try utf16CopyFromObject(allocator, object);
    \\    }
    \\
    \\
    \\    pub inline fn getUTF16Owned(self: *String, allocator: std.mem.Allocator) BridgeError![]u8 {
    \\        const copied = try self.getUTF16Copy(allocator);
    \\        self.deinit(allocator);
    \\        return copied;
    \\    }
    \\
    \\
    \\    pub inline fn size(self: *const String) BridgeError!usize {
    \\        return try sourceLength(self.source);
    \\    }
    \\
    \\
    \\    pub inline fn toConst(self: @This()) ConstString {
    \\        return .{ .source = self.source };
    \\    }
    \\
    \\
    \\    pub inline fn deinit(self: *String, allocator: std.mem.Allocator) void {
    \\        _ = allocator;
    \\        releaseSource(self.source, self.owned);
    \\        self.* = .fromBorrowedObject(null);
    \\    }
    \\};
    \\
    \\
    \\pub const ConstBytes = struct {
    \\    source: ValueSource,
    \\
    \\
    \\    pub fn fromBorrowedObject(object: ?*python.PyObject) @This() {
    \\        return .{ .source = .{ .direct = object } };
    \\    }
    \\
    \\
    \\    pub fn fromBorrowedSource(source: ValueSource) @This() {
    \\        return .{ .source = source };
    \\    }
    \\
    \\
    \\    pub fn fromOwned(object: ?*python.PyObject) @This() {
    \\        return .{ .source = .{ .direct = object } };
    \\    }
    \\
    \\
    \\    pub fn newRef(self: @This()) BridgeError!?*python.PyObject {
    \\        return sourceGetOwned(self.source);
    \\    }
    \\
    \\
    \\    pub fn resolveOwned(self: @This()) BridgeError!?*python.PyObject {
    \\        return try self.newRef();
    \\    }
    \\
    \\
    \\    pub inline fn get(self: @This(), allocator: std.mem.Allocator) BridgeError![]const u8 {
    \\        return try self.getCopy(allocator);
    \\    }
    \\
    \\
    \\    pub inline fn getCopy(self: @This(), allocator: std.mem.Allocator) BridgeError![]u8 {
    \\        const object = try sourceGetRequiredOwned(self.source);
    \\        defer pyDecref(object);
    \\        return try bytesCopyFromObject(allocator, object);
    \\    }
    \\
    \\
    \\    pub inline fn size(self: @This()) BridgeError!usize {
    \\        return try sourceLength(self.source);
    \\    }
    \\};
    \\
    \\
    \\pub const Bytes = struct {
    \\    source: ValueSource,
    \\    owned: bool,
    \\
    \\
    \\    pub fn fromOwned(object: ?*python.PyObject) @This() {
    \\        return .{ .source = .{ .direct = object }, .owned = true };
    \\    }
    \\
    \\
    \\    pub fn fromNewRef(object: ?*python.PyObject) @This() {
    \\        return .fromOwned(pyNewRef(object));
    \\    }
    \\
    \\
    \\    pub fn fromBorrowedObject(object: ?*python.PyObject) @This() {
    \\        return .{ .source = .{ .direct = object }, .owned = false };
    \\    }
    \\
    \\
    \\    pub fn fromBorrowedSource(source: ValueSource) @This() {
    \\        return .{ .source = source, .owned = false };
    \\    }
    \\
    \\
    \\    pub fn newRef(self: @This()) BridgeError!?*python.PyObject {
    \\        return sourceGetOwned(self.source);
    \\    }
    \\
    \\
    \\    pub fn resolveOwned(self: *@This()) BridgeError!?*python.PyObject {
    \\        if (self.owned) {
    \\            const object = switch (self.source) {
    \\                .direct => |object| object,
    \\                .attr => try sourceGetOwned(self.source),
    \\            };
    \\            self.* = .fromBorrowedObject(null);
    \\            return object;
    \\        }
    \\        return try self.newRef();
    \\    }
    \\
    \\
    \\    pub inline fn init(src: []u8) Bytes {
    \\        const state = python.PyGILState_Ensure();
    \\        defer python.PyGILState_Release(state);
    \\        const object = python.PyBytes_FromStringAndSize(@ptrCast(src.ptr), @intCast(src.len));
    \\        return .fromOwned(@ptrCast(object));
    \\    }
    \\
    \\
    \\    pub inline fn initCopy(allocator: std.mem.Allocator, src: []const u8) BridgeError!Bytes {
    \\        _ = allocator;
    \\        const state = python.PyGILState_Ensure();
    \\        defer python.PyGILState_Release(state);
    \\        const object = python.PyBytes_FromStringAndSize(@ptrCast(src.ptr), @intCast(src.len));
    \\        if (object == null) return error.PythonError;
    \\        return .fromOwned(@ptrCast(object));
    \\    }
    \\
    \\
    \\    pub inline fn get(self: *const Bytes, allocator: std.mem.Allocator) BridgeError![]const u8 {
    \\        return try self.getCopy(allocator);
    \\    }
    \\
    \\
    \\    pub inline fn getCopy(self: *const Bytes, allocator: std.mem.Allocator) BridgeError![]u8 {
    \\        const object = try sourceGetRequiredOwned(self.source);
    \\        defer pyDecref(object);
    \\        return try bytesCopyFromObject(allocator, object);
    \\    }
    \\
    \\
    \\    pub inline fn getOwned(self: *Bytes, allocator: std.mem.Allocator) BridgeError![]u8 {
    \\        const copied = try self.getCopy(allocator);
    \\        self.deinit(allocator);
    \\        return copied;
    \\    }
    \\
    \\
    \\    pub inline fn toConst(self: @This()) ConstBytes {
    \\        return .{ .source = self.source };
    \\    }
    \\
    \\
    \\    pub inline fn size(self: *const Bytes) BridgeError!usize {
    \\        return try sourceLength(self.source);
    \\    }
    \\
    \\
    \\    pub inline fn deinit(self: *Bytes, allocator: std.mem.Allocator) void {
    \\        _ = allocator;
    \\        releaseSource(self.source, self.owned);
    \\        self.* = .fromBorrowedObject(null);
    \\    }
    \\};
    \\
    \\
    \\pub fn List(comptime T: type) type {
    \\    return struct {
    \\        source: ValueSource,
    \\        owned: bool,
    \\
    \\
    \\        pub fn fromOwned(object: ?*python.PyObject) @This() {
    \\            return .{ .source = .{ .direct = object }, .owned = true };
    \\        }
    \\
    \\
    \\        pub fn fromNewRef(object: ?*python.PyObject) @This() {
    \\            return .fromOwned(pyNewRef(object));
    \\        }
    \\
    \\
    \\        pub fn fromBorrowedObject(object: ?*python.PyObject) @This() {
    \\            return .{ .source = .{ .direct = object }, .owned = false };
    \\        }
    \\
    \\
    \\        pub fn fromBorrowedSource(source: ValueSource) @This() {
    \\            return .{ .source = source, .owned = false };
    \\        }
    \\
    \\
    \\        pub fn newRef(self: @This()) BridgeError!?*python.PyObject {
    \\            return sourceGetOwned(self.source);
    \\        }
    \\
    \\
    \\        pub fn resolveOwned(self: *@This()) BridgeError!?*python.PyObject {
    \\            if (self.owned) {
    \\                const object = switch (self.source) {
    \\                    .direct => |object| object,
    \\                    .attr => try sourceGetOwned(self.source),
    \\                };
    \\                self.* = .fromBorrowedObject(null);
    \\                return object;
    \\            }
    \\            return try self.newRef();
    \\        }
    \\
    \\
    \\        pub inline fn init(allocator: std.mem.Allocator, len: usize) BridgeError!@This() {
    \\            _ = allocator;
    \\            return .fromOwned(try createListOwned(len));
    \\        }
    \\
    \\
    \\        pub inline fn initOwned(allocator: std.mem.Allocator, value: []T) BridgeError!@This() {
    \\            var list = try @This().init(allocator, value.len);
    \\            errdefer list.deinit(allocator);
    \\
    \\
    \\            for (value, 0..) |item, index| {
    \\                try list.set(allocator, index, item);
    \\            }
    \\            return list;
    \\        }
    \\
    \\
    \\        pub inline fn size(self: @This()) BridgeError!usize {
    \\            return try sourceLength(self.source);
    \\        }
    \\
    \\
    \\        pub inline fn toConst(self: @This()) ConstList(T) {
    \\            return .{ .source = self.source };
    \\        }
    \\
    \\
    \\        pub inline fn get(self: @This(), index: usize) BridgeError!T {
    \\            if (@hasDecl(T, "fromOwned")) {
    \\                const item = try sourceSequenceItemOwned(self.source, index);
    \\                return try pyObjectToBridgeValue(T, item);
    \\            }
    \\            const item = try sourceSequenceItemOwned(self.source, index);
    \\            defer pyDecref(item);
    \\            return try pyObjectToBridgeValue(T, item);
    \\        }
    \\
    \\
    \\        pub inline fn set(self: @This(), allocator: std.mem.Allocator, index: usize, value: T) BridgeError!void {
    \\            _ = allocator;
    \\            const list_object = try sourceGetRequiredOwned(self.source);
    \\            defer pyDecref(list_object);
    \\            const item = try bridgeValueToPyOwned(T, value);
    \\            try listSetOwned(list_object, index, item);
    \\        }
    \\
    \\
    \\        pub inline fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    \\            _ = allocator;
    \\            releaseSource(self.source, self.owned);
    \\            self.* = .fromBorrowedObject(null);
    \\        }
    \\    };
    \\}
    \\
    \\
    \\pub fn ConstListItem(comptime T: type) type {
    \\    return struct {
    \\        value: T,
    \\        source: ValueSource,
    \\        owned: bool,
    \\
    \\
    \\        pub fn fromOwned(object: ?*python.PyObject) @This() {
    \\            return .{ .value = T.fromBorrowedObject(object), .source = .{ .direct = object }, .owned = true };
    \\        }
    \\
    \\
    \\        pub fn toConst(self: *const @This()) T {
    \\            return self.value;
    \\        }
    \\
    \\
    \\        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    \\            _ = allocator;
    \\            releaseSource(self.source, self.owned);
    \\            self.* = .{ .value = defaultBridgeValue(T), .source = .{ .direct = null }, .owned = false };
    \\        }
    \\    };
    \\}
    \\
    \\
    \\pub fn ConstList(comptime T: type) type {
    \\    return struct {
    \\        source: ValueSource,
    \\
    \\
    \\        pub fn fromBorrowedObject(object: ?*python.PyObject) @This() {
    \\            return .{ .source = .{ .direct = object } };
    \\        }
    \\
    \\
    \\        pub fn fromBorrowedSource(source: ValueSource) @This() {
    \\            return .{ .source = source };
    \\        }
    \\
    \\
    \\        pub fn fromOwned(object: ?*python.PyObject) @This() {
    \\            return .{ .source = .{ .direct = object } };
    \\        }
    \\
    \\
    \\        pub fn newRef(self: @This()) BridgeError!?*python.PyObject {
    \\            return sourceGetOwned(self.source);
    \\        }
    \\
    \\
    \\        pub fn resolveOwned(self: @This()) BridgeError!?*python.PyObject {
    \\            return try self.newRef();
    \\        }
    \\
    \\
    \\        pub inline fn size(self: @This()) BridgeError!usize {
    \\            return try sourceLength(self.source);
    \\        }
    \\
    \\
    \\        pub inline fn get(self: @This(), index: usize) if (@hasDecl(T, "fromBorrowedObject")) BridgeError!ConstListItem(T) else BridgeError!T {
    \\            if (@hasDecl(T, "fromBorrowedObject")) {
    \\                const item = try sourceSequenceItemOwned(self.source, index);
    \\                return ConstListItem(T).fromOwned(item);
    \\            }
    \\            const item = try sourceSequenceItemOwned(self.source, index);
    \\            defer pyDecref(item);
    \\            return try pyObjectToBridgeValue(T, item);
    \\        }
    \\    };
    \\}
    \\
    \\
    \\pub fn fieldWrapper(comptime T: type, source: ValueSource, name: [:0]const u8) BridgeError!T {
    \\    return switch (source) {
    \\        .direct => |object| T.fromBorrowedSource(.{ .attr = .{ .parent = object, .name = name } }),
    \\        .attr => blk: {
    \\            const value = try sourceChildOwned(source, name);
    \\            if (value == null) {
    \\                setTypeError("expected object with required mzproto field");
    \\                return error.PythonError;
    \\            }
    \\            break :blk T.fromOwned(value);
    \\        },
    \\    };
    \\}
    \\
    \\
    \\pub fn optionalFieldWrapper(comptime T: type, source: ValueSource, name: [:0]const u8) BridgeError!?T {
    \\    const value = try sourceChildOwned(source, name);
    \\    if (value == null or pyIsNone(value)) {
    \\        pyDecref(value);
    \\        return null;
    \\    }
    \\    return T.fromOwned(value);
    \\}
    \\
    \\
    \\pub fn fieldValue(comptime T: type, source: ValueSource, name: [:0]const u8) BridgeError!T {
    \\    const value = try sourceChildOwned(source, name);
    \\    defer pyDecref(value);
    \\    if (value == null) {
    \\        setTypeError("expected object with required mzproto field");
    \\        return error.PythonError;
    \\    }
    \\    return try pyObjectToBridgeValue(T, value);
    \\}
    \\
    \\
    \\pub fn optionalFieldValue(comptime T: type, source: ValueSource, name: [:0]const u8) BridgeError!?T {
    \\    const value = try sourceChildOwned(source, name);
    \\    defer pyDecref(value);
    \\    if (value == null or pyIsNone(value)) return null;
    \\    return try pyObjectToBridgeValue(T, value);
    \\}
    \\
    \\
    \\pub fn fieldPtr(source: ValueSource, name: [:0]const u8) BridgeError!*anyopaque {
    \\    const value = try sourceChildOwned(source, name);
    \\    defer pyDecref(value);
    \\    return try pyPtrFromObject(value);
    \\}
    \\
    \\
    \\pub fn setFieldValue(comptime T: type, source: ValueSource, name: [:0]const u8, value: T) BridgeError!void {
    \\    const owner = try sourceGetRequiredOwned(source);
    \\    defer pyDecref(owner);
    \\    const object = try bridgeValueToPyOwned(T, value);
    \\    defer pyDecref(object);
    \\    try objectSetOwned(owner, name, object);
    \\}
    \\
    \\
    \\pub fn setOptionalFieldValue(comptime T: type, source: ValueSource, name: [:0]const u8, value: ?T) BridgeError!void {
    \\    const owner = try sourceGetRequiredOwned(source);
    \\    defer pyDecref(owner);
    \\    const object = if (value) |v| try bridgeValueToPyOwned(T, v) else pyNoneOwned();
    \\    defer pyDecref(object);
    \\    try objectSetOwned(owner, name, object);
    \\}
    \\
    \\
    \\pub fn setFieldPtr(source: ValueSource, name: [:0]const u8, ptr: *anyopaque) BridgeError!void {
    \\    const owner = try sourceGetRequiredOwned(source);
    \\    defer pyDecref(owner);
    \\    const value = try pyObjectFromPtr(ptr);
    \\    defer pyDecref(value);
    \\    try objectSetOwned(owner, name, value);
    \\}
    \\
    \\
    \\pub fn deleteField(source: ValueSource, name: [:0]const u8) void {
    \\    const owner = sourceGetRequiredOwned(source) catch return;
    \\    defer pyDecref(owner);
    \\    objectDelete(owner, name);
    \\}
    \\
    \\

    );

    try emitEnumToPyOwned(writer, schema);

    for (schema.declarations.items) |decl| {
        switch (decl) {
            .enum_decl => |enum_decl| try emitEnumDecl(writer, allocator, enum_decl),
            .struct_decl => |struct_decl| try emitObjectWrapper(writer, allocator, schema, struct_decl.name, struct_decl.fields.items, false, struct_decl.doc),
            .union_decl => |union_decl| try emitUnionWrapper(writer, allocator, schema, union_decl),
            .opaque_decl => |opaque_decl| try emitObjectWrapper(writer, allocator, schema, opaque_decl.name, &.{}, true, opaque_decl.doc),
            .function_decl => {},
        }
    }
}
