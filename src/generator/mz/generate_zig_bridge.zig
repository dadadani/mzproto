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

fn getterTypeOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr, comptime is_const: bool) ![]u8 {
    return switch (type_expr.*) {
        .optional => |child| blk: {
            const inner = try getterTypeOwned(allocator, schema, child, is_const);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "?{s}", .{inner});
        },
        .reference => |child| switch (child.*) {
            .named => |name| switch (utils.classifyNamed(schema, name)) {
                .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "{s}{s}", .{ if (is_const) "ConstRef" else "Ref", name }),
                else => try getterTypeOwned(allocator, schema, child, is_const),
            },
            else => try getterTypeOwned(allocator, schema, child, is_const),
        },
        .list => |child| blk: {
            const inner = try getterTypeOwned(allocator, schema, child, is_const);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "{s}List({s})", .{ if (is_const) "Const" else "", inner });
        },
        .function => allocator.dupe(u8, "void"),
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_bool => allocator.dupe(u8, "bool"),
            .builtin_u32 => allocator.dupe(u8, "u32"),
            .builtin_u64 => allocator.dupe(u8, "u64"),
            .builtin_i32 => allocator.dupe(u8, "i32"),
            .builtin_i64 => allocator.dupe(u8, "i64"),
            .builtin_time => allocator.dupe(u8, "u64"),
            .builtin_string => allocator.dupe(u8, if (is_const) "ConstString" else "String"),
            .builtin_bytes => allocator.dupe(u8, if (is_const) "ConstBytes" else "Bytes"),
            .enum_decl, .struct_decl, .union_decl, .opaque_decl => allocator.dupe(u8, name),
            else => allocator.dupe(u8, name),
        },
    };
}

fn setterTypeOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) ![]u8 {
    return switch (type_expr.*) {
        .optional => |child| blk: {
            const inner = try setterTypeOwned(allocator, schema, child);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "?{s}", .{inner});
        },
        .reference => |child| switch (child.*) {
            .named => |name| switch (utils.classifyNamed(schema, name)) {
                .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "Ref{s}", .{name}),
                else => try setterTypeOwned(allocator, schema, child),
            },
            else => try setterTypeOwned(allocator, schema, child),
        },
        .list => |child| blk: {
            const inner = try setterTypeOwned(allocator, schema, child);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "List({s})", .{inner});
        },
        .function => allocator.dupe(u8, "void"),
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_bool => allocator.dupe(u8, "bool"),
            .builtin_u32 => allocator.dupe(u8, "u32"),
            .builtin_u64 => allocator.dupe(u8, "u64"),
            .builtin_i32 => allocator.dupe(u8, "i32"),
            .builtin_i64 => allocator.dupe(u8, "i64"),
            .builtin_time => allocator.dupe(u8, "u64"),
            .builtin_string => allocator.dupe(u8, "String"),
            .builtin_bytes => allocator.dupe(u8, "Bytes"),
            .enum_decl, .struct_decl, .union_decl, .opaque_decl => allocator.dupe(u8, name),
            else => allocator.dupe(u8, name),
        },
    };
}

fn getterExprOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, expr: []const u8, type_expr: *const Parser.TypeExpr, comptime is_const: bool) ![]u8 {
    return switch (type_expr.*) {
        .optional => |child| blk: {
            const inner = try getterExprOwned(allocator, schema, "value", child, is_const);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "if ({s}) |value| {s} else null", .{ expr, inner });
        },
        .reference => |child| switch (child.*) {
            .named => |name| switch (utils.classifyNamed(schema, name)) {
                .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, ".{{ .value = {s} }}", .{expr}),
                else => try getterExprOwned(allocator, schema, expr, child, is_const),
            },
            else => try getterExprOwned(allocator, schema, expr, child, is_const),
        },
        .list => |child| blk: {
            const inner = try getterTypeOwned(allocator, schema, child, is_const);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "{s}List({s}){{ .slice = @constCast({s}) }}", .{ if (is_const) "Const" else "", inner, expr });
        },
        .function => allocator.dupe(u8, expr),
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_string => try std.fmt.allocPrint(allocator, "{s}String{{ .slice = @constCast({s}) }}", .{ if (is_const) "Const" else "", expr }),
            .builtin_bytes => try std.fmt.allocPrint(allocator, "{s}Bytes{{ .slice = @constCast({s}) }}", .{ if (is_const) "Const" else "", expr }),
            .builtin_time => try std.fmt.allocPrint(allocator, "@as(u64, @intCast({s}.nanoseconds))", .{expr}),
            .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, ".{{ .value = {s} }}", .{expr}),
            else => allocator.dupe(u8, expr),
        },
    };
}

