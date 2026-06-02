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

fn emitDocIndented(writer: *std.Io.Writer, doc: ?[]u8, indent: usize) !void {
    if (doc) |value| {
        var spaces: [16]u8 = undefined;
        @memset(&spaces, ' ');
        const prefix = spaces[0..indent];
        var iterator = std.mem.splitScalar(u8, value, '\n');
        while (iterator.next()) |line| {
            if (line.len == 0) {
                try writer.print("{s}///\n", .{prefix});
            } else {
                try writer.print("{s}/// {s}\n", .{ prefix, line });
            }
        }
    }
}

fn emitFunctionParams(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, params: []const Parser.Parameter, receiver: ?[]const u8) !void {
    var first = true;
    if (receiver) |receiver_src| {
        try writer.writeAll(receiver_src);
        first = false;
    }

    for (params) |param| {
        const ty = try utils.zigTypeOwned(allocator, schema, param.type_expr);
        defer allocator.free(ty);

        if (!first) try writer.writeAll(", ");
        first = false;
        try writer.print("{s}: {s}", .{ param.name, ty });
    }
}

fn emitUnusedParams(writer: *std.Io.Writer, params: []const Parser.Parameter, receiver_name: ?[]const u8) !void {
    if (receiver_name) |name| {
        try writer.print("        _ = {s};\n", .{name});
    }
    for (params) |param| {
        try writer.print("        _ = {s};\n", .{param.name});
    }
}

fn emitOkFallback(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, return_type: *const Parser.TypeExpr) !void {
    const ty = try utils.zigTypeOwned(allocator, schema, return_type);
    defer allocator.free(ty);

    if (return_type.* == .named and utils.classifyNamed(schema, return_type.named) == .builtin_void) {
        try writer.writeAll("        return .{ .ok = {} };\n");
        return;
    }

    try writer.print("        return .{{ .ok = initDefault({s}) }};\n", .{ty});
}

fn runtimeBridgeArgExprOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, expr: []const u8, type_expr: *const Parser.TypeExpr, comptime receiver_const: bool) ![]u8 {
    return switch (type_expr.*) {
        .optional => |child| blk: {
            const inner = try runtimeBridgeArgExprOwned(allocator, schema, "value", child, receiver_const);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "if ({s}) |value| {s} else null", .{ expr, inner });
        },
        .reference => |child| switch (child.*) {
            .named => |name| switch (utils.classifyNamed(schema, name)) {
                .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "runtime_bridge.ConstRef{s}{{ .value = @constCast({s}) }}", .{ name, expr }),
                else => try runtimeBridgeArgExprOwned(allocator, schema, expr, child, receiver_const),
            },
            else => try runtimeBridgeArgExprOwned(allocator, schema, expr, child, receiver_const),
        },
        .list => |child| blk: {
            const inner = try runtimeBridgeListTypeOwned(allocator, schema, child, true);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "runtime_bridge.ConstList({s}){{ .slice = {s} }}", .{ inner, expr });
        },
        .function => allocator.dupe(u8, expr),
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_string => try std.fmt.allocPrint(allocator, "runtime_bridge.ConstString{{ .slice = {s} }}", .{expr}),
            .builtin_bytes => try std.fmt.allocPrint(allocator, "runtime_bridge.ConstBytes{{ .slice = {s} }}", .{expr}),
            .builtin_time => try std.fmt.allocPrint(allocator, "@as(u64, @intCast({s}.nanoseconds))", .{expr}),
            .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "runtime_bridge.{s}{{ .value = {s} }}", .{ name, expr }),
            else => allocator.dupe(u8, expr),
        },
    };
}

fn runtimeBridgeListTypeOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr, comptime is_const: bool) ![]u8 {
    return switch (type_expr.*) {
        .reference => |child| switch (child.*) {
            .named => |name| switch (utils.classifyNamed(schema, name)) {
                .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "{s}{s}", .{ if (is_const) "ConstRef" else "Ref", name }),
                else => runtimeBridgeListTypeOwned(allocator, schema, child, is_const),
            },
            else => runtimeBridgeListTypeOwned(allocator, schema, child, is_const),
        },
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_string => allocator.dupe(u8, if (is_const) "ConstString" else "String"),
            .builtin_bytes => allocator.dupe(u8, if (is_const) "ConstBytes" else "Bytes"),
            .struct_decl, .union_decl, .opaque_decl, .enum_decl => allocator.dupe(u8, name),
            .builtin_bool => allocator.dupe(u8, "bool"),
            .builtin_u32 => allocator.dupe(u8, "u32"),
            .builtin_u64 => allocator.dupe(u8, "u64"),
            .builtin_i32 => allocator.dupe(u8, "i32"),
            .builtin_i64 => allocator.dupe(u8, "i64"),
            .builtin_time => allocator.dupe(u8, "u64"),
            else => allocator.dupe(u8, name),
        },
        else => allocator.dupe(u8, "void"),
    };
}

fn runtimeBridgeResultExprOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, expr: []const u8, type_expr: *const Parser.TypeExpr) ![]u8 {
    return switch (type_expr.*) {
        .optional => |child| blk: {
            const inner = try runtimeBridgeResultExprOwned(allocator, schema, "value", child);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "if ({s}) |value| {s} else null", .{ expr, inner });
        },
        .reference => |child| try runtimeBridgeResultExprOwned(allocator, schema, expr, child),
        .list => try std.fmt.allocPrint(allocator, "{s}.slice", .{expr}),
        .function => allocator.dupe(u8, expr),
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_void => allocator.dupe(u8, expr),
            .builtin_string, .builtin_bytes => try std.fmt.allocPrint(allocator, "{s}.slice", .{expr}),
            .builtin_time => try std.fmt.allocPrint(allocator, ".{{ .nanoseconds = @as(i128, @intCast({s})) }}", .{expr}),
            .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "{s}.value", .{expr}),
            else => allocator.dupe(u8, expr),
        },
    };
}

fn typeNeedsRuntimeBridge(type_expr: *const Parser.TypeExpr, schema: *const Parser.Schema) bool {
    return switch (type_expr.*) {
        .optional => |child| typeNeedsRuntimeBridge(child, schema),
        .reference, .list => true,
        .function => false,
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_string, .builtin_bytes => true,
            .struct_decl, .union_decl, .opaque_decl => true,
            else => false,
        },
    };
}

fn emitRuntimeBridgeDispatch(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, owner_name: ?[]const u8, fun_name: []const u8, params: []const Parser.Parameter, return_type: *const Parser.TypeExpr, receiver_name: ?[]const u8) !void {
    const needs_bridge_module = blk: {
        if (receiver_name != null) break :blk true;
        for (params) |param| {
            if (typeNeedsRuntimeBridge(param.type_expr, schema)) break :blk true;
        }
        break :blk false;
    };

    if (needs_bridge_module) {
        try writer.writeAll("        const runtime_bridge = @import(\"mzproto_bridge\");\n");
    }

    if (receiver_name) |name| {
        const owner = owner_name orelse unreachable;
        try writer.print("        const bridge_self = runtime_bridge.ConstRef{s}{{ .value = {s} }};\n", .{ owner, name });
    }

    for (params) |param| {
        const bridge_arg = try runtimeBridgeArgExprOwned(allocator, schema, param.name, param.type_expr, false);
        defer allocator.free(bridge_arg);
        try writer.print("        const bridge_{s} = {s};\n", .{ param.name, bridge_arg });
    }

    if (owner_name) |owner| {
        try writer.print("        const result = runtime_impl.Methods.{s}.{s}(", .{ owner, fun_name });
        try writer.writeAll("bridge_self");
        for (params) |param| {
            try writer.print(", bridge_{s}", .{param.name});
        }
        try writer.writeAll(");\n");
    } else {
        try writer.print("        const result = runtime_impl.Methods.global.{s}(", .{fun_name});
        var first = true;
        for (params) |param| {
            if (!first) try writer.writeAll(", ");
            first = false;
            try writer.print("bridge_{s}", .{param.name});
        }
        try writer.writeAll(");\n");
    }

    if (return_type.* == .named and utils.classifyNamed(schema, return_type.named) == .builtin_void) {
        try writer.writeAll(
            "        return switch (result) {\n" ++
                "            .ok => .{ .ok = {} },\n" ++
                "            .err => |err| .{ .err = .{ .code = err.code, .message = err.message, .owned = err.owned } },\n" ++
                "        };\n",
        );
        return;
    }

    const ok_expr = try runtimeBridgeResultExprOwned(allocator, schema, "value", return_type);
    defer allocator.free(ok_expr);
    try writer.print(
        "        return switch (result) {{\n" ++
            "            .ok => |value| .{{ .ok = {s} }},\n" ++
            "            .err => |err| .{{ .err = .{{ .code = err.code, .message = err.message, .owned = err.owned }} }},\n" ++
            "        }};\n",
        .{ok_expr},
    );
}

