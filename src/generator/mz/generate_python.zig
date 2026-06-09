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

fn emitPyStringLiteral(writer: *std.Io.Writer, value: []const u8) !void {
    try writer.writeByte('"');
    for (value) |char| {
        switch (char) {
            '\\' => try writer.writeAll("\\\\"),
            '"' => try writer.writeAll("\\\""),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            else => try writer.writeByte(char),
        }
    }
    try writer.writeByte('"');
}

fn emitDocStringIndented(writer: *std.Io.Writer, doc: ?[]u8, indent: usize) !bool {
    const value = doc orelse return false;
    try writeIndent(writer, indent);
    try emitPyStringLiteral(writer, value);
    try writer.writeAll("\n");
    return true;
}

fn emitCommentIndented(writer: *std.Io.Writer, doc: ?[]u8, indent: usize) !void {
    const value = doc orelse return;
    var iterator = std.mem.splitScalar(u8, value, '\n');
    while (iterator.next()) |line| {
        try writeIndent(writer, indent);
        if (line.len == 0) {
            try writer.writeAll("#\n");
        } else {
            try writer.print("# {s}\n", .{line});
        }
    }
}

fn writeIndent(writer: *std.Io.Writer, indent: usize) !void {
    for (0..indent) |_| try writer.writeByte(' ');
}

fn isPythonKeyword(name: []const u8) bool {
    const keywords = [_][]const u8{
        "False", "None", "True", "and", "as", "assert", "async", "await", "break", "class", "continue",
        "def", "del", "elif", "else", "except", "finally", "for", "from", "global", "if", "import",
        "in", "is", "lambda", "nonlocal", "not", "or", "pass", "raise", "return", "try", "while", "with", "yield",
    };
    for (keywords) |keyword| {
        if (std.mem.eql(u8, name, keyword)) return true;
    }
    return false;
}

fn pythonIdentifierOwned(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    const snake = try utils.snakeCaseOwned(allocator, name);
    if (!isPythonKeyword(snake)) return snake;
    defer allocator.free(snake);
    return std.fmt.allocPrint(allocator, "{s}_", .{snake});
}

fn pythonClassNameOwned(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    const pascal = try utils.pascalCaseOwned(allocator, name);
    if (!isPythonKeyword(pascal)) return pascal;
    defer allocator.free(pascal);
    return std.fmt.allocPrint(allocator, "{s}_", .{pascal});
}

fn pythonEnumMemberOwned(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    const upper = try utils.upperSnakeOwned(allocator, name);
    if (!isPythonKeyword(upper)) return upper;
    defer allocator.free(upper);
    return std.fmt.allocPrint(allocator, "{s}_", .{upper});
}

fn pythonTypeOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) ![]u8 {
    return switch (type_expr.*) {
        .optional => |child| blk: {
            const inner = try pythonTypeOwned(allocator, schema, child);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "{s} | None", .{inner});
        },
        .reference => |child| pythonTypeOwned(allocator, schema, child),
        .list => |child| blk: {
            const inner = try pythonTypeOwned(allocator, schema, child);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "Sequence[{s}]", .{inner});
        },
        .function => allocator.dupe(u8, "Callable[..., Any]"),
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_void => allocator.dupe(u8, "None"),
            .builtin_bool => allocator.dupe(u8, "bool"),
            .builtin_u32, .builtin_u64, .builtin_i32, .builtin_i64, .builtin_time => allocator.dupe(u8, "int"),
            .builtin_string => allocator.dupe(u8, "str"),
            .builtin_bytes => allocator.dupe(u8, "bytes"),
            .enum_decl, .struct_decl, .union_decl, .opaque_decl => pythonClassNameOwned(allocator, name),
            else => pythonClassNameOwned(allocator, name),
        },
    };
}

fn pythonNativeFunctionNameOwned(allocator: std.mem.Allocator, owner: ?[]const u8, name: []const u8) ![]u8 {
    const function_name = try pythonIdentifierOwned(allocator, name);
    defer allocator.free(function_name);

    if (owner) |owner_name| {
        const owner_snake = try pythonIdentifierOwned(allocator, owner_name);
        defer allocator.free(owner_snake);
        return std.fmt.allocPrint(allocator, "{s}_{s}", .{ owner_snake, function_name });
    }

    return allocator.dupe(u8, function_name);
}

fn isVoidType(schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) bool {
    return type_expr.* == .named and utils.classifyNamed(schema, type_expr.named) == .builtin_void;
}

fn pythonFieldDefaultExpr(schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) ?[]const u8 {
    return switch (type_expr.*) {
        .optional => "None",
        .reference => |child| pythonFieldDefaultExpr(schema, child),
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_bool => "False",
            else => null,
        },
        else => null,
    };
}

