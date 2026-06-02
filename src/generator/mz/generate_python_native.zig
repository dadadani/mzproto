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

fn pythonIdentifierOwned(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    return utils.snakeCaseOwned(allocator, name);
}

fn pythonCFunctionNameOwned(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    const pascal = try utils.pascalCaseOwned(allocator, name);
    defer allocator.free(pascal);
    return std.fmt.allocPrint(allocator, "pyClient{s}", .{pascal});
}

fn bridgeListTypeOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) ![]u8 {
    return switch (type_expr.*) {
        .reference => |child| switch (child.*) {
            .named => |name| switch (utils.classifyNamed(schema, name)) {
                .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "bapi.ConstRef{s}", .{name}),
                else => bridgeListTypeOwned(allocator, schema, child),
            },
            else => bridgeListTypeOwned(allocator, schema, child),
        },
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_bool => allocator.dupe(u8, "bool"),
            .builtin_u32 => allocator.dupe(u8, "u32"),
            .builtin_u64, .builtin_time => allocator.dupe(u8, "u64"),
            .builtin_i32 => allocator.dupe(u8, "i32"),
            .builtin_i64 => allocator.dupe(u8, "i64"),
            .builtin_string => allocator.dupe(u8, "bapi.ConstString"),
            .builtin_bytes => allocator.dupe(u8, "bapi.ConstBytes"),
            .enum_decl, .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "bapi.{s}", .{name}),
            else => try std.fmt.allocPrint(allocator, "bapi.{s}", .{name}),
        },
        else => allocator.dupe(u8, "void"),
    };
}

fn bridgeReturnTypeOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) ![]u8 {
    return switch (type_expr.*) {
        .optional => |child| blk: {
            const inner = try bridgeReturnTypeOwned(allocator, schema, child);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "?{s}", .{inner});
        },
        .reference => |child| bridgeReturnTypeOwned(allocator, schema, child),
        .list => |child| blk: {
            const inner = try bridgeListTypeOwned(allocator, schema, child);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "bapi.List({s})", .{inner});
        },
        .function => allocator.dupe(u8, "void"),
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_void => allocator.dupe(u8, "void"),
            .builtin_bool => allocator.dupe(u8, "bool"),
            .builtin_u32 => allocator.dupe(u8, "u32"),
            .builtin_u64, .builtin_time => allocator.dupe(u8, "u64"),
            .builtin_i32 => allocator.dupe(u8, "i32"),
            .builtin_i64 => allocator.dupe(u8, "i64"),
            .builtin_string => allocator.dupe(u8, "bapi.String"),
            .builtin_bytes => allocator.dupe(u8, "bapi.Bytes"),
            .enum_decl => try std.fmt.allocPrint(allocator, "bapi.{s}", .{name}),
            .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "bapi.{s}", .{name}),
            else => try std.fmt.allocPrint(allocator, "bapi.{s}", .{name}),
        },
    };
}

fn bridgeArgNeedsRoot(schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) bool {
    return switch (type_expr.*) {
        .optional => |child| bridgeArgNeedsRoot(schema, child),
        .reference => |child| switch (child.*) {
            .named => |name| switch (utils.classifyNamed(schema, name)) {
                .struct_decl, .union_decl, .opaque_decl => true,
                else => bridgeArgNeedsRoot(schema, child),
            },
            else => bridgeArgNeedsRoot(schema, child),
        },
        .list => true,
        .function => false,
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_string, .builtin_bytes, .struct_decl, .union_decl, .opaque_decl => true,
            else => false,
        },
    };
}

fn bridgeArgOwnerTypeOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) ![]u8 {
    return switch (type_expr.*) {
        .optional => |child| bridgeArgOwnerTypeOwned(allocator, schema, child),
        .reference => |child| switch (child.*) {
            .named => |name| switch (utils.classifyNamed(schema, name)) {
                .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "bapi.Ref{s}", .{name}),
                else => bridgeArgOwnerTypeOwned(allocator, schema, child),
            },
            else => bridgeArgOwnerTypeOwned(allocator, schema, child),
        },
        .list => |child| blk: {
            const inner = try bridgeListTypeOwned(allocator, schema, child);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "bapi.List({s})", .{inner});
        },
        .function => allocator.dupe(u8, "void"),
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_string => allocator.dupe(u8, "bapi.String"),
            .builtin_bytes => allocator.dupe(u8, "bapi.Bytes"),
            .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "bapi.{s}", .{name}),
            else => allocator.dupe(u8, "void"),
        },
    };
}

fn bridgeArgValueFromOwnerOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, owner_expr: []const u8, type_expr: *const Parser.TypeExpr) ![]u8 {
    return switch (type_expr.*) {
        .optional => |child| bridgeArgValueFromOwnerOwned(allocator, schema, owner_expr, child),
        .reference => |child| switch (child.*) {
            .named => |name| switch (utils.classifyNamed(schema, name)) {
                .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "{s}.toConst()", .{owner_expr}),
                else => bridgeArgValueFromOwnerOwned(allocator, schema, owner_expr, child),
            },
            else => bridgeArgValueFromOwnerOwned(allocator, schema, owner_expr, child),
        },
        .list => try std.fmt.allocPrint(allocator, "{s}.toConst()", .{owner_expr}),
        .function => allocator.dupe(u8, "{}"),
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_string, .builtin_bytes => try std.fmt.allocPrint(allocator, "{s}.toConst()", .{owner_expr}),
            .struct_decl, .union_decl, .opaque_decl => allocator.dupe(u8, owner_expr),
            else => allocator.dupe(u8, owner_expr),
        },
    };
}