fn emitManualDispatch(writer: *std.Io.Writer, module_alias: []const u8, owner_name: ?[]const u8, fun_name: []const u8, params: []const Parser.Parameter, receiver_name: ?[]const u8) !void {
    if (owner_name) |name| {
        try writer.print(
            "        const __has_methods_impl = comptime @hasDecl({s}, \"Methods\") and @hasField(@TypeOf({s}.Methods), \"{s}\") and @hasDecl(@TypeOf(@field({s}.Methods, \"{s}\")), \"{s}\");\n",
            .{ module_alias, module_alias, name, module_alias, name, fun_name },
        );
        try writer.print(
            "        if (__has_methods_impl) return @field(@field({s}.Methods, \"{s}\"), \"{s}\")(",
            .{ module_alias, name, fun_name },
        );
    } else {
        try writer.print(
            "        const __has_methods_impl = comptime @hasDecl({s}, \"Methods\") and @hasField(@TypeOf({s}.Methods), \"global\") and @hasDecl(@TypeOf({s}.Methods.global), \"{s}\");\n",
            .{ module_alias, module_alias, module_alias, fun_name },
        );
        try writer.print(
            "        if (__has_methods_impl) return @field({s}.Methods.global, \"{s}\")(",
            .{ module_alias, fun_name },
        );
    }

    var first = true;
    if (receiver_name) |name| {
        try writer.writeAll(name);
        first = false;
    }
    for (params) |param| {
        if (!first) try writer.writeAll(", ");
        first = false;
        try writer.writeAll(param.name);
    }
    try writer.writeAll(");\n");

    try writer.print("        const __has_impl = comptime @hasDecl({s}, \"{s}\");\n", .{ module_alias, fun_name });
    try writer.print("        if (__has_impl) return {s}.{s}(", .{ module_alias, fun_name });
    first = true;
    if (receiver_name) |name| {
        try writer.writeAll(name);
        first = false;
    }
    for (params) |param| {
        if (!first) try writer.writeAll(", ");
        first = false;
        try writer.writeAll(param.name);
    }
    try writer.writeAll(");\n");

    try writer.writeAll("        if (comptime !(__has_methods_impl or __has_impl)) {\n");
    if (receiver_name) |name| {
        try writer.print("            ignoreUnused({s});\n", .{name});
    }
    for (params) |param| {
        try writer.print("            ignoreUnused({s});\n", .{param.name});
    }
    try writer.writeAll("        }\n");
}

fn emitStructMethod(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, decl_name: []const u8, field: Parser.Field) !void {
    const signature = field.type_expr.function;
    const return_ty = try utils.zigTypeOwned(allocator, schema, signature.return_type);
    defer allocator.free(return_ty);

    try emitDocIndented(writer, field.doc, 4);
    try writer.print("    pub fn {s}(", .{field.name});
    try emitFunctionParams(allocator, writer, schema, signature.params.items, "self: *const @This()");
    try writer.print(") Result({s}) {{\n", .{return_ty});
    try emitManualDispatch(writer, "struct_impl", decl_name, field.name, signature.params.items, "self");
    try emitOkFallback(allocator, writer, schema, signature.return_type);
    try writer.writeAll("    }\n\n");
}

fn emitTopLevelFunction(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, fun: Parser.FunctionDecl) !void {
    const return_ty = try utils.zigTypeOwned(allocator, schema, fun.return_type);
    defer allocator.free(return_ty);

    try emitDoc(writer, fun.doc);
    try writer.print("pub fn {s}(", .{fun.name});
    try emitFunctionParams(allocator, writer, schema, fun.params.items, null);
    try writer.print(") Result({s}) {{\n", .{return_ty});
    try emitRuntimeBridgeDispatch(allocator, writer, schema, null, fun.name, fun.params.items, fun.return_type, null);
    try writer.writeAll("}\n\n");
}

fn emitOpaqueMethod(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, decl_name: []const u8, fun: Parser.FunctionDecl) !void {
    const return_ty = try utils.zigTypeOwned(allocator, schema, fun.return_type);
    defer allocator.free(return_ty);

    try emitDocIndented(writer, fun.doc, 4);
    try writer.print("    pub fn {s}(", .{fun.name});
    try emitFunctionParams(allocator, writer, schema, fun.params.items, "self: *const @This()");
    try writer.print(") Result({s}) {{\n", .{return_ty});
    try emitRuntimeBridgeDispatch(allocator, writer, schema, decl_name, fun.name, fun.params.items, fun.return_type, "self");
    try writer.writeAll("    }\n\n");
}

