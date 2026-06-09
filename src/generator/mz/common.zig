const std = @import("std");
const Parser = @import("./parser.zig");

pub const DeclKind = enum {
    builtin_void,
    builtin_bool,
    builtin_u32,
    builtin_u64,
    builtin_i32,
    builtin_i64,
    builtin_time,
    builtin_string,
    builtin_bytes,
    enum_decl,
    struct_decl,
    union_decl,
    opaque_decl,
    function_decl,
    unknown,
};

pub const ListFamily = enum {
    handle,
    bool,
    u32,
    u64,
    i32,
    i64,
    time,
};

pub fn classifyNamed(schema: *const Parser.Schema, name: []const u8) DeclKind {
    if (std.mem.eql(u8, name, "void")) return .builtin_void;
    if (std.mem.eql(u8, name, "bool")) return .builtin_bool;
    if (std.mem.eql(u8, name, "u32")) return .builtin_u32;
    if (std.mem.eql(u8, name, "u64")) return .builtin_u64;
    if (std.mem.eql(u8, name, "i32")) return .builtin_i32;
    if (std.mem.eql(u8, name, "i64")) return .builtin_i64;
    if (std.mem.eql(u8, name, "time")) return .builtin_time;
    if (std.mem.eql(u8, name, "string")) return .builtin_string;
    if (std.mem.eql(u8, name, "bytes")) return .builtin_bytes;

    for (schema.declarations.items) |declaration| {
        switch (declaration) {
            .enum_decl => |decl| if (std.mem.eql(u8, decl.name, name)) return .enum_decl,
            .struct_decl => |decl| if (std.mem.eql(u8, decl.name, name)) return .struct_decl,
            .union_decl => |decl| if (std.mem.eql(u8, decl.name, name)) return .union_decl,
            .opaque_decl => |decl| if (std.mem.eql(u8, decl.name, name)) return .opaque_decl,
            .function_decl => |decl| if (std.mem.eql(u8, decl.name, name)) return .function_decl,
        }
    }

    return .unknown;
}

pub fn pascalCaseOwned(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);
    var upper = true;
    for (name) |char| {
        if (char == '.' or char == '-' or char == ' ' or char == '_') {
            upper = true;
            continue;
        }
        if (upper) {
            upper = false;
            try out.append(allocator, std.ascii.toUpper(char));
            continue;
        }
        try out.append(allocator, char);
    }

    return out.toOwnedSlice(allocator);
}

pub fn snakeCaseOwned(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);

    for (name, 0..) |char, index| {
        if (char == '.' or char == '-' or char == ' ') {
            try out.append(allocator, '_');
            continue;
        }
        if (std.ascii.isUpper(char)) {
            const previous = if (index > 0) name[index - 1] else 0;
            const next = if (index + 1 < name.len) name[index + 1] else 0;
            const need_separator = index > 0 and previous != '_' and (std.ascii.isLower(previous) or
                std.ascii.isDigit(previous) or
                (std.ascii.isUpper(previous) and next != 0 and std.ascii.isLower(next)));
            if (need_separator) {
                try out.append(allocator, '_');
            }
            try out.append(allocator, std.ascii.toLower(char));
            continue;
        }
        try out.append(allocator, char);
    }

    return out.toOwnedSlice(allocator);
}

pub fn upperSnakeOwned(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    const snake = try snakeCaseOwned(allocator, name);
    defer allocator.free(snake);

    const out = try allocator.dupe(u8, snake);
    for (out) |*char| {
        char.* = std.ascii.toUpper(char.*);
    }
    return out;
}

pub fn goNameOwned(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);

    var make_upper = true;
    for (name) |char| {
        if (char == '_' or char == '.' or char == '-' or char == ' ') {
            make_upper = true;
            continue;
        }

        if (make_upper) {
            try out.append(allocator, std.ascii.toUpper(char));
            make_upper = false;
        } else {
            try out.append(allocator, char);
        }
    }

    return out.toOwnedSlice(allocator);
}