fn bridgeArgExprOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, object_expr: []const u8, type_expr: *const Parser.TypeExpr) ![]u8 {
    return switch (type_expr.*) {
        .optional => |child| blk: {
            const inner = try bridgeArgExprOwned(allocator, schema, object_expr, child);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "if (pyIsNone({s})) null else {s}", .{ object_expr, inner });
        },
        .reference => |child| switch (child.*) {
            .named => |name| switch (utils.classifyNamed(schema, name)) {
                .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "bapi.ConstRef{s}.fromBorrowedObject(@ptrCast({s}))", .{ name, object_expr }),
                else => bridgeArgExprOwned(allocator, schema, object_expr, child),
            },
            else => bridgeArgExprOwned(allocator, schema, object_expr, child),
        },
        .list => |child| blk: {
            const inner = try bridgeListTypeOwned(allocator, schema, child);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "bapi.ConstList({s}).fromBorrowedObject(@ptrCast({s}))", .{ inner, object_expr });
        },
        .function => allocator.dupe(u8, "{}"),
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_bool => try std.fmt.allocPrint(allocator, "python.PyObject_IsTrue(@ptrCast({s})) != 0", .{object_expr}),
            .builtin_u32 => try std.fmt.allocPrint(allocator, "@as(u32, @intCast(python.PyLong_AsUnsignedLong(@ptrCast({s}))))", .{object_expr}),
            .builtin_u64, .builtin_time => try std.fmt.allocPrint(allocator, "@as(u64, @intCast(python.PyLong_AsUnsignedLongLong(@ptrCast({s}))))", .{object_expr}),
            .builtin_i32 => try std.fmt.allocPrint(allocator, "@as(i32, @intCast(python.PyLong_AsLong(@ptrCast({s}))))", .{object_expr}),
            .builtin_i64 => try std.fmt.allocPrint(allocator, "@as(i64, @intCast(python.PyLong_AsLongLong(@ptrCast({s}))))", .{object_expr}),
            .builtin_string => try std.fmt.allocPrint(allocator, "bapi.ConstString.fromBorrowedObject(@ptrCast({s}))", .{object_expr}),
            .builtin_bytes => try std.fmt.allocPrint(allocator, "bapi.ConstBytes.fromBorrowedObject(@ptrCast({s}))", .{object_expr}),
            .enum_decl => try std.fmt.allocPrint(allocator, "@as(bapi.{s}, @enumFromInt(python.PyLong_AsUnsignedLong(@ptrCast({s}))))", .{ name, object_expr }),
            .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "bapi.{s}.fromBorrowedObject(@ptrCast({s}))", .{ name, object_expr }),
            else => try std.fmt.allocPrint(allocator, "bapi.{s}.fromBorrowedObject(@ptrCast({s}))", .{ name, object_expr }),
        },
    };
}

fn writeIndent(writer: *std.Io.Writer, indent: usize) !void {
    for (0..indent) |_| try writer.writeByte(' ');
}

fn emitPyObjectValue(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, out_name: []const u8, value_expr: []const u8, type_expr: *const Parser.TypeExpr, indent: usize, counter: *usize) !void {
    switch (type_expr.*) {
        .optional => |child| {
            const id = counter.*;
            counter.* += 1;
            try writeIndent(writer, indent);
            try writer.print("const optional_value_{d} = {s};\n", .{ id, value_expr });
            try writeIndent(writer, indent);
            try writer.print("const {s}: ?*python.PyObject = if (optional_value_{d}) |child_value_{d}| blk: {{\n", .{ out_name, id, id });
            const child_name = try std.fmt.allocPrint(allocator, "child_object_{d}", .{id});
            defer allocator.free(child_name);
            const child_expr = try std.fmt.allocPrint(allocator, "child_value_{d}", .{id});
            defer allocator.free(child_expr);
            try emitPyObjectValue(writer, allocator, schema, child_name, child_expr, child, indent + 4, counter);
            try writeIndent(writer, indent + 4);
            try writer.print("break :blk {s};\n", .{child_name});
            try writeIndent(writer, indent);
            try writer.writeAll("} else pyNone();\n");
            try writeIndent(writer, indent);
            try writer.print("if ({s} == null) return null;\n", .{out_name});
        },
        .reference => |child| try emitPyObjectValue(writer, allocator, schema, out_name, value_expr, child, indent, counter),
        .list => |child| {
            const id = counter.*;
            counter.* += 1;
            try writeIndent(writer, indent);
            try writer.print("var owned_value_{d} = {s};\n", .{ id, value_expr });
            try writeIndent(writer, indent);
            try writer.print("const {s}: ?*python.PyObject = owned_value_{d}.resolveOwned() catch null;\n", .{ out_name, id });
            _ = child;
            try writer.print("if ({s} == null) return null;\n", .{out_name});
        },
        .function => {
            try writeIndent(writer, indent);
            try writer.print("const {s}: ?*python.PyObject = pyNone();\n", .{out_name});
        },
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_void => {
                try writeIndent(writer, indent);
                try writer.print("const {s}: ?*python.PyObject = pyNone();\n", .{out_name});
            },
            .builtin_bool => {
                try writeIndent(writer, indent);
                try writer.print("const {s}: ?*python.PyObject = @ptrCast(python.PyBool_FromLong(if ({s}) 1 else 0));\n", .{ out_name, value_expr });
                try writeIndent(writer, indent);
                try writer.print("if ({s} == null) return null;\n", .{out_name});
            },
            .builtin_u32, .builtin_u64, .builtin_time => {
                try writeIndent(writer, indent);
                try writer.print("const {s}: ?*python.PyObject = @ptrCast(python.PyLong_FromUnsignedLongLong(@intCast({s})));\n", .{ out_name, value_expr });
                try writeIndent(writer, indent);
                try writer.print("if ({s} == null) return null;\n", .{out_name});
            },
            .builtin_i32, .builtin_i64 => {
                try writeIndent(writer, indent);
                try writer.print("const {s}: ?*python.PyObject = @ptrCast(python.PyLong_FromLongLong(@intCast({s})));\n", .{ out_name, value_expr });
                try writeIndent(writer, indent);
                try writer.print("if ({s} == null) return null;\n", .{out_name});
            },
            .builtin_string => {
                const id = counter.*;
                counter.* += 1;
                try writeIndent(writer, indent);
                try writer.print("var owned_value_{d} = {s};\n", .{ id, value_expr });
                try writeIndent(writer, indent);
                try writer.print("const {s}: ?*python.PyObject = owned_value_{d}.resolveOwned() catch null;\n", .{ out_name, id });
                try writeIndent(writer, indent);
                try writer.print("if ({s} == null) return null;\n", .{out_name});
            },
            .builtin_bytes => {
                const id = counter.*;
                counter.* += 1;
                try writeIndent(writer, indent);
                try writer.print("var owned_value_{d} = {s};\n", .{ id, value_expr });
                try writeIndent(writer, indent);
                try writer.print("const {s}: ?*python.PyObject = owned_value_{d}.resolveOwned() catch null;\n", .{ out_name, id });
                try writeIndent(writer, indent);
                try writer.print("if ({s} == null) return null;\n", .{out_name});
            },
            .enum_decl => {
                try writeIndent(writer, indent);
                try writer.print("const {s}: ?*python.PyObject = pyObjectFromEnum(\"{s}\", @intFromEnum({s}));\n", .{ out_name, name, value_expr });
                try writeIndent(writer, indent);
                try writer.print("if ({s} == null) return null;\n", .{out_name});
            },
            .struct_decl, .union_decl => {
                const id = counter.*;
                counter.* += 1;
                try writeIndent(writer, indent);
                try writer.print("var owned_value_{d} = {s};\n", .{ id, value_expr });
                try writeIndent(writer, indent);
                try writer.print("const {s}: ?*python.PyObject = owned_value_{d}.resolveOwned() catch null;\n", .{ out_name, id });
                try writeIndent(writer, indent);
                try writer.print("if ({s} == null) return null;\n", .{out_name});
            },
            .opaque_decl => {
                const id = counter.*;
                counter.* += 1;
                try writeIndent(writer, indent);
                try writer.print("var owned_value_{d} = {s};\n", .{ id, value_expr });
                try writeIndent(writer, indent);
                try writer.print("const {s}: ?*python.PyObject = owned_value_{d}.resolveOwned() catch null;\n", .{ out_name, id });
                try writeIndent(writer, indent);
                try writer.print("if ({s} == null) return null;\n", .{out_name});
            },
            else => {
                const id = counter.*;
                counter.* += 1;
                try writeIndent(writer, indent);
                try writer.print("var owned_value_{d} = {s};\n", .{ id, value_expr });
                try writeIndent(writer, indent);
                try writer.print("const {s}: ?*python.PyObject = owned_value_{d}.resolveOwned() catch null;\n", .{ out_name, id });
                try writeIndent(writer, indent);
                try writer.print("if ({s} == null) return null;\n", .{out_name});
            },
        },
    }
}