fn unionVariantStructName(schema: *const Parser.Schema, field: Parser.Field) ?[]const u8 {
    if (field.type_expr.* != .named) return null;
    const name = field.type_expr.named;
    return switch (utils.classifyNamed(schema, name)) {
        .struct_decl => name,
        else => null,
    };
}

fn structIsUnionVariant(schema: *const Parser.Schema, struct_name: []const u8) bool {
    for (schema.declarations.items) |decl| {
        switch (decl) {
            .union_decl => |union_decl| {
                for (union_decl.fields.items) |field| {
                    if (unionVariantStructName(schema, field)) |name| {
                        if (std.mem.eql(u8, name, struct_name)) return true;
                    }
                }
            },
            else => {},
        }
    }
    return false;
}

fn emitStructBaseList(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, struct_name: []const u8) !void {
    var first = true;
    for (schema.declarations.items) |decl| {
        switch (decl) {
            .union_decl => |union_decl| {
                var matches = false;
                for (union_decl.fields.items) |field| {
                    if (unionVariantStructName(schema, field)) |name| {
                        if (std.mem.eql(u8, name, struct_name)) {
                            matches = true;
                            break;
                        }
                    }
                }
                if (!matches) continue;
                const base_name = try pythonClassNameOwned(allocator, union_decl.name);
                defer allocator.free(base_name);
                if (!first) try writer.writeAll(", ");
                first = false;
                try writer.writeAll(base_name);
            },
            else => {},
        }
    }
}

fn emitParameterList(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, params: []const Parser.Parameter) !void {
    for (params) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        const ty = try pythonTypeOwned(allocator, schema, param.type_expr);
        defer allocator.free(ty);
        try writer.print(", {s}: {s}", .{ name, ty });
    }
}

fn emitNativeCallArgs(allocator: std.mem.Allocator, writer: *std.Io.Writer, params: []const Parser.Parameter) !void {
    for (params) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        try writer.print(", {s}", .{name});
    }
}

fn emitMethodBody(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, native_name: []const u8, params: []const Parser.Parameter, return_type: *const Parser.TypeExpr, receiver_arg: []const u8, is_async: bool) !void {
    try writer.print("        result = _native.{s}({s}", .{ native_name, receiver_arg });
    try emitNativeCallArgs(allocator, writer, params);
    try writer.writeAll(")\n");

    if (is_async) {
        if (isVoidType(schema, return_type)) {
            try writer.writeAll("        await result\n        return None\n");
        } else {
            try writer.writeAll("        return await result\n");
        }
        return;
    }

    if (isVoidType(schema, return_type)) {
        try writer.writeAll("        return None\n");
    } else {
        try writer.writeAll("        return result\n");
    }
}

fn emitStructMethod(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, owner_name: []const u8, field: Parser.Field) !void {
    const signature = field.type_expr.function;
    const method_name = try pythonIdentifierOwned(allocator, field.name);
    defer allocator.free(method_name);
    const manual_name = try pythonNativeFunctionNameOwned(allocator, owner_name, field.name);
    defer allocator.free(manual_name);
    const return_ty = try pythonTypeOwned(allocator, schema, signature.return_type);
    defer allocator.free(return_ty);

    try writer.print("    def {s}(self", .{method_name});
    try emitParameterList(allocator, writer, schema, signature.params.items);
    try writer.print(") -> {s}:\n", .{return_ty});
    const has_doc = try emitDocStringIndented(writer, field.doc, 8);
    _ = has_doc;
    try writer.print("        return _methods.{s}(self", .{manual_name});
    try emitNativeCallArgs(allocator, writer, signature.params.items);
    try writer.writeAll(")\n");
    try writer.writeAll("\n");
}

fn emitEnumDecl(allocator: std.mem.Allocator, writer: *std.Io.Writer, decl: Parser.EnumDecl) !void {
    const class_name = try pythonClassNameOwned(allocator, decl.name);
    defer allocator.free(class_name);

    try writer.print("class {s}(IntEnum):\n", .{class_name});
    const has_doc = try emitDocStringIndented(writer, decl.doc, 4);
    if (decl.items.items.len == 0) {
        if (!has_doc) try writer.writeAll("    pass\n");
        try writer.writeAll("\n\n");
        return;
    }

    for (decl.items.items) |item| {
        try emitCommentIndented(writer, item.doc, 4);
        const item_name = try pythonEnumMemberOwned(allocator, item.name);
        defer allocator.free(item_name);
        try writer.print("    {s} = {}\n", .{ item_name, item.value });
    }
    try writer.writeAll("\n\n");
}