fn setterExprOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, expr: []const u8, type_expr: *const Parser.TypeExpr) ![]u8 {
    return switch (type_expr.*) {
        .optional => |child| blk: {
            const inner = try setterExprOwned(allocator, schema, "v", child);
            defer allocator.free(inner);
            break :blk try std.fmt.allocPrint(allocator, "if ({s}) |v| {s} else null", .{ expr, inner });
        },
        .reference => |child| switch (child.*) {
            .named => |name| switch (utils.classifyNamed(schema, name)) {
                .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "{s}.value", .{expr}),
                else => try setterExprOwned(allocator, schema, expr, child),
            },
            else => try setterExprOwned(allocator, schema, expr, child),
        },
        .list => try std.fmt.allocPrint(allocator, "{s}.slice", .{expr}),
        .function => allocator.dupe(u8, expr),
        .named => |name| switch (utils.classifyNamed(schema, name)) {
            .builtin_string, .builtin_bytes => try std.fmt.allocPrint(allocator, "{s}.slice", .{expr}),
            .builtin_time => try std.fmt.allocPrint(allocator, ".{{ .nanoseconds = @as(i128, @intCast({s})) }}", .{expr}),
            .struct_decl, .union_decl, .opaque_decl => try std.fmt.allocPrint(allocator, "{s}.value", .{expr}),
            else => allocator.dupe(u8, expr),
        },
    };
}

fn emitGetters(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, fields: []const Parser.Field, self_expr: []const u8, indent: []const u8, comptime is_const: bool) !void {
    for (fields) |field| {
        if (field.type_expr.* == .function) continue;
        const suffix = try utils.pascalCaseOwned(allocator, field.name);
        defer allocator.free(suffix);
        const snake = try utils.snakeCaseOwned(allocator, field.name);
        defer allocator.free(snake);
        const return_ty = try getterTypeOwned(allocator, schema, field.type_expr, is_const);
        defer allocator.free(return_ty);
        const field_expr = try std.fmt.allocPrint(allocator, "{s}.{s}", .{ self_expr, snake });
        defer allocator.free(field_expr);
        const wrapped = try getterExprOwned(allocator, schema, field_expr, field.type_expr, is_const);
        defer allocator.free(wrapped);
        try writer.print("{s}pub inline fn get{s}(self: *const @This()) {s} {{\n", .{ indent, suffix, return_ty });
        try writer.print("{s}    return {s};\n", .{ indent, wrapped });
        try writer.print("{s}}}\n\n", .{indent});
    }
}

fn emitSetters(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, fields: []const Parser.Field, self_expr: []const u8, indent: []const u8) !void {
    for (fields) |field| {
        if (field.type_expr.* == .function) continue;
        const suffix = try utils.pascalCaseOwned(allocator, field.name);
        defer allocator.free(suffix);
        const snake = try utils.snakeCaseOwned(allocator, field.name);
        defer allocator.free(snake);
        const input_ty = try setterTypeOwned(allocator, schema, field.type_expr);
        defer allocator.free(input_ty);
        const assign_expr = try setterExprOwned(allocator, schema, "value", field.type_expr);
        defer allocator.free(assign_expr);
        const field_expr = try std.fmt.allocPrint(allocator, "{s}.{s}", .{ self_expr, snake });
        defer allocator.free(field_expr);
        try writer.print("{s}pub inline fn set{s}(self: @This(), allocator: std.mem.Allocator, value: {s}) !void {{\n", .{ indent, suffix, input_ty });
        try writer.print("{s}    deinitPublicOwnedValue(@TypeOf({s}), &{s}, allocator);\n", .{ indent, field_expr, field_expr });
        try writer.print("{s}    {s} = {s};\n", .{ indent, field_expr, assign_expr });
        try writer.print("{s}}}\n\n", .{indent});
    }
}