fn emitReturnValue(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) !void {
    try writer.writeAll("            .ok => |value| {\n");
    var counter: usize = 0;
    try emitPyObjectValue(writer, allocator, schema, "object", "value", type_expr, 16, &counter);
    try writer.writeAll("                return object;\n            },\n");
}

fn emitResultToPyFunction(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, function_name: []const u8, type_expr: *const Parser.TypeExpr) !void {
    const return_ty = try bridgeReturnTypeOwned(allocator, schema, type_expr);
    defer allocator.free(return_ty);
    try writer.print("fn {s}ResultToPy(value: {s}) ?*python.PyObject {{\n", .{ function_name, return_ty });
    var counter: usize = 0;
    try emitPyObjectValue(writer, allocator, schema, "object", "value", type_expr, 4, &counter);
    try writer.writeAll("    return object;\n}\n\n");
}

fn emitBridgeArgsFromObjects(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, params: []const Parser.Parameter) !void {
    for (params) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        const object_name = try std.fmt.allocPrint(allocator, "{s}_object", .{name});
        defer allocator.free(object_name);
        if (bridgeArgNeedsRoot(schema, param.type_expr)) {
            const owner_ty = try bridgeArgOwnerTypeOwned(allocator, schema, param.type_expr);
            defer allocator.free(owner_ty);
            if (param.type_expr.* == .optional) {
                const owner_expr = try std.fmt.allocPrint(allocator, "bridge_{s}_owner.?", .{name});
                defer allocator.free(owner_expr);
                const bridge_expr = try bridgeArgValueFromOwnerOwned(allocator, schema, owner_expr, param.type_expr.optional);
                defer allocator.free(bridge_expr);
                try writer.print("    var bridge_{s}_owner: ?{s} = null;\n", .{ name, owner_ty });
                try writer.print("    defer if (bridge_{s}_owner) |*owner| owner.deinit(client.allocator);\n", .{name});
                try writer.print("    const bridge_{s} = if (pyIsNone({s})) null else blk: {{\n", .{ name, object_name });
                try writer.print("        bridge_{s}_owner = {s}.fromNewRef(@ptrCast({s}));\n", .{ name, owner_ty, object_name });
                try writer.print("        break :blk {s};\n", .{bridge_expr});
                try writer.writeAll("    };\n");
            } else {
                const owner_name = try std.fmt.allocPrint(allocator, "bridge_{s}_owner", .{name});
                defer allocator.free(owner_name);
                const bridge_expr = try bridgeArgValueFromOwnerOwned(allocator, schema, owner_name, param.type_expr);
                defer allocator.free(bridge_expr);
                try writer.print("    var {s} = {s}.fromNewRef(@ptrCast({s}));\n", .{ owner_name, owner_ty, object_name });
                try writer.print("    defer {s}.deinit(client.allocator);\n", .{owner_name});
                try writer.print("    const bridge_{s} = {s};\n", .{ name, bridge_expr });
            }
        } else {
            const bridge_expr = try bridgeArgExprOwned(allocator, schema, object_name, param.type_expr);
            defer allocator.free(bridge_expr);
            try writer.print("    const bridge_{s} = {s};\n", .{ name, bridge_expr });
        }
    }
}