fn emitClientMethod(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, fun: Parser.FunctionDecl) !void {
    const return_ty = try utils.zigTypeOwned(allocator, schema, fun.return_type);
    defer allocator.free(return_ty);

    try emitDocIndented(writer, fun.doc, 4);
    try writer.print("    pub fn {s}(", .{fun.name});
    try emitFunctionParams(allocator, writer, schema, fun.params.items, "self: *const @This()");
    try writer.print(") Result({s}) {{\n", .{return_ty});
    const needs_bridge_module = blk: {
        for (fun.params.items) |param| {
            if (typeNeedsRuntimeBridge(param.type_expr, schema)) break :blk true;
        }
        break :blk false;
    };
    if (needs_bridge_module) {
        try writer.writeAll("        const runtime_bridge = @import(\"mzproto_bridge\");\n");
    }

    for (fun.params.items) |param| {
        const bridge_arg = try runtimeBridgeArgExprOwned(allocator, schema, param.name, param.type_expr, false);
        defer allocator.free(bridge_arg);
        try writer.print("        const bridge_{s} = {s};\n", .{ param.name, bridge_arg });
    }

    try writer.print("        const result = runtime_impl.Methods.Client.{s}(self.ptr", .{fun.name});
    for (fun.params.items) |param| {
        try writer.print(", bridge_{s}", .{param.name});
    }
    try writer.writeAll(");\n");

    if (fun.return_type.* == .named and utils.classifyNamed(schema, fun.return_type.named) == .builtin_void) {
        try writer.writeAll(
            "        return switch (result) {\n" ++
                "            .ok => .{ .ok = {} },\n" ++
                "            .err => |err| .{ .err = .{ .code = err.code, .message = err.message, .owned = err.owned } },\n" ++
                "        };\n" ++
                "    }\n\n",
        );
        return;
    }

    const ok_expr = try runtimeBridgeResultExprOwned(allocator, schema, "value", fun.return_type);
    defer allocator.free(ok_expr);
    try writer.print(
        "        return switch (result) {{\n" ++
            "            .ok => |value| .{{ .ok = {s} }},\n" ++
            "            .err => |err| .{{ .err = .{{ .code = err.code, .message = err.message, .owned = err.owned }} }},\n" ++
            "        }};\n" ++
            "    }}\n\n",
        .{ok_expr},
    );
}

fn emitClientWrapper(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema) !void {
    var has_methods = false;
    for (schema.declarations.items) |decl| {
        switch (decl) {
            .function_decl => {
                has_methods = true;
                break;
            },
            else => {},
        }
    }
    if (!has_methods) return;

    try writer.writeAll(
        \\/// Language-native client instance. This type is not part of the schema;
        \\/// schema-level operations are projected as methods here.
        \\pub const Client = struct {
        \\    ptr: *anyopaque,
        \\
        \\    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: *const Config) !@This() {
        \\        const runtime_bridge = @import("mzproto_bridge");
        \\        const bridge_config = runtime_bridge.ConstRefConfig{ .value = @constCast(config) };
        \\        const result = runtime_impl.Methods.Client.init(allocator, io, bridge_config);
        \\        return switch (result) {
        \\            .ok => |ptr| .{ .ptr = ptr },
        \\            .err => error.MzProto,
        \\        };
        \\    }
        \\
        \\    pub fn deinit(self: *@This()) void {
        \\        if (@intFromPtr(self.ptr) == 0) return;
        \\        _ = runtime_impl.Methods.Client.deinit(self.ptr);
        \\        self.ptr = zeroPointer(*anyopaque);
        \\    }
        \\
    );

    for (schema.declarations.items) |decl| {
        switch (decl) {
            .function_decl => |fun| try emitClientMethod(allocator, writer, schema, fun),
            else => {},
        }
    }

    try writer.writeAll("};\n\n");
}