fn emitStructDecl(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, decl: Parser.StructDecl) !void {
    const class_name = try pythonClassNameOwned(allocator, decl.name);
    defer allocator.free(class_name);

    try writer.print("@dataclass(slots=True)\nclass {s}", .{class_name});
    if (structIsUnionVariant(schema, decl.name)) {
        try writer.writeAll("(");
        try emitStructBaseList(allocator, writer, schema, decl.name);
        try writer.writeAll(")");
    }
    try writer.writeAll(":\n");
    var emitted_body = try emitDocStringIndented(writer, decl.doc, 4);

    var has_required_fields = false;
    for (decl.fields.items) |field| {
        if (field.type_expr.* == .function) continue;
        try emitCommentIndented(writer, field.doc, 4);
        const name = try pythonIdentifierOwned(allocator, field.name);
        defer allocator.free(name);
        const ty = try pythonTypeOwned(allocator, schema, field.type_expr);
        defer allocator.free(ty);
        if (pythonFieldDefaultExpr(schema, field.type_expr)) |default_expr| {
            try writer.print("    {s}: {s} = {s}\n", .{ name, ty, default_expr });
        } else {
            has_required_fields = true;
            try writer.print("    {s}: {s} = _MZ_MISSING\n", .{ name, ty });
        }
        emitted_body = true;
    }

    if (has_required_fields) {
        try writer.writeAll("\n    def __post_init__(self) -> None:\n");
        for (decl.fields.items) |field| {
            if (field.type_expr.* == .function) continue;
            if (pythonFieldDefaultExpr(schema, field.type_expr) != null) continue;

            const name = try pythonIdentifierOwned(allocator, field.name);
            defer allocator.free(name);
            const error_message = try std.fmt.allocPrint(allocator, "{s} missing required field: {s}", .{ class_name, name });
            defer allocator.free(error_message);
            try writer.print("        if self.{s} is _MZ_MISSING:\n", .{name});
            try writer.writeAll("            raise TypeError(");
            try emitPyStringLiteral(writer, error_message);
            try writer.writeAll(")\n");
        }
        emitted_body = true;
    }

    var emitted_method = false;
    for (decl.fields.items) |field| {
        if (field.type_expr.* != .function) continue;
        if (!emitted_method) try writer.writeAll("\n");
        try emitStructMethod(allocator, writer, schema, decl.name, field);
        emitted_method = true;
        emitted_body = true;
    }

    if (!emitted_body) try writer.writeAll("    pass\n");
    try writer.writeAll("\n\n");
}

fn emitUnionDecl(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, decl: Parser.UnionDecl) !void {
    const class_name = try pythonClassNameOwned(allocator, decl.name);
    defer allocator.free(class_name);

    try writer.print("class {s}:\n", .{class_name});
    var emitted_body = try emitDocStringIndented(writer, decl.doc, 4);
    try writer.print("    __slots__ = ()\n\n    def __new__(cls, *args: Any, **kwargs: Any) -> {s}:\n        if cls is {s}:\n            raise TypeError(\"{s} is not instantiable\")\n        return super().__new__(cls)\n\n", .{ class_name, class_name, class_name });
    emitted_body = true;

    for (decl.fields.items) |field| {
        const name = try pythonIdentifierOwned(allocator, field.name);
        defer allocator.free(name);
        const variant_struct = unionVariantStructName(schema, field) orelse return error.UnsupportedType;
        const ty = try pythonClassNameOwned(allocator, variant_struct);
        defer allocator.free(ty);
        try writer.print("    @classmethod\n    def from_{s}(cls, value: {s}) -> {s}:\n        return value\n\n", .{ name, ty, class_name });
        emitted_body = true;
    }

    if (!emitted_body) try writer.writeAll("    pass\n");
    try writer.writeAll("\n");
}

fn emitOpaqueDecl(allocator: std.mem.Allocator, writer: *std.Io.Writer, decl: Parser.OpaqueDecl) !void {
    const class_name = try pythonClassNameOwned(allocator, decl.name);
    defer allocator.free(class_name);

    try writer.print("class {s}:\n", .{class_name});
    const has_doc = try emitDocStringIndented(writer, decl.doc, 4);
    _ = has_doc;
    try writer.writeAll("    __slots__ = (\"_native_handle\",)\n\n    def __init__(self, native_handle: object) -> None:\n        self._native_handle = native_handle\n\n\n");
}