fn emitParseTupleFormat(writer: *std.Io.Writer, count: usize) !void {
    try writer.writeByte('"');
    for (0..count) |_| try writer.writeByte('O');
    try writer.writeByte('"');
}

fn emitClientOperation(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, fun: Parser.FunctionDecl) !void {
    const py_func = try pythonCFunctionNameOwned(allocator, fun.name);
    defer allocator.free(py_func);

    try writer.print("fn {s}(_: ?*python.PyObject, args: ?*python.PyObject) callconv(.c) ?*python.PyObject {{\n", .{py_func});
    try writer.writeAll("    var handle: ?*python.PyObject = null;\n");
    for (fun.params.items) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        try writer.print("    var {s}_object: ?*python.PyObject = null;\n", .{name});
    }
    try writer.writeAll("\n    if (python.PyArg_ParseTuple(args, ");
    try emitParseTupleFormat(writer, fun.params.items.len + 1);
    try writer.writeAll(", &handle");
    for (fun.params.items) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        try writer.print(", &{s}_object", .{name});
    }
    try writer.writeAll(") == 0) {\n        return null;\n    }\n\n");
    try writer.writeAll("    const client = nativeClientFromHandle(handle) orelse return null;\n");
    if (std.mem.eql(u8, fun.name, "terminate")) {
        try writer.writeAll(
            "    _ = client;\n" ++
                "    const handle_object = clientHandleFromObject(handle) orelse return null;\n" ++
                "    closeClientHandle(handle_object, true) catch {\n" ++
                "        setNativeError(\"failed to terminate mzproto client\");\n" ++
                "        return null;\n" ++
                "    };\n" ++
                "    return pyNone();\n" ++
                "}\n\n",
        );
        return;
    }

    for (fun.params.items) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        const object_name = try std.fmt.allocPrint(allocator, "{s}_object", .{name});
        defer allocator.free(object_name);
        if (bridgeArgNeedsRoot(schema, param.type_expr)) {
            const owner_ty = try bridgeArgOwnerTypeOwned(allocator, schema, param.type_expr);
            defer allocator.free(owner_ty);
            if (param.type_expr.* == .optional) {
                const owner_expr = try std.fmt.allocPrint(allocator, "bridge_{s}_owner.?", .{name});
                defer allocator.free(owner_expr);
                const bridge_expr = try bridgeArgValueFromOwnerOwned(allocator, schema, owner_expr, param.type_expr.optional);
                defer allocator.free(bridge_expr);
                try writer.print("    var bridge_{s}_owner: ?{s} = null;\n", .{ name, owner_ty });
                try writer.print("    defer if (bridge_{s}_owner) |*owner| owner.deinit(client.allocator);\n", .{name});
                try writer.print("    const bridge_{s} = if (pyIsNone({s})) null else blk: {{\n", .{ name, object_name });
                try writer.print("        bridge_{s}_owner = {s}.fromNewRef(@ptrCast({s}));\n", .{ name, owner_ty, object_name });
                try writer.print("        break :blk {s};\n", .{bridge_expr});
                try writer.writeAll("    };\n");
            } else {
                const owner_name = try std.fmt.allocPrint(allocator, "bridge_{s}_owner", .{name});
                defer allocator.free(owner_name);
                const bridge_expr = try bridgeArgValueFromOwnerOwned(allocator, schema, owner_name, param.type_expr);
                defer allocator.free(bridge_expr);
                try writer.print("    var {s} = {s}.fromNewRef(@ptrCast({s}));\n", .{ owner_name, owner_ty, object_name });
                try writer.print("    defer {s}.deinit(client.allocator);\n", .{owner_name});
                try writer.print("    const bridge_{s} = {s};\n", .{ name, bridge_expr });
            }
        } else {
            const bridge_expr = try bridgeArgExprOwned(allocator, schema, object_name, param.type_expr);
            defer allocator.free(bridge_expr);
            try writer.print("    const bridge_{s} = {s};\n", .{ name, bridge_expr });
        }
    }

    try writer.print("    const result = runtime_impl.Methods.Client.{s}(client.ptr", .{fun.name});
    for (fun.params.items) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        try writer.print(", bridge_{s}", .{name});
    }
    try writer.writeAll(");\n");

    try writer.writeAll("    switch (result) {\n");
    try emitReturnValue(writer, allocator, schema, fun.return_type);
    try writer.writeAll("        .err => |err| { setNativeMzError(err); return null; },\n    }\n}\n\n");
}