fn emitStructDecl(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, decl: Parser.StructDecl) !void {
    try emitDoc(writer, decl.doc);
    try writer.print("pub const {s} = struct {{\n", .{decl.name});

    for (decl.fields.items) |field| {
        if (field.type_expr.* == .function) continue;

        const snake = try utils.snakeCaseOwned(allocator, field.name);
        defer allocator.free(snake);
        const ty = try utils.zigTypeOwned(allocator, schema, field.type_expr);
        defer allocator.free(ty);

        try emitDocIndented(writer, field.doc, 4);

        const defaultValue = blk: {
            switch (field.type_expr.*) {
                .optional => break :blk " = null",
                .named => |name| {
                    switch (utils.classifyNamed(schema, name)) {
                        .builtin_bool => break :blk " = false",
                        else => {},
                    }
                },
                else => {},
            }

            break :blk "";
        };

        try writer.print("    {s}: {s}{s},\n", .{ snake, ty, defaultValue });
    }

    try writer.writeAll("\n    pub fn init() @This() {\n        var self: @This() = undefined;\n");
    for (decl.fields.items) |field| {
        if (field.type_expr.* == .function) continue;
        const snake = try utils.snakeCaseOwned(allocator, field.name);
        defer allocator.free(snake);
        const ty = try utils.zigTypeOwned(allocator, schema, field.type_expr);
        defer allocator.free(ty);
        try writer.print("        self.{s} = initDefault({s});\n", .{ snake, ty });
    }
    try writer.writeAll("        return self;\n    }\n\n");

    try writer.writeAll("    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {\n");
    for (decl.fields.items) |field| {
        if (field.type_expr.* == .function) continue;
        const snake = try utils.snakeCaseOwned(allocator, field.name);
        defer allocator.free(snake);
        const ty = try utils.zigTypeOwned(allocator, schema, field.type_expr);
        defer allocator.free(ty);
        try writer.print("        deinitOwnedValue({s}, &self.{s}, allocator);\n", .{ ty, snake });
    }
    try writer.writeAll("        self.* = .init();\n    }\n\n");

    for (decl.fields.items) |field| {
        if (field.type_expr.* != .function) continue;
        try emitStructMethod(allocator, writer, schema, decl.name, field);
    }

    try writer.writeAll("};\n\n");
}

fn emitEnumDecl(allocator: std.mem.Allocator, writer: *std.Io.Writer, decl: Parser.EnumDecl) !void {
    try emitDoc(writer, decl.doc);
    try writer.print("pub const {s} = enum(u32) {{\n", .{decl.name});
    for (decl.items.items) |item| {
        const snake = try utils.snakeCaseOwned(allocator, item.name);
        defer allocator.free(snake);
        try emitDocIndented(writer, item.doc, 4);
        try writer.print("    {s} = {},\n", .{ snake, item.value });
    }
    if (decl.items.items.len > 0) {
        const first = try utils.snakeCaseOwned(allocator, decl.items.items[0].name);
        defer allocator.free(first);
        try writer.print("\n    pub fn init() @This() {{\n        return .{s};\n    }}\n", .{first});
    } else {
        try writer.writeAll("\n    pub fn init() @This() {\n        return undefined;\n    }\n");
    }
    try writer.writeAll("};\n\n");
}

fn emitUnionDecl(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, decl: Parser.UnionDecl) !void {
    try emitDoc(writer, decl.doc);
    try writer.print("pub const {s} = union(enum) {{\n", .{decl.name});
    for (decl.fields.items) |field| {
        const ty = try utils.zigTypeOwned(allocator, schema, field.type_expr);
        defer allocator.free(ty);
        try emitDocIndented(writer, field.doc, 4);
        try writer.print("    {s}: {s},\n", .{ field.name, ty });
    }
    if (decl.fields.items.len > 0) {
        const first_ty = try utils.zigTypeOwned(allocator, schema, decl.fields.items[0].type_expr);
        defer allocator.free(first_ty);
        try writer.print("\n    pub fn init() @This() {{\n        return .{{ .{s} = initDefault({s}) }};\n    }}\n", .{ decl.fields.items[0].name, first_ty });
    } else {
        try writer.writeAll("\n    pub fn init() @This() {\n        return undefined;\n    }\n");
    }
    try writer.writeAll("\n    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {\n        switch (self.*) {\n");
    for (decl.fields.items) |field| {
        const ty = try utils.zigTypeOwned(allocator, schema, field.type_expr);
        defer allocator.free(ty);
        try writer.print("            .{s} => |*value| deinitOwnedValue({s}, value, allocator),\n", .{ field.name, ty });
    }
    try writer.writeAll("        }\n        self.* = .init();\n    }\n};\n\n");
}

