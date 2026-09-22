const std = @import("std");
const ast = @import("ast.zig");

fn appendType(allocator: std.mem.Allocator, out: *std.ArrayList(u8), ty: *const ast.TypeExpr) std.mem.Allocator.Error!void {
    switch (ty.value) {
        .name => |name| try out.appendSlice(allocator, if (std.mem.eql(u8, name, "bytes")) "string" else name),
        .natural => try out.append(allocator, '#'),
        .bare => |inner| {
            try out.append(allocator, '%');
            try appendType(allocator, out, inner);
        },
        .bang => |inner| {
            try out.append(allocator, '!');
            try appendType(allocator, out, inner);
        },
        .application => |app| {
            try appendType(allocator, out, app.head);
            for (app.args) |arg| {
                try out.append(allocator, ' ');
                try appendType(allocator, out, arg);
            }
        },
    }
}

/// Canonical TL declaration for CRC32: no ID, braces, parentheses, or semicolon.
pub fn canonical(allocator: std.mem.Allocator, declaration: ast.Declaration) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    
    try out.appendSlice(allocator, declaration.name);

    for (declaration.type_parameters) |parameter| {
        try out.append(allocator, ' ');
        try out.appendSlice(allocator, parameter.name);
        try out.appendSlice(allocator, ":Type");
    }

    for (declaration.fields) |field| {
        if (field.condition != null and field.type.value == .name and std.mem.eql(u8, field.type.value.name, "true")) continue;
        try out.append(allocator, ' ');
        try out.appendSlice(allocator, field.name);
        try out.append(allocator, ':');
        if (field.condition) |condition| {
            try out.appendSlice(allocator, condition.field);
            var buf: [16]u8 = undefined;
            try out.appendSlice(allocator, std.fmt.bufPrint(&buf, ".{d}?", .{condition.bit}) catch unreachable);
        }
        try appendType(allocator, &out, field.type);
    }

    try out.appendSlice(allocator, " = ");
    try appendType(allocator, &out, declaration.result);

    return out.toOwnedSlice(allocator);
}

pub fn compute(allocator: std.mem.Allocator, declaration: ast.Declaration) !u32 {
    const text = try canonical(allocator, declaration);
    defer allocator.free(text);

    return std.hash.Crc32.hash(text);
}