fn emitAsyncClientOperation(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, fun: Parser.FunctionDecl) !void {
    const py_func = try pythonCFunctionNameOwned(allocator, fun.name);
    defer allocator.free(py_func);

    try emitResultToPyFunction(writer, allocator, schema, py_func, fun.return_type);

    try writer.print("fn {s}AsyncWorker(client: *NativeClient, handle: ?*python.PyObject, loop: ?*python.PyObject, future: ?*python.PyObject", .{py_func});
    for (fun.params.items) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        try writer.print(", {s}_object: ?*python.PyObject", .{name});
    }
    try writer.writeAll(") std.Io.Cancelable!void {\n");
    try writer.writeAll("    defer pyDecref(handle);\n    defer pyDecref(loop);\n    defer pyDecref(future);\n");
    for (fun.params.items) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        try writer.print("    defer pyDecref({s}_object);\n", .{name});
    }
    try emitBridgeArgsFromObjects(writer, allocator, schema, fun.params.items);
    try writer.print("    const result = runtime_impl.Methods.Client.{s}(client.ptr", .{fun.name});
    for (fun.params.items) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        try writer.print(", bridge_{s}", .{name});
    }
    try writer.writeAll(");\n");
    try writer.writeAll("    switch (result) {\n");
    try writer.print("        .ok => |value| {{\n            const state = python.PyGILState_Ensure();\n            const object = {s}ResultToPy(value);\n            python.PyGILState_Release(state);\n            if (object == null) {{\n                scheduleFutureRuntimeError(loop, future, \"failed to convert mzproto result\");\n                return;\n            }}\n            scheduleFutureResult(loop, future, object);\n        }},\n", .{py_func});
    try writer.writeAll("        .err => |err| {\n            const exception = createMzExceptionOwned(err) orelse {\n                scheduleFutureRuntimeError(loop, future, \"mzproto error\");\n                return;\n            };\n            scheduleFutureExceptionObject(loop, future, exception);\n        },\n    }\n}\n\n");

    try writer.print("fn {s}(_: ?*python.PyObject, args: ?*python.PyObject) callconv(.c) ?*python.PyObject {{\n", .{py_func});
    try writer.writeAll("    var handle: ?*python.PyObject = null;\n");
    for (fun.params.items) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        try writer.print("    var {s}_object: ?*python.PyObject = null;\n", .{name});
    }
    try writer.writeAll("\n    if (python.PyArg_ParseTuple(args, ");
    try emitParseTupleFormat(writer, fun.params.items.len + 1);
    try writer.writeAll(", &handle");
    for (fun.params.items) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        try writer.print(", &{s}_object", .{name});
    }
    try writer.writeAll(") == 0) {\n        return null;\n    }\n\n");
    try writer.writeAll("    const client = nativeClientFromHandle(handle) orelse return null;\n");
    try writer.writeAll("    var loop: ?*python.PyObject = null;\n    const future = createAsyncioFutureOwned(&loop) orelse return null;\n");
    try writer.writeAll("    const handle_ref = pyNewRef(handle);\n    const future_ref = pyNewRef(future);\n");
    for (fun.params.items) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        try writer.print("    const {s}_ref = pyNewRef({s}_object);\n", .{ name, name });
    }
    try writer.print("    client.async_group.concurrent(client.io.io(), {s}AsyncWorker, .{{ client, handle_ref, loop, future_ref", .{py_func});
    for (fun.params.items) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        try writer.print(", {s}_ref", .{name});
    }
    try writer.writeAll(" }) catch {\n");
    try writer.writeAll("        pyDecref(handle_ref);\n        pyDecref(loop);\n        pyDecref(future_ref);\n");
    for (fun.params.items) |param| {
        const name = try pythonIdentifierOwned(allocator, param.name);
        defer allocator.free(name);
        try writer.print("        pyDecref({s}_ref);\n", .{name});
    }
    try writer.writeAll("        pyDecref(future);\n        setNativeError(\"mzproto async concurrency unavailable\");\n        return null;\n    };\n");
    try writer.writeAll("    return future;\n}\n\n");
}

fn emitMethodDef(writer: *std.Io.Writer, allocator: std.mem.Allocator, name: []const u8, py_func: []const u8, doc: []const u8) !void {
    const native_name = try pythonIdentifierOwned(allocator, name);
    defer allocator.free(native_name);
    try writer.print(
        "    .{{\n" ++
            "        .ml_name = \"{s}\",\n" ++
            "        .ml_meth = @ptrCast(&{s}),\n" ++
            "        .ml_flags = python.METH_VARARGS,\n" ++
            "        .ml_doc = \"{s}\",\n" ++
            "    }},\n",
        .{ native_name, py_func, doc },
    );
}