fn emitClientMethod(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, fun: Parser.FunctionDecl) !void {
    const method_name = try pythonIdentifierOwned(allocator, fun.name);
    defer allocator.free(method_name);
    const native_name = try pythonNativeFunctionNameOwned(allocator, "client", fun.name);
    defer allocator.free(native_name);
    const return_ty = try pythonTypeOwned(allocator, schema, fun.return_type);
    defer allocator.free(return_ty);
    const async_prefix = if (fun.mode == .asynchronous) "async " else "";

    try writer.print("    {s}def {s}(self", .{ async_prefix, method_name });
    try emitParameterList(allocator, writer, schema, fun.params.items);
    try writer.print(") -> {s}:\n", .{return_ty});
    const has_doc = try emitDocStringIndented(writer, fun.doc, 8);
    _ = has_doc;
    try writer.writeAll("        self._ensure_open()\n");
    try emitMethodBody(allocator, writer, schema, native_name, fun.params.items, fun.return_type, "self._native_handle", fun.mode == .asynchronous);
    try writer.writeAll("\n");
}

fn hasClientMethods(schema: *const Parser.Schema) bool {
    for (schema.declarations.items) |decl| {
        if (decl == .function_decl) return true;
    }
    return false;
}

fn emitClient(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema) !void {
    if (!hasClientMethods(schema)) return;

    try writer.writeAll(
        \\class Client:
        \\    """Language-native mzproto client instance."""
        \\    __slots__ = ("_native_handle", "_closed")
        \\
        \\    def __init__(self, config: Config) -> None:
        \\        self._native_handle = _native.client_init(config)
        \\        self._closed = False
        \\
        \\    def _ensure_open(self) -> None:
        \\        if self._closed:
        \\            raise RuntimeError("mzproto client is closed")
        \\
        \\    def close(self) -> None:
        \\        if self._closed:
        \\            return
        \\        _native.client_deinit(self._native_handle)
        \\        self._native_handle = None
        \\        self._closed = True
        \\
        \\    def __enter__(self) -> "Client":
        \\        self._ensure_open()
        \\        return self
        \\
        \\    def __exit__(self, exc_type: object, exc: object, tb: object) -> None:
        \\        self.close()
        \\
        \\    def __del__(self) -> None:
        \\        try:
        \\            self.close()
        \\        except Exception:
        \\            pass
        \\
    );
    try writer.writeAll("\n");

    for (schema.declarations.items) |decl| {
        switch (decl) {
            .function_decl => |fun| try emitClientMethod(allocator, writer, schema, fun),
            else => {},
        }
    }

    try writer.writeAll("\n");
}

fn emitAll(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema) !void {
    try writer.writeAll("__all__ = [\n    \"MzException\",\n");
    for (schema.declarations.items) |decl| {
        switch (decl) {
            .enum_decl => |value| {
                const name = try pythonClassNameOwned(allocator, value.name);
                defer allocator.free(name);
                try writer.print("    \"{s}\",\n", .{name});
            },
            .struct_decl => |value| {
                const name = try pythonClassNameOwned(allocator, value.name);
                defer allocator.free(name);
                try writer.print("    \"{s}\",\n", .{name});
            },
            .union_decl => |value| {
                const name = try pythonClassNameOwned(allocator, value.name);
                defer allocator.free(name);
                try writer.print("    \"{s}\",\n", .{name});
            },
            .opaque_decl => |value| {
                const name = try pythonClassNameOwned(allocator, value.name);
                defer allocator.free(name);
                try writer.print("    \"{s}\",\n", .{name});
            },
            .function_decl => {},
        }
    }
    if (hasClientMethods(schema)) try writer.writeAll("    \"Client\",\n");
    try writer.writeAll("]\n");
}

pub fn emit(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema) !void {
    try writer.writeAll(
        \\# mzproto Python public API
        \\
        \\from __future__ import annotations
        \\
        \\from dataclasses import dataclass
        \\from enum import IntEnum
        \\from typing import Any, Callable, Sequence
        \\
        \\from . import _methods, _native
        \\
        \\_MZ_MISSING = object()
        \\
        \\
        \\class MzException(Exception):
        \\    """Exception raised by mzproto native operations."""
        \\    code: int
        \\    message: str
        \\
        \\    def __init__(self, code: int, message: str) -> None:
        \\        super().__init__(message)
        \\        self.code = code
        \\        self.message = message
        \\
        \\
    );

    for (schema.declarations.items) |decl| switch (decl) {
        .enum_decl => |value| try emitEnumDecl(allocator, writer, value),
        else => {},
    };
    for (schema.declarations.items) |decl| switch (decl) {
        .union_decl => |value| try emitUnionDecl(allocator, writer, schema, value),
        else => {},
    };
    for (schema.declarations.items) |decl| switch (decl) {
        .struct_decl => |value| try emitStructDecl(allocator, writer, schema, value),
        .opaque_decl => |value| try emitOpaqueDecl(allocator, writer, value),
        else => {},
    };

    try emitClient(allocator, writer, schema);
    try emitAll(allocator, writer, schema);
}