pub fn zigTypeOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr, comptime const_ref: bool) ![]u8 {
    switch (type_expr.*) {
        //.optional => |child| return cTypeOwned(allocator, schema, child),
        .optional => |child| {
            const ty = try zigTypeOwned(allocator, schema, child, const_ref);
            defer allocator.free(ty);
            return std.fmt.allocPrint(allocator, "?{s}", .{ty});
        },
        .reference => |child| {
            const ty = try zigTypeOwned(allocator, schema, child, const_ref);
            defer allocator.free(ty);
            if (const_ref) {
                return std.fmt.allocPrint(allocator, "*const {s}", .{ty});
            } else {
                return std.fmt.allocPrint(allocator, "*{s}", .{ty});
            }
        },
        .list => |child| {
            const ty = try zigTypeOwned(allocator, schema, child, const_ref);
            defer allocator.free(ty);
            if (const_ref) {
                return std.fmt.allocPrint(allocator, "[]const {s}", .{ty});
            } else {
                return std.fmt.allocPrint(allocator, "[]{s}", .{ty});
            }
        },
        .function => return allocator.dupe(u8, "void"),
        .named => |name| switch (classifyNamed(schema, name)) {
            .builtin_void => return allocator.dupe(u8, "void"),
            .builtin_bool => return allocator.dupe(u8, "bool"),
            .builtin_u32 => return allocator.dupe(u8, "u32"),
            .builtin_u64 => return allocator.dupe(u8, "u64"),
            .builtin_i32 => return allocator.dupe(u8, "i32"),
            .builtin_i64 => return allocator.dupe(u8, "i64"),
            .builtin_time => return allocator.dupe(u8, "Time"),
            .builtin_string => return allocator.dupe(u8, "String"),
            .builtin_bytes => return allocator.dupe(u8, "Bytes"),
            .enum_decl, .struct_decl, .union_decl => return allocator.dupe(u8, name),
            .opaque_decl => return allocator.dupe(u8, name),
            else => return allocator.dupe(u8, name),
        },
    }
}

pub fn cTypeOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) ![]u8 {
    switch (type_expr.*) {
        .optional => |child| return cTypeOwned(allocator, schema, child),
        .reference => |child| return cTypeOwned(allocator, schema, child),
        .list => return allocator.dupe(u8, "mzt_list_t"),
        .function => return allocator.dupe(u8, "void"),
        .named => |name| switch (classifyNamed(schema, name)) {
            .builtin_void => return allocator.dupe(u8, "void"),
            .builtin_bool => return allocator.dupe(u8, "mzt_bool_t"),
            .builtin_u32 => return allocator.dupe(u8, "mzt_u32_t"),
            .builtin_u64 => return allocator.dupe(u8, "mzt_u64_t"),
            .builtin_i32 => return allocator.dupe(u8, "mzt_i32_t"),
            .builtin_i64 => return allocator.dupe(u8, "mzt_i64_t"),
            .builtin_time => return allocator.dupe(u8, "mzt_time_t"),
            .builtin_string => return allocator.dupe(u8, "mzt_string_t"),
            .builtin_bytes => return allocator.dupe(u8, "mzt_bytes_t"),
            .enum_decl, .struct_decl, .union_decl => {
                const snake = try snakeCaseOwned(allocator, name);
                defer allocator.free(snake);
                return std.fmt.allocPrint(allocator, "mzt_{s}_t", .{snake});
            },
            .opaque_decl => {
                const snake = try snakeCaseOwned(allocator, name);
                defer allocator.free(snake);
                return std.fmt.allocPrint(allocator, "mzf_{s}_t", .{snake});
            },
            else => {
                const snake = try snakeCaseOwned(allocator, name);
                defer allocator.free(snake);
                return std.fmt.allocPrint(allocator, "mzt_{s}_t", .{snake});
            },
        },
    }
}

pub fn goTypeOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) std.mem.Allocator.Error![]u8 {
    switch (type_expr.*) {
        .optional => |child| {
            const inner = try goTypeOwned(allocator, schema, child);
            defer allocator.free(inner);
            return std.fmt.allocPrint(allocator, "Option[{s}]", .{inner});
        },
        .reference => |child| {
            const inner = try goTypeOwned(allocator, schema, child);
            if (inner.len == 0 or std.mem.startsWith(u8, inner, "*")) {
                return inner;
            }
            defer allocator.free(inner);
            return std.fmt.allocPrint(allocator, "*{s}", .{inner});
        },
        .list => |child| {
            const inner = try goTypeOwned(allocator, schema, child);
            defer allocator.free(inner);
            return std.fmt.allocPrint(allocator, "[]{s}", .{inner});
        },
        .function => |signature| return goSignatureTypeOwned(allocator, schema, &signature),
        .named => |name| switch (classifyNamed(schema, name)) {
            .builtin_void => return allocator.dupe(u8, ""),
            .builtin_bool => return allocator.dupe(u8, "bool"),
            .builtin_u32 => return allocator.dupe(u8, "uint32"),
            .builtin_u64 => return allocator.dupe(u8, "uint64"),
            .builtin_i32 => return allocator.dupe(u8, "int32"),
            .builtin_i64 => return allocator.dupe(u8, "int64"),
            .builtin_time => return allocator.dupe(u8, "int64"),
            .builtin_string => return allocator.dupe(u8, "string"),
            .builtin_bytes => return allocator.dupe(u8, "[]byte"),
            .enum_decl => return goNameOwned(allocator, name),
            .struct_decl, .union_decl => return goNameOwned(allocator, name),
            .opaque_decl => {
                const go_name = try goNameOwned(allocator, name);
                defer allocator.free(go_name);
                return std.fmt.allocPrint(allocator, "{s}Handle", .{go_name});
            },
            else => return goNameOwned(allocator, name),
        },
    }
}