pub fn emit(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema) !void {
    try writer.writeAll(
        \\///! mzproto Python native extension.
        \\///!
        \\///! Automatically generated.
        \\
        \\const std = @import("std");
        \\const python = @import("python");
        \\const runtime_impl = @import("mzproto_internal");
        \\const bapi = @import("mzproto_bridge");
        \\
        \\const NativeClient = struct {
        \\    io: std.Io.Threaded,
        \\    allocator: std.mem.Allocator,
        \\    async_group: std.Io.Group,
        \\    ptr: *anyopaque,
        \\};
        \\
        \\const ClientHandleObject = extern struct {
        \\    ob_base: python.PyObject,
        \\    client: ?*NativeClient,
        \\    closed: c_int,
        \\};
        \\
        \\var client_handle_type: ?*python.PyTypeObject = null;
        \\
        \\fn pyDecref(object: ?*python.PyObject) void {
        \\    if (object == null) return;
        \\    const state = python.PyGILState_Ensure();
        \\    defer python.PyGILState_Release(state);
        \\    python.Py_DecRef(@ptrCast(object));
        \\}
        \\
        \\fn pyNewRef(object: ?*python.PyObject) ?*python.PyObject {
        \\    if (object == null) return null;
        \\    const state = python.PyGILState_Ensure();
        \\    defer python.PyGILState_Release(state);
        \\    return @ptrCast(python.Py_NewRef(@ptrCast(object)));
        \\}
        \\
        \\fn pyNone() ?*python.PyObject {
        \\    return @ptrCast(python.Py_GetConstant(@intCast(python.Py_CONSTANT_NONE)));
        \\}
        \\
        \\fn pyIsNone(object: ?*python.PyObject) bool {
        \\    return object == null or python.Py_IsNone(@ptrCast(object)) != 0;
        \\}
        \\
        \\fn setNativeError(message: [*:0]const u8) void {
        \\    python.PyErr_SetString(python.PyExc_RuntimeError, message);
        \\}
        \\
        \\fn createAsyncioFutureOwned(loop_out: *?*python.PyObject) ?*python.PyObject {
        \\    loop_out.* = null;
        \\    const module = python.PyImport_ImportModule("asyncio");
        \\    if (module == null) return null;
        \\    defer pyDecref(@ptrCast(module));
        \\
        \\    const get_loop = python.PyObject_GetAttrString(module, "get_running_loop");
        \\    if (get_loop == null) return null;
        \\    defer pyDecref(@ptrCast(get_loop));
        \\
        \\    const loop = python.PyObject_CallNoArgs(get_loop);
        \\    if (loop == null) return null;
        \\
        \\    const create_future = python.PyObject_GetAttrString(loop, "create_future");
        \\    if (create_future == null) {
        \\        pyDecref(@ptrCast(loop));
        \\        return null;
        \\    }
        \\    defer pyDecref(@ptrCast(create_future));
        \\
        \\    const future = python.PyObject_CallNoArgs(create_future);
        \\    if (future == null) {
        \\        pyDecref(@ptrCast(loop));
        \\        return null;
        \\    }
        \\    loop_out.* = @ptrCast(loop);
        \\    return @ptrCast(future);
        \\}
        \\
        \\fn createMzExceptionOwned(err: bapi.MzError) ?*python.PyObject {
        \\    const state = python.PyGILState_Ensure();
        \\    defer python.PyGILState_Release(state);
        \\    const class = bapi.getPublicClassOwned("MzException") orelse return null;
        \\    defer pyDecref(class);
        \\
        \\    const args: ?*python.PyObject = @ptrCast(python.PyTuple_New(2));
        \\    if (args == null) return null;
        \\    defer pyDecref(args);
        \\
        \\    const code: ?*python.PyObject = @ptrCast(python.PyLong_FromUnsignedLong(@intCast(err.code)));
        \\    if (!tupleSetOwned(args, 0, code)) return null;
        \\    const message: ?*python.PyObject = @ptrCast(python.PyUnicode_FromStringAndSize(@ptrCast(err.message.ptr), @intCast(err.message.len)));
        \\    if (!tupleSetOwned(args, 1, message)) return null;
        \\
        \\    return @ptrCast(python.PyObject_CallObject(@ptrCast(class), @ptrCast(args)));
        \\}
        \\
        \\fn callOneArgOwned(callable: ?*python.PyObject, arg: ?*python.PyObject) ?*python.PyObject {
        \\    if (callable == null or arg == null) return null;
        \\    const args: ?*python.PyObject = @ptrCast(python.PyTuple_New(1));
        \\    if (args == null) return null;
        \\    defer pyDecref(args);
        \\    const arg_ref = pyNewRef(arg);
        \\    if (arg_ref == null) return null;
        \\    if (python.PyTuple_SetItem(@ptrCast(args), 0, @ptrCast(arg_ref)) != 0) {
        \\        pyDecref(arg_ref);
        \\        return null;
        \\    }
        \\    return @ptrCast(python.PyObject_CallObject(@ptrCast(callable), @ptrCast(args)));
        \\}
        \\
        \\fn scheduleFutureCall(loop: ?*python.PyObject, future: ?*python.PyObject, method_name: [*:0]const u8, arg_owned: ?*python.PyObject) void {
        \\    if (loop == null or future == null or arg_owned == null) {
        \\        pyDecref(arg_owned);
        \\        return;
        \\    }
        \\    const state = python.PyGILState_Ensure();
        \\    defer python.PyGILState_Release(state);
        \\
        \\    const call_soon = python.PyObject_GetAttrString(@ptrCast(loop), "call_soon_threadsafe");
        \\    if (call_soon == null) {
        \\        python.PyErr_Clear();
        \\        pyDecref(arg_owned);
        \\        return;
        \\    }
        \\    defer pyDecref(@ptrCast(call_soon));
        \\
        \\    const callback = python.PyObject_GetAttrString(@ptrCast(future), method_name);
        \\    if (callback == null) {
        \\        python.PyErr_Clear();
        \\        pyDecref(arg_owned);
        \\        return;
        \\    }
        \\
        \\    const args: ?*python.PyObject = @ptrCast(python.PyTuple_New(2));
        \\    if (args == null) {
        \\        pyDecref(@ptrCast(callback));
        \\        pyDecref(arg_owned);
        \\        return;
        \\    }
        \\    defer pyDecref(args);
        \\    if (python.PyTuple_SetItem(@ptrCast(args), 0, callback) != 0) {
        \\        pyDecref(@ptrCast(callback));
        \\        pyDecref(arg_owned);
        \\        return;
        \\    }
        \\    if (python.PyTuple_SetItem(@ptrCast(args), 1, @ptrCast(arg_owned)) != 0) {
        \\        pyDecref(arg_owned);
        \\        return;
        \\    }
        \\    const result = python.PyObject_CallObject(@ptrCast(call_soon), @ptrCast(args));
        \\    if (result == null) {
        \\        python.PyErr_Clear();
        \\        return;
        \\    }
        \\    pyDecref(@ptrCast(result));
        \\}
        \\
        \\fn scheduleFutureResult(loop: ?*python.PyObject, future: ?*python.PyObject, result_owned: ?*python.PyObject) void {
        \\    scheduleFutureCall(loop, future, "set_result", result_owned);
        \\}
        \\
        \\fn scheduleFutureExceptionObject(loop: ?*python.PyObject, future: ?*python.PyObject, exception_owned: ?*python.PyObject) void {
        \\    scheduleFutureCall(loop, future, "set_exception", exception_owned);
        \\}
        \\
        \\fn scheduleFutureRuntimeError(loop: ?*python.PyObject, future: ?*python.PyObject, message: []const u8) void {
        \\    const state = python.PyGILState_Ensure();
        \\    const class = python.PyExc_RuntimeError;
        \\    const args: ?*python.PyObject = @ptrCast(python.PyTuple_New(1));
        \\    if (args == null) {
        \\        python.PyErr_Clear();
        \\        python.PyGILState_Release(state);
        \\        return;
        \\    }
        \\    const text: ?*python.PyObject = @ptrCast(python.PyUnicode_FromStringAndSize(@ptrCast(message.ptr), @intCast(message.len)));
        \\    if (!tupleSetOwned(args, 0, text)) {
        \\        pyDecref(args);
        \\        python.PyErr_Clear();
        \\        python.PyGILState_Release(state);
        \\        return;
        \\    }
        \\    const exception: ?*python.PyObject = @ptrCast(python.PyObject_CallObject(class, @ptrCast(args)));
        \\    pyDecref(args);
        \\    if (exception == null) python.PyErr_Clear();
        \\    python.PyGILState_Release(state);
        \\    scheduleFutureExceptionObject(loop, future, exception);
        \\}
        \\
        \\fn callPublicClass(name: [:0]const u8, args: ?*python.PyObject) ?*python.PyObject {
        \\    const class = bapi.getPublicClassOwned(name) orelse return null;
        \\    defer pyDecref(class);
        \\    return @ptrCast(python.PyObject_CallObject(@ptrCast(class), @ptrCast(args)));
        \\}
        \\
        \\fn tupleSetOwned(tuple: ?*python.PyObject, index: usize, item: ?*python.PyObject) bool {
        \\    if (item == null) {
        \\        return false;
        \\    }
        \\    if (python.PyTuple_SetItem(@ptrCast(tuple), @intCast(index), @ptrCast(item)) != 0) {
        \\        return false;
        \\    }
        \\    return true;
        \\}
        \\
        \\fn setNativeMzError(err: bapi.MzError) void {
        \\    const class = bapi.getPublicClassOwned("MzException") orelse {
        \\        setNativeError("mzproto error");
        \\        return;
        \\    };
        \\    defer pyDecref(class);
        \\
        \\    const args: ?*python.PyObject = @ptrCast(python.PyTuple_New(2));
        \\    if (args == null) {
        \\        setNativeError("mzproto error");
        \\        return;
        \\    }
        \\    defer pyDecref(args);
        \\
        \\    const code: ?*python.PyObject = @ptrCast(python.PyLong_FromUnsignedLong(@intCast(err.code)));
        \\    if (!tupleSetOwned(args, 0, code)) {
        \\        setNativeError("mzproto error");
        \\        return;
        \\    }
        \\    const message: ?*python.PyObject = @ptrCast(python.PyUnicode_FromStringAndSize(@ptrCast(err.message.ptr), @intCast(err.message.len)));
        \\    if (!tupleSetOwned(args, 1, message)) {
        \\        setNativeError("mzproto error");
        \\        return;
        \\    }
        \\
        \\    const instance: ?*python.PyObject = @ptrCast(python.PyObject_CallObject(@ptrCast(class), @ptrCast(args)));
        \\    if (instance == null) {
        \\        setNativeError("mzproto error");
        \\        return;
        \\    }
        \\    defer pyDecref(instance);
        \\    python.PyErr_SetObject(@ptrCast(class), @ptrCast(instance));
        \\}
        \\
        \\fn pyObjectFromEnum(class_name: [:0]const u8, value: u64) ?*python.PyObject {
        \\    const args: ?*python.PyObject = @ptrCast(python.PyTuple_New(1));
        \\    if (args == null) return null;
        \\    defer pyDecref(args);
        \\    const item: ?*python.PyObject = @ptrCast(python.PyLong_FromUnsignedLongLong(@intCast(value)));
        \\    if (!tupleSetOwned(args, 0, item)) return null;
        \\    return callPublicClass(class_name, args);
        \\}
        \\
        \\fn cancelClientAsyncGroupAllowThreads(client: *NativeClient) void {
        \\    const thread_state = python.PyEval_SaveThread();
        \\    defer python.PyEval_RestoreThread(thread_state);
        \\    client.async_group.cancel(client.io.io());
        \\}
        \\
        \\fn destroyNativeClient(client: *NativeClient, comptime terminate: bool) !void {
        \\    cancelClientAsyncGroupAllowThreads(client);
        \\    const result = if (terminate) runtime_impl.Methods.Client.terminate(client.ptr) else runtime_impl.Methods.Client.deinit(client.ptr);
        \\    client.io.deinit();
        \\    python.PyMem_Free(client);
        \\    switch (result) {
        \\        .ok => {},
        \\        .err => return error.MzProto,
        \\    }
        \\}
        \\
        \\fn clientHandleDealloc(object: [*c]python.PyObject) callconv(.c) void {
        \\    var handle: *ClientHandleObject = @ptrCast(@alignCast(object));
        \\    if (handle.client) |client| {
        \\        _ = destroyNativeClient(client, false) catch {};
        \\        handle.client = null;
        \\    }
        \\    handle.closed = 1;
        \\
        \\    const type_obj = python.Py_TYPE(object);
        \\    const free_slot = python.PyType_GetSlot(type_obj, python.Py_tp_free) orelse {
        \\        python.PyObject_Free(object);
        \\        return;
        \\    };
        \\    const free_fn: python.freefunc = @ptrCast(@alignCast(free_slot));
        \\    free_fn.?(@ptrCast(object));
        \\}
        \\
        \\fn pyHandleFromNativeClient(client: *NativeClient) ?*python.PyObject {
        \\    const type_obj = client_handle_type orelse {
        \\        setNativeError("mzproto ClientHandle type is not initialized");
        \\        return null;
        \\    };
        \\    const object = python.PyType_GenericAlloc(type_obj, 0);
        \\    if (object == null) return null;
        \\    const handle: *ClientHandleObject = @ptrCast(@alignCast(object));
        \\    handle.client = client;
        \\    handle.closed = 0;
        \\    return @ptrCast(object);
        \\}
        \\
        \\fn clientHandleFromObject(object: ?*python.PyObject) ?*ClientHandleObject {
        \\    const type_obj = client_handle_type orelse {
        \\        setNativeError("mzproto ClientHandle type is not initialized");
        \\        return null;
        \\    };
        \\    if (object == null or python.PyObject_TypeCheck(@ptrCast(object), type_obj) == 0) {
        \\        setNativeError("expected mzproto._native.ClientHandle");
        \\        return null;
        \\    }
        \\    return @ptrCast(@alignCast(object));
        \\}
        \\
        \\fn nativeClientFromHandle(object: ?*python.PyObject) ?*NativeClient {
        \\    const handle = clientHandleFromObject(object) orelse return null;
        \\    if (handle.closed != 0 or handle.client == null) {
        \\        setNativeError("mzproto client handle is closed");
        \\        return null;
        \\    }
        \\    return handle.client.?;
        \\}
        \\
        \\fn closeClientHandle(handle: *ClientHandleObject, comptime terminate: bool) !void {
        \\    if (handle.closed != 0 or handle.client == null) return error.Closed;
        \\    const client = handle.client.?;
        \\    handle.client = null;
        \\    handle.closed = 1;
        \\    try destroyNativeClient(client, terminate);
        \\}
        \\
        \\
        \\
        \\
        \\fn pyClientInit(_: ?*python.PyObject, args: ?*python.PyObject) callconv(.c) ?*python.PyObject {
        \\    var config_object: ?*python.PyObject = null;
        \\
        \\    if (python.PyArg_ParseTuple(args, "O", &config_object) == 0) {
        \\        return null;
        \\    }
        \\
        \\    const client_memory = python.PyMem_Malloc(@sizeOf(NativeClient)) orelse {
        \\        setNativeError("failed to allocate mzproto client wrapper");
        \\        return null;
        \\    };
        \\    const client: *NativeClient = @ptrCast(@alignCast(client_memory));
        \\
        \\
        \\    client.allocator = std.heap.smp_allocator;
        \\    client.io = std.Io.Threaded.init(client.allocator, .{});
        \\    client.async_group = .init;
        \\
        \\    var bridge_config_ref = bapi.RefConfig.fromNewRef(@ptrCast(config_object));
        \\    defer bridge_config_ref.deinit(client.allocator);
        \\    const bridge_config = bridge_config_ref.toConst();
        \\    client.ptr = switch (runtime_impl.Methods.Client.init(client.allocator, client.io.io(), bridge_config)) {
        \\        .ok => |ptr| ptr,
        \\        .err => |err| {
        \\            client.io.deinit();
        \\            python.PyMem_Free(client);
        \\            setNativeMzError(err);
        \\            return null;
        \\        },
        \\    };
        \\
        \\    return pyHandleFromNativeClient(client) orelse {
        \\        _ = destroyNativeClient(client, false) catch {};
        \\        setNativeError("failed to allocate mzproto client handle");
        \\        return null;
        \\    };
        \\}
        \\
        \\fn pyClientDeinit(_: ?*python.PyObject, args: ?*python.PyObject) callconv(.c) ?*python.PyObject {
        \\    var handle: ?*python.PyObject = null;
        \\
        \\    if (python.PyArg_ParseTuple(args, "O", &handle) == 0) {
        \\        return null;
        \\    }
        \\
        \\    const handle_object = clientHandleFromObject(handle) orelse return null;
        \\    closeClientHandle(handle_object, false) catch {
        \\        setNativeError("failed to deinitialize mzproto client");
        \\        return null;
        \\    };
        \\
        \\    return pyNone();
        \\}
        \\
    );

    for (schema.declarations.items) |decl| {
        switch (decl) {
            .function_decl => |fun| if (fun.mode == .asynchronous) try emitAsyncClientOperation(writer, allocator, schema, fun) else try emitClientOperation(writer, allocator, schema, fun),
            else => {},
        }
    }

    try writer.writeAll("const methods = [_]python.PyMethodDef{\n");
    try emitMethodDef(writer, allocator, "client_init", "pyClientInit", "Create a native mzproto client and return an internal handle.");
    try emitMethodDef(writer, allocator, "client_deinit", "pyClientDeinit", "Destroy a native mzproto client handle.");
    for (schema.declarations.items) |decl| {
        switch (decl) {
            .function_decl => |fun| {
                const native_name = try pythonIdentifierOwned(allocator, fun.name);
                defer allocator.free(native_name);
                const py_func = try pythonCFunctionNameOwned(allocator, fun.name);
                defer allocator.free(py_func);
                const method_name = try std.fmt.allocPrint(allocator, "client_{s}", .{native_name});
                defer allocator.free(method_name);
                try emitMethodDef(writer, allocator, method_name, py_func, "Invoke a schema-defined mzproto client operation.");
            },
            else => {},
        }
    }
    try writer.writeAll(
        \\    std.mem.zeroes(python.PyMethodDef),
        \\};
        \\
        \\var client_handle_slots = [_]python.PyType_Slot{
        \\    .{ .slot = python.Py_tp_dealloc, .pfunc = @constCast(@ptrCast(&clientHandleDealloc)) },
        \\    .{ .slot = 0, .pfunc = null },
        \\};
        \\
        \\var client_handle_spec = python.PyType_Spec{
        \\    .name = "mzproto._native.ClientHandle",
        \\    .basicsize = @intCast(@sizeOf(ClientHandleObject)),
        \\    .itemsize = 0,
        \\    .flags = @intCast(python.Py_TPFLAGS_DEFAULT | python.Py_TPFLAGS_DISALLOW_INSTANTIATION),
        \\    .slots = &client_handle_slots,
        \\};
        \\
        \\var module_def = std.mem.zeroInit(python.PyModuleDef, .{
        \\    .m_name = "mzproto._native",
        \\    .m_doc = "mzproto native Python functions.",
        \\    .m_size = @as(python.Py_ssize_t, -1),
        \\    .m_methods = @constCast(&methods[0]),
        \\});
        \\
        \\pub export fn PyInit__native() callconv(.c) ?*python.PyObject {
        \\    const module = python.PyModule_Create2(&module_def, python.PYTHON_ABI_VERSION);
        \\    if (module == null) return null;
        \\
        \\    const handle_type_object = python.PyType_FromSpec(&client_handle_spec);
        \\    if (handle_type_object == null) {
        \\        python.Py_DecRef(module);
        \\        return null;
        \\    }
        \\    client_handle_type = @ptrCast(@alignCast(handle_type_object));
        \\    if (python.PyModule_AddObject(module, "ClientHandle", handle_type_object) != 0) {
        \\        client_handle_type = null;
        \\        python.Py_DecRef(handle_type_object);
        \\        python.Py_DecRef(module);
        \\        return null;
        \\    }
        \\
        \\    return @ptrCast(module);
        \\}
        \\
    );
}