fn emitOpaqueDecl(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema, decl: Parser.OpaqueDecl) !void {
    try emitDoc(writer, decl.doc);
    try writer.print("pub const {s} = struct {{\n    ptr: *anyopaque,\n\n    pub fn init() @This() {{\n        return .{{ .ptr = initDefault(*anyopaque) }};\n    }}\n\n    pub fn deinit(self: *@This()) void {{\n        _ = self;\n    }}\n\n", .{decl.name});
    for (decl.methods.items) |method| {
        try emitOpaqueMethod(allocator, writer, schema, decl.name, method);
    }
    try writer.writeAll("};\n\n");
}

pub fn emit(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema) !void {
    try writer.writeAll(
        \\///! mzproto - zig public api
        \\///!
        \\///! Automatically generated
        \\
        \\const std = @import("std");
        \\const struct_impl = @import("mzproto_internal_methods");
        \\const runtime_impl = @import("mzproto_internal");
        \\
        \\pub const Time = std.Io.Timestamp;
        \\pub const String = []const u8;
        \\pub const Bytes = []const u8;
        \\
        \\fn ignoreUnused(_: anytype) void {}
        \\
        \\pub const MzError = struct {
        \\    code: u32,
        \\    message: []const u8,
        \\    owned: bool = false,
        \\
        \\    pub fn deinit(self: *MzError, allocator: std.mem.Allocator) void {
        \\        if (self.owned and self.message.len > 0) allocator.free(@constCast(self.message));
        \\        self.* = undefined;
        \\    }
        \\};
        \\
        \\fn hasDeinit(comptime T: type) bool {
        \\    return switch (@typeInfo(T)) {
        \\        .@"struct", .@"union", .@"enum", .@"opaque" => @hasDecl(T, "deinit"),
        \\        else => false,
        \\    };
        \\}
        \\
        \\pub fn Result(comptime T: type) type {
        \\    return union(enum) {
        \\        ok: T,
        \\        err: MzError,
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
        \\fn zeroPointer(comptime T: type) T {
        \\    var value: T = undefined;
        \\    @memset(std.mem.asBytes(&value), 0);
        \\    return value;
        \\}
        \\
        \\fn initDefault(comptime T: type) T {
        \\    return switch (@typeInfo(T)) {
        \\        .optional => null,
        \\        .bool => false,
        \\        .int, .comptime_int => 0,
        \\        .pointer => |pointer| switch (pointer.size) {
        \\            .slice => &.{},
        \\            else => zeroPointer(T),
        \\        },
        \\        .@"struct", .@"union", .@"enum" => if (@hasDecl(T, "init")) T.init() else std.mem.zeroes(T),
        \\        else => std.mem.zeroes(T),
        \\    };
        \\}
        \\
        \\fn deinitOwnedValue(comptime T: type, value: *T, allocator: std.mem.Allocator) void {
        \\    switch (@typeInfo(T)) {
        \\        .optional => if (value.*) |*child| deinitOwnedValue(@TypeOf(child.*), child, allocator),
        \\        .pointer => |pointer| switch (pointer.size) {
        \\            .slice => {
        \\                if (value.*.len == 0) return;
        \\                if (pointer.child != u8) {
        \\                    for (value.*) |item| {
        \\                        var copy = item;
        \\                        deinitOwnedValue(@TypeOf(copy), &copy, allocator);
        \\                    }
        \\                }
        \\                allocator.free(value.*);
        \\                value.* = &.{};
        \\            },
        \\            else => {
        \\                if (@intFromPtr(value.*) == 0) return;
        \\                if (@hasDecl(pointer.child, "deinit")) {
        \\                    const ptr: *pointer.child = @constCast(value.*);
        \\                    ptr.deinit(allocator);
        \\                    allocator.destroy(ptr);
        \\                }
        \\                value.* = zeroPointer(T);
        \\            },
        \\        },
        \\        .@"struct", .@"union" => if (@hasDecl(T, "deinit")) value.deinit(allocator),
        \\        else => {},
        \\    }
        \\}
        \\
    );

    for (schema.declarations.items) |decl| {
        switch (decl) {
            .struct_decl => |value| try emitStructDecl(allocator, writer, schema, value),
            .enum_decl => |value| try emitEnumDecl(allocator, writer, value),
            .union_decl => |value| try emitUnionDecl(allocator, writer, schema, value),
            .opaque_decl => |value| try emitOpaqueDecl(allocator, writer, schema, value),
            .function_decl => {},
        }
    }

    try emitClientWrapper(allocator, writer, schema);
}