pub fn goSignatureTypeOwned(allocator: std.mem.Allocator, schema: *const Parser.Schema, signature: *const Parser.FunctionSignature) std.mem.Allocator.Error![]u8 {
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);

    try out.appendSlice(allocator, "func(");
    for (signature.params.items, 0..) |parameter, index| {
        if (index != 0) {
            try out.appendSlice(allocator, ", ");
        }
        const parameter_type = try goTypeOwned(allocator, schema, parameter.type_expr);
        defer allocator.free(parameter_type);
        try out.appendSlice(allocator, parameter_type);
    }
    try out.append(allocator, ')');

    const return_type = try goTypeOwned(allocator, schema, signature.return_type);
    defer allocator.free(return_type);
    if (return_type.len != 0) {
        try out.append(allocator, ' ');
        try out.appendSlice(allocator, return_type);
    }

    return out.toOwnedSlice(allocator);
}

pub fn isHandleType(schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) bool {
    switch (type_expr.*) {
        .optional => |child| return isHandleType(schema, child),
        .reference => return true,
        .list => return true,
        .function => return false,
        .named => |name| switch (classifyNamed(schema, name)) {
            .builtin_string,
            .builtin_bytes,
            .opaque_decl,
            => return true,
            else => return false,
        },
    }
}

pub fn isOptionalType(type_expr: *const Parser.TypeExpr) bool {
    return type_expr.* == .optional;
}

pub fn isValueObjectType(schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) bool {
    return switch (type_expr.*) {
        .optional => |child| isValueObjectType(schema, child),
        .reference => false,
        .named => |name| switch (classifyNamed(schema, name)) {
            .struct_decl, .union_decl => true,
            else => false,
        },
        else => false,
    };
}

pub fn isOptionalScalar(schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) bool {
    return isOptionalType(type_expr) and !isHandleType(schema, type_expr.optional);
}

pub fn isVoidType(schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) bool {
    const inner = unwrapType(type_expr);
    return inner.* == .named and classifyNamed(schema, inner.named) == .builtin_void;
}

pub fn listFamily(schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) ListFamily {
    const inner = unwrapType(type_expr);
    return switch (inner.*) {
        .list => .handle,
        .reference => .handle,
        .function => .handle,
        .optional => listFamily(schema, inner.optional),
        .named => |name| switch (classifyNamed(schema, name)) {
            .builtin_bool => .bool,
            .builtin_u32, .enum_decl => .u32,
            .builtin_u64 => .u64,
            .builtin_i32 => .i32,
            .builtin_i64 => .i64,
            .builtin_time => .time,
            else => .handle,
        },
    };
}

pub fn unwrapType(type_expr: *const Parser.TypeExpr) *const Parser.TypeExpr {
    return switch (type_expr.*) {
        .optional => |child| unwrapType(child),
        .reference => |child| unwrapType(child),
        else => type_expr,
    };
}

pub fn isReferenceLike(schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) bool {
    return switch (type_expr.*) {
        .optional => |child| isReferenceLike(schema, child),
        .reference => true,
        .list => true,
        .function => true,
        .named => |name| switch (classifyNamed(schema, name)) {
            .builtin_string,
            .builtin_bytes,
            .opaque_decl,
            => true,
            else => false,
        },
    };
}

pub fn isReferenceLike2(schema: *const Parser.Schema, type_expr: *const Parser.TypeExpr) bool {
    return switch (type_expr.*) {
        .optional => |child| isReferenceLike2(schema, child),
        .reference => |child| isReferenceLike2(schema, child),
        .list => true,
        .function => true,
        .named => |name| switch (classifyNamed(schema, name)) {
            .builtin_string,
            .builtin_bytes,
            .opaque_decl,
            => true,
            else => false,
        },
    };
}

pub fn isList(type_expr: *const Parser.TypeExpr) bool {
    return switch (type_expr.*) {
        .optional => |child| isList(child),
        .reference => |child| isList(child),
        .list => true,
        else => false,
    };
}