fn emitStructWrapper(writer: *std.Io.Writer, allocator: std.mem.Allocator, schema: *const Parser.Schema, name: []const u8, fields: []const Parser.Field, comptime deinit_uses_allocator: bool, comptime is_opaque: bool) !void {
    try writer.print(
        \\pub const {s} = struct {{
        \\    value: papi.{s},
        \\
        \\    pub const Plain = @This();
        \\    pub const Ref = Ref{s};
        \\    pub const ConstRef = ConstRef{s};
        \\
        \\    pub inline fn init(allocator: std.mem.Allocator) !{s} {{
        \\        _ = allocator;
        \\        return .{{ .value = papi.{s}.init() }};
        \\    }}
        \\
    , .{ name, name, name, name, name, name });

    if (deinit_uses_allocator) {
        try writer.writeAll("    pub inline fn deinit(self: *@This(), allocator: std.mem.Allocator) void {\n        self.value.deinit(allocator);\n    }\n\n");
    } else {
        try writer.writeAll("    pub inline fn deinit(self: *@This()) void {\n        self.value.deinit();\n    }\n\n");
    }

    if (is_opaque) {
        try writer.writeAll("    pub inline fn getPtr(self: *const @This()) *anyopaque {\n        return self.value.ptr;\n    }\n\n");
    } else {
        try emitGetters(writer, allocator, schema, fields, "self.value", "    ", false);
    }

    try writer.print(
        \\    pub inline fn toRef(self: *@This()) Ref{s} {{
        \\        return .{{ .value = &self.value }};
        \\    }}
        \\
        \\    pub inline fn toConst(self: *const @This()) ConstRef{s} {{
        \\        return .{{ .value = &self.value }};
        \\    }}
        \\}};
        \\
    , .{ name, name });

    try writer.print(
        \\pub const Ref{s} = struct {{
        \\    value: *papi.{s},
        \\
        \\    pub const Plain = {s};
        \\    pub const Ref = @This();
        \\    pub const ConstRef = ConstRef{s};
        \\
        \\    pub inline fn init(allocator: std.mem.Allocator) !Ref{s} {{
        \\        const obj = try allocator.create(papi.{s});
        \\        obj.* = papi.{s}.init();
        \\        return .{{ .value = obj }};
        \\    }}
        \\
    , .{ name, name, name, name, name, name, name });

    if (deinit_uses_allocator) {
        try writer.writeAll("    pub inline fn deinit(self: @This(), allocator: std.mem.Allocator) void {\n        self.value.deinit(allocator);\n        allocator.destroy(self.value);\n    }\n\n");
    } else {
        try writer.writeAll("    pub inline fn deinit(self: @This(), allocator: std.mem.Allocator) void {\n        self.value.deinit();\n        allocator.destroy(self.value);\n    }\n\n");
    }

    if (is_opaque) {
        try writer.writeAll("    pub inline fn getPtr(self: @This()) *anyopaque {\n        return self.value.ptr;\n    }\n\n    pub inline fn setPtr(self: @This(), ptr: *anyopaque) void {\n        self.value.ptr = ptr;\n    }\n\n");
    } else {
        try emitGetters(writer, allocator, schema, fields, "self.value", "    ", false);
        try emitSetters(writer, allocator, schema, fields, "self.value", "    ");
    }

    try writer.print(
        \\    pub inline fn toConst(self: @This()) ConstRef{s} {{
        \\        return .{{ .value = self.value }};
        \\    }}
        \\}};
        \\
    , .{name});

    try writer.print(
        \\pub const ConstRef{s} = struct {{
        \\    value: *const papi.{s},
        \\
        \\    pub const Plain = {s};
        \\    pub const Ref = Ref{s};
        \\    pub const ConstRef = @This();
        \\
    , .{ name, name, name, name });

    if (is_opaque) {
        try writer.writeAll("    pub inline fn getPtr(self: @This()) *anyopaque {\n        return @constCast(self.value.ptr);\n    }\n\n");
    } else {
        try emitGetters(writer, allocator, schema, fields, "self.value", "    ", true);
    }

    try writer.writeAll("};\n\n");
}

pub fn emit(allocator: std.mem.Allocator, writer: *std.Io.Writer, schema: *const Parser.Schema) !void {
    try writer.writeAll(
        \\///! mzproto - bridge between ir and native zig
        \\///!
        \\///! Automatically generated. do not edit
        \\
        \\const std = @import("std");
        \\const papi = @import("mzproto");
        \\
        \\const PREFERRED_ENCODING = enum {
        \\    utf8,
        \\    utf16,
        \\};
        \\
        \\pub const STRINGS_ARE_NO_COPY = true;
        \\pub const BYTES_ARE_NO_COPY = true;
        \\pub const PREFERRED_STRING_ENCODING: PREFERRED_ENCODING = .utf8;
        \\pub const OBJECTS_ALWAYS_REFERENCED = false;
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
        \\fn zeroValue(comptime T: type) T {
        \\    var value: T = undefined;
        \\    @memset(std.mem.asBytes(&value), 0);
        \\    return value;
        \\}
        \\
        \\fn deinitPublicOwnedValue(comptime T: type, value: *T, allocator: std.mem.Allocator) void {
        \\    switch (@typeInfo(T)) {
        \\        .optional => {
        \\            if (value.*) |*child| {
        \\                deinitPublicOwnedValue(@TypeOf(child.*), child, allocator);
        \\            }
        \\            value.* = null;
        \\        },
        \\        .pointer => |pointer| switch (pointer.size) {
        \\            .slice => {
        \\                if (value.*.len == 0) return;
        \\                if (pointer.child != u8) {
        \\                    for (value.*) |*item| {
        \\                        deinitPublicOwnedValue(@TypeOf(item.*), item, allocator);
        \\                    }
        \\                }
        \\                allocator.free(@constCast(value.*));
        \\                value.* = &.{};
        \\            },
        \\            else => {
        \\                if (@intFromPtr(value.*) == 0) return;
        \\                if (@hasDecl(pointer.child, "deinit")) {
        \\                    const ptr: *pointer.child = @constCast(value.*);
        \\                    ptr.deinit(allocator);
        \\                    allocator.destroy(ptr);
        \\                }
        \\                value.* = zeroValue(T);
        \\            },
        \\        },
        \\        .@"struct", .@"union" => if (@hasDecl(T, "deinit")) value.deinit(allocator),
        \\        else => {},
        \\    }
        \\}
        \\
        \\fn bridgeStorageType(comptime T: type) type {
        \\    if (T == String) return []u8;
        \\    if (T == Bytes) return []u8;
        \\    if (T == ConstString) return []const u8;
        \\    if (T == ConstBytes) return []const u8;
        \\    if (@hasField(T, "value")) return @FieldType(T, "value");
        \\    return T;
        \\}
        \\
        \\fn wrapBridgeValue(comptime T: type, value: bridgeStorageType(T)) T {
        \\    if (T == String or T == Bytes) return .{ .slice = @constCast(value) };
        \\    if (T == ConstString or T == ConstBytes) return .{ .slice = value };
        \\    if (@hasField(T, "value")) return .{ .value = value };
        \\    return value;
        \\}
        \\
        \\fn unwrapBridgeValue(comptime T: type, value: T) bridgeStorageType(T) {
        \\    if (T == String or T == Bytes or T == ConstString or T == ConstBytes) return value.slice;
        \\    if (@hasField(T, "value")) return value.value;
        \\    return value;
        \\}
        \\
        \\pub const ConstString = struct {
        \\    slice: []const u8,
        \\
        \\    pub inline fn getUTF8(self: ConstString, allocator: std.mem.Allocator) ![]const u8 {
        \\        _ = allocator;
        \\        return self.slice;
        \\    }
        \\
        \\    pub inline fn getUTF8Copy(self: ConstString, allocator: std.mem.Allocator) ![]u8 {
        \\        return try allocator.dupe(u8, self.slice);
        \\    }
        \\
        \\    pub inline fn getUTF16(self: ConstString, allocator: std.mem.Allocator) ![]const u8 {
        \\        _ = allocator;
        \\        return self.slice;
        \\    }
        \\
        \\    pub inline fn getUTF16Copy(self: ConstString, allocator: std.mem.Allocator) ![]u8 {
        \\        return try allocator.dupe(u8, self.slice);
        \\    }
        \\
        \\    pub inline fn size(self: ConstString) usize {
        \\        return self.slice.len;
        \\    }
        \\};
        \\
        \\pub const String = struct {
        \\    slice: []u8,
        \\
        \\    pub inline fn initUTF8(allocator: std.mem.Allocator, src: []u8) !String {
        \\        _ = allocator;
        \\        return .{ .slice = src };
        \\    }
        \\
        \\    pub inline fn initUTF16(allocator: std.mem.Allocator, src: []u8) !String {
        \\        _ = allocator;
        \\        return .{ .slice = src };
        \\    }
        \\
        \\    pub inline fn getUTF8(self: *const String, allocator: std.mem.Allocator) ![]const u8 {
        \\        _ = allocator;
        \\        return self.slice;
        \\    }
        \\
        \\    pub inline fn getUTF8Copy(self: *const String, allocator: std.mem.Allocator) ![]u8 {
        \\        return try allocator.dupe(u8, self.slice);
        \\    }
        \\
        \\    pub inline fn getUTF8Owned(self: *String, allocator: std.mem.Allocator) ![]u8 {
        \\        _ = allocator;
        \\        const slice = self.slice;
        \\        self.slice = &.{};
        \\        return slice;
        \\    }
        \\
        \\    pub inline fn getUTF16(self: *const String, allocator: std.mem.Allocator) ![]const u8 {
        \\        _ = allocator;
        \\        return self.slice;
        \\    }
        \\
        \\    pub inline fn getUTF16Copy(self: *const String, allocator: std.mem.Allocator) ![]u8 {
        \\        return try allocator.dupe(u8, self.slice);
        \\    }
        \\
        \\    pub inline fn getUTF16Owned(self: *String, allocator: std.mem.Allocator) ![]u8 {
        \\        return self.getUTF8Owned(allocator);
        \\    }
        \\
        \\    pub inline fn size(self: *const String) usize {
        \\        return self.slice.len;
        \\    }
        \\
        \\    pub inline fn toConst(self: *const String) ConstString {
        \\        return .{ .slice = self.slice };
        \\    }
        \\
        \\    pub inline fn deinit(self: *String, allocator: std.mem.Allocator) void {
        \\        if (self.slice.len > 0) allocator.free(self.slice);
        \\        self.slice = &.{};
        \\    }
        \\};
        \\
        \\pub const ConstBytes = struct {
        \\    slice: []const u8,
        \\
        \\    pub inline fn get(self: ConstBytes, allocator: std.mem.Allocator) ![]const u8 {
        \\        _ = allocator;
        \\        return self.slice;
        \\    }
        \\
        \\    pub inline fn getCopy(self: ConstBytes, allocator: std.mem.Allocator) ![]u8 {
        \\        return try allocator.dupe(u8, self.slice);
        \\    }
        \\
        \\    pub inline fn size(self: ConstBytes) usize {
        \\        return self.slice.len;
        \\    }
        \\};
        \\
        \\pub const Bytes = struct {
        \\    slice: []u8,
        \\
        \\    pub inline fn init(src: []u8) Bytes {
        \\        return .{ .slice = src };
        \\    }
        \\
        \\    pub inline fn initCopy(allocator: std.mem.Allocator, src: []const u8) !Bytes {
        \\        return .{ .slice = try allocator.dupe(u8, src) };
        \\    }
        \\
        \\    pub inline fn get(self: *const Bytes, allocator: std.mem.Allocator) ![]const u8 {
        \\        _ = allocator;
        \\        return self.slice;
        \\    }
        \\
        \\    pub inline fn getCopy(self: *const Bytes, allocator: std.mem.Allocator) ![]u8 {
        \\        return try allocator.dupe(u8, self.slice);
        \\    }
        \\
        \\    pub inline fn getOwned(self: *Bytes, allocator: std.mem.Allocator) ![]u8 {
        \\        _ = allocator;
        \\        const slice = self.slice;
        \\        self.slice = &.{};
        \\        return slice;
        \\    }
        \\
        \\    pub inline fn toConst(self: *const Bytes) ConstBytes {
        \\        return .{ .slice = self.slice };
        \\    }
        \\
        \\    pub inline fn size(self: *const Bytes) usize {
        \\        return self.slice.len;
        \\    }
        \\
        \\    pub inline fn deinit(self: *Bytes, allocator: std.mem.Allocator) void {
        \\        if (self.slice.len > 0) allocator.free(self.slice);
        \\        self.slice = &.{};
        \\    }
        \\};
        \\
        \\pub fn List(comptime T: type) type {
        \\    const Storage = bridgeStorageType(T);
        \\    return struct {
        \\        slice: []Storage,
        \\
        \\        pub inline fn init(allocator: std.mem.Allocator, len: usize) !@This() {
        \\            return .{ .slice = try allocator.alloc(Storage, len) };
        \\        }
        \\
        \\        pub inline fn initOwned(allocator: std.mem.Allocator, value: []Storage) !@This() {
        \\            _ = allocator;
        \\            return .{ .slice = value };
        \\        }
        \\
        \\        pub inline fn size(self: @This()) usize {
        \\            return self.slice.len;
        \\        }
        \\
        \\        pub inline fn toConst(self: @This()) ConstList(T) {
        \\            return .{ .slice = self.slice };
        \\        }
        \\
        \\        pub inline fn get(self: @This(), index: usize) T {
        \\            return wrapBridgeValue(T, self.slice[index]);
        \\        }
        \\
        \\        pub inline fn set(self: @This(), allocator: std.mem.Allocator, index: usize, value: T) void {
        \\            deinitPublicOwnedValue(Storage, &self.slice[index], allocator);
        \\            self.slice[index] = unwrapBridgeValue(T, value);
        \\        }
        \\
        \\        pub inline fn deinit(self: @This(), allocator: std.mem.Allocator) void {
        \\            for (self.slice) |*item| {
        \\                deinitPublicOwnedValue(Storage, item, allocator);
        \\            }
        \\            allocator.free(self.slice);
        \\        }
        \\    };
        \\}
        \\
        \\pub fn ConstList(comptime T: type) type {
        \\    const Storage = bridgeStorageType(T);
        \\    return struct {
        \\        slice: []const Storage,
        \\
        \\        pub inline fn size(self: @This()) usize {
        \\            return self.slice.len;
        \\        }
        \\
        \\        pub inline fn get(self: @This(), index: usize) T {
        \\            return wrapBridgeValue(T, self.slice[index]);
        \\        }
        \\    };
        \\}
        \\
    );

    for (schema.declarations.items) |decl| {
        switch (decl) {
            .enum_decl => |value| {
                try emitDoc(writer, value.doc);
                try writer.print("pub const {s} = papi.{s};\n\n", .{ value.name, value.name });
            },
            .struct_decl => |value| {
                try emitDoc(writer, value.doc);
                try emitStructWrapper(writer, allocator, schema, value.name, value.fields.items, true, false);
            },
            .union_decl => |value| {
                try emitDoc(writer, value.doc);
                try emitStructWrapper(writer, allocator, schema, value.name, value.fields.items, true, false);
            },
            .opaque_decl => |value| {
                try emitDoc(writer, value.doc);
                try emitStructWrapper(writer, allocator, schema, value.name, &.{}, false, true);
            },
            .function_decl => {},
        }
    }
}
