const std = @import("std");
const tl = @import("tl_parser");
pub const Dialect = enum { telegram, storage };

fn name(allocator: std.mem.Allocator, raw: []const u8, prefix: []const u8) std.mem.Allocator.Error![]const u8 {
    // Keep TL spelling intact inside quoted Zig identifiers, including namespaces.
    return std.fmt.allocPrint(allocator, "@\"{s}{s}\"", .{ prefix, raw });
}
const Context = struct {
    schema: *const tl.Schema,
    dialect: Dialect,
    w: *std.Io.Writer,

    fn spec(self: *Context, allocator: std.mem.Allocator, ty: *const tl.semantic.Type) std.mem.Allocator.Error![]const u8 {
        return switch (ty.kind) {
            .natural => "base.Primitive(u32, null)",
            .builtin => |b| blk: {
                const boxed = ty.encoding == .boxed;
                const primitive, const definition = switch (b) {
                    .int => .{ "u32", "int ? = Int" },
                    .long => .{ "u64", "long ? = Long" },
                    .double => .{ "f64", "double ? = Double" },
                    .int128 => .{ "u128", "int128 4*[ int ] = Int128" },
                    .int256 => .{ "u256", "int256 8*[ int ] = Int256" },
                    .string, .bytes => {
                        if (boxed) break :blk "base.BoxedBytes(0xb5286e24)";
                        break :blk "base.Bytes";
                    },
                    .boolean => break :blk "base.Boolean",
                    .true_value => break :blk if (boxed) "base.True" else "base.Boolean",
                    .object => break :blk "base.Ref(AnyObject, .boxed)",
                };
                if (boxed) break :blk try std.fmt.allocPrint(allocator, "base.Primitive({s}, 0x{x})", .{ primitive, std.hash.Crc32.hash(definition) });
                break :blk try std.fmt.allocPrint(allocator, "base.Primitive({s}, null)", .{primitive});
            },
            .boxed => |i| try std.fmt.allocPrint(allocator, "base.Ref({s}, .boxed)", .{
                try name(allocator, self.schema.types[i].name, ""),
            }),
            .constructor => |i| try std.fmt.allocPrint(allocator, "base.Ref({s}, .bare)", .{
                try name(allocator, self.schema.syntax.declarations[i].name, ""),
            }),
            .vector => |element| try std.fmt.allocPrint(allocator, "base.Vector({s}, .{s})", .{
                try self.spec(allocator, element),
                if (ty.encoding == .bare) "bare" else "boxed",
            }),
            .query => "base.Ref(Query, .boxed)",
            .parameter => "Query.Result",
        };
    }

    fn common(self: *Context) !void {
        try self.w.print(
            \\    const Object = base.TLObject(@This(), .{s});
            \\    pub const out_alignment = Object.out_alignment;
            \\    pub const serialize = Object.serialize;
            \\    pub const serializedSize = Object.serializedSize;
            \\    pub const measure = Object.measure;
            \\    pub const decodeInto = Object.decodeInto;
            \\    pub const decodeExact = Object.decodeExact;
            \\    pub const view = Object.view;
            \\    pub const cloneSize = Object.cloneSize;
            \\    pub const cloneInto = Object.cloneInto;
            \\
        , .{@tagName(self.dialect)});
    }

    fn declaration(self: *Context, allocator: std.mem.Allocator, index: usize) !void {
        const syntax = self.schema.syntax.declarations[index];
        const decl = self.schema.declarations[index];
        const generic = syntax.type_parameters.len != 0;

        if (self.dialect == .storage and (syntax.explicit_id == null or syntax.section == .functions)) {
            return error.StorageRequiresExplicitConstructorIds;
        }

        if (generic) {
            if (syntax.type_parameters.len != 1 or decl.result.kind != .parameter) return error.UnsupportedGenericFunction;

            var queries: usize = 0;
            for (decl.fields) |f| {
                if (f.type.kind == .query) queries += 1 else if (f.type.kind == .parameter) return error.UnsupportedGenericValue;
            }

            if (queries != 1) return error.UnsupportedGenericFunction;
        }

        if (generic) {
            try self.w.print("pub fn {s}(comptime Query: type) type {{ return struct {{\n", .{try name(allocator, syntax.name, "")});
        } else {
            try self.w.print("pub const {s} = struct {{\n", .{try name(allocator, syntax.name, "")});
        }

        try self.w.print(
            \\    pub const tl_id: u32 = 0x{x};
            \\
        , .{decl.id});

        for (syntax.fields, decl.fields) |f, resolved| {
            if (self.dialect == .telegram and f.since != null) return error.StorageAnnotationInTelegram;
            if (resolved.type.kind == .natural) continue;
            const optional = resolved.since > 1 or (resolved.presence == .flag and !resolved.presence.flag.flag_only);
            try self.w.print("    {s}: {s}({s}).Write{s},\n", .{ try name(allocator, f.name, ""), if (optional) "?" else "", try self.spec(allocator, resolved.type), if (optional) " = null" else if (resolved.presence == .flag) " = false" else "" });
        }

        try self.w.writeAll("    pub const tl_fields = .{\n");
        for (syntax.fields, decl.fields) |f, resolved| {
            try self.w.print("        base.Field(\"{s}\", {s}, .{{ .since = {d}", .{ f.name, try self.spec(allocator, resolved.type), resolved.since });
            if (resolved.type.kind == .natural) try self.w.writeAll(", .flag_word = true");
            if (resolved.presence == .flag) {
                const flag = resolved.presence.flag;
                try self.w.print(", .flag_index = {d}, .bit = {d}, .flag_only = {}", .{ flag.field_index, flag.bit, flag.flag_only });
            }
            try self.w.writeAll(" }),\n");
        }

        try self.w.writeAll("    };\n    pub const Decoded = struct {\n");
        for (syntax.fields, decl.fields) |f, resolved| {
            if (resolved.type.kind == .natural) continue;
            const optional = resolved.since > 1 or (resolved.presence == .flag and !resolved.presence.flag.flag_only);
            try self.w.print("        {s}: {s}({s}).Read,\n", .{ try name(allocator, f.name, ""), if (optional) "?" else "", try self.spec(allocator, resolved.type) });
        }
        try self.resultMethod(allocator, index);
        try self.w.writeAll(
            \\    };
            \\    pub const View = struct {
            \\        _mztl_frame: base.Frame,
            \\        const Parent = _mztl_module.
        );
        if (generic) try self.w.print("{s}(Query);\n", .{try name(allocator, syntax.name, "")}) else try self.w.print("{s};\n", .{try name(allocator, syntax.name, "")});
        try self.w.writeAll(
            \\        pub fn storedVersion(_mztl_view: @This()) u32 { return _mztl_view._mztl_frame.version; }
            \\        pub fn validateAll(_mztl_view: @This()) base.cursor.Error!void { return base.validateView(Parent, _mztl_view._mztl_frame); }
            \\
        );
        for (syntax.fields, decl.fields) |f, resolved| {
            if (resolved.type.kind == .natural) continue;
            try self.w.print(
                \\        pub fn {s}(_mztl_view: @This()) base.cursor.Error!base.FieldBorrow(Parent, "{s}") {{ return base.getField(Parent, "{s}", _mztl_view._mztl_frame); }}
                \\
            , .{ try name(allocator, f.name, ""), f.name, f.name });
        }
        try self.w.writeAll("    };\n");
        if (syntax.section == .functions) {
            if (generic) {
                try self.w.writeAll("    pub const Result = if (@hasDecl(Query, \"Result\")) Query.Result else void;\n    pub const TLResult = if (Result != void) base.TLValue(Result, .telegram) else void;\n");
            } else try self.w.print(
                \\    pub const Result = {s};
                \\    pub const TLResult = base.TLValue(Result, .telegram);
                \\
            , .{try self.spec(allocator, decl.result)});
        }
        try self.resultMethod(allocator, index);
        try self.common();
        if (generic) try self.w.writeAll("}; }\n") else try self.w.writeAll("};\n");
    }
    fn unionMember(self: *Context, allocator: std.mem.Allocator, i: usize) ![]const u8 {
        const decl = self.schema.syntax.declarations[i];
        const n = try name(allocator, decl.name, "");
        return if (decl.type_parameters.len != 0) std.fmt.allocPrint(allocator, "{s}(AnyFunction)", .{n}) else n;
    }

    fn resultMethod(self: *Context, allocator: std.mem.Allocator, index: usize) !void {
        const decl = self.schema.syntax.declarations[index];
        if (decl.section != .functions) return;
        try self.w.writeAll("    pub fn resultOps(_mztl_self: @This()) base.ResultOps {\n");
        if (decl.type_parameters.len != 0) {
            for (decl.fields, self.schema.declarations[index].fields) |field, resolved| {
                if (resolved.type.kind == .query) try self.w.print("        return _mztl_self.{s}.resultOps();\n", .{try name(allocator, field.name, "")});
            }
        } else {
            try self.w.print("        _ = _mztl_self; return base.ResultOps.forType(_mztl_module.{s});\n", .{try name(allocator, decl.name, "")});
        }
        try self.w.writeAll("    }\n");
    }

    fn dynamicResultMethod(self: *Context) !void {
        try self.w.writeAll(
            \\    pub fn resultOps(self: @This()) base.ResultOps {
            \\        @setEvalBranchQuota(20_000_000);
            \\        return switch (self) { inline else => |value| value.resultOps() };
            \\    }
            \\
        );
    }

    fn unionType(self: *Context, allocator: std.mem.Allocator, type_name: []const u8, constructors: []const usize) !void {
        try self.w.print(
            \\pub const {s} = union(enum) {{
            \\
        , .{type_name});
        for (constructors) |i| try self.w.print("    {s}: *const {s},\n", .{ try name(allocator, self.schema.syntax.declarations[i].name, ""), try self.unionMember(allocator, i) });

        try self.w.writeAll("    pub const tl_constructors = .{");
        for (constructors) |i| try self.w.print("{s},", .{try self.unionMember(allocator, i)});
        try self.w.writeAll(
            \\};
            \\    pub const Decoded = union(enum) {
            \\
        );
        for (constructors) |i| try self.w.print("        {s}: *const {s}.Decoded,\n", .{ try name(allocator, self.schema.syntax.declarations[i].name, ""), try self.unionMember(allocator, i) });
        if (std.mem.eql(u8, type_name, "AnyFunction")) try self.dynamicResultMethod();
        try self.w.print(
            \\    }};
            \\    pub const View = base.UnionView({s});
            \\
        , .{type_name});
        if (std.mem.eql(u8, type_name, "AnyFunction")) try self.dynamicResultMethod();
        try self.common();
        try self.w.writeAll("};\n");
    }
};

pub fn generate(gpa: std.mem.Allocator, schema: *const tl.Schema, dialect: Dialect, w: *std.Io.Writer) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const allocator = arena.allocator();
    try validate(schema, dialect);
    var ctx: Context = .{ .schema = schema, .dialect = dialect, .w = w };
    try w.writeAll(
        \\// Generated by mzproto's TL generator. Do not edit this files directly, changes will be overwritten!
        \\const _mztl_module = @This();
        \\const base = @import("tl_base");
        \\pub const out_alignment = if (@hasDecl(_mztl_module, "AnyObject")) base.objectAlignment(base.Ref(_mztl_module.AnyObject, .boxed)) else 1;
        \\
    );
    if (dialect == .telegram) {
        try w.writeAll(
            \\pub const identify = base.mtproto.IdentifyFn(_mztl_module).identify;
            \\pub const identifyId = base.mtproto.IdentifyFn(_mztl_module).identifyId;
            \\pub const proto = base.mtproto;
            \\
        );
    }
    for (schema.declarations, 0..) |_, i| try ctx.declaration(allocator, i);
    for (schema.types) |ty| {
        if (ty.external) return error.Unimplemented;
        try ctx.unionType(allocator, try name(allocator, ty.name, ""), ty.constructors);
    }
    var constructors: std.ArrayList(usize) = .empty;
    for (schema.syntax.declarations, 0..) |decl, i| if (decl.section == .types) {
        try constructors.append(allocator, i);
    };
    if (constructors.items.len != 0) try ctx.unionType(allocator, "AnyObject", constructors.items);
    var functions: std.ArrayList(usize) = .empty;
    for (schema.syntax.declarations, 0..) |decl, i| if (decl.section == .functions) {
        try functions.append(allocator, i);
    };
    if (functions.items.len != 0) try ctx.unionType(allocator, "AnyFunction", functions.items);
    try w.writeAll("pub const mztl_constructors = .{");
    for (constructors.items) |i| try w.print("{s},", .{try name(allocator, schema.syntax.declarations[i].name, "")});
    try w.writeAll("};\n");
}

fn validate(schema: *const tl.Schema, dialect: Dialect) !void {
    const reserved = [_][]const u8{
        "base",
        "AnyObject",
        "AnyFunction",
        "identifyId",
        "identify",
        "resultOps",
        "out_alignment",
        "mztl_constructors",
        "Decoded",
        "View",
        "Parent",
        "Query",
        "Result",
        "TLResult",
        "tl_id",
        "tl_fields",
        "tl_version",
        "tl_constructors",
        "serialize",
        "serializedSize",
        "measure",
        "decodeInto",
        "decodeExact",
        "view",
        "cloneSize",
        "cloneInto",
        "storedVersion",
        "validateAll",
    };
    for (schema.syntax.declarations) |decl| {
        for (reserved) |word| if (std.mem.eql(u8, decl.name, word)) return error.ReservedGeneratedName;
        if (std.mem.startsWith(u8, decl.name, "_mztl_")) return error.ReservedGeneratedName;
        if (dialect == .storage and (decl.explicit_id == null or decl.section == .functions)) return error.StorageRequiresExplicitConstructorIds;
        for (decl.fields) |field| {
            for (reserved) |word| if (std.mem.eql(u8, field.name, word)) return error.ReservedGeneratedName;
            if (std.mem.startsWith(u8, field.name, "_mztl_")) return error.ReservedGeneratedName;
            if (dialect == .telegram and field.since != null) return error.StorageAnnotationInTelegram;
        }
    }
    for (schema.types) |ty| {
        if (ty.external) return error.Unimplemented;
        for (reserved) |word| if (std.mem.eql(u8, ty.name, word)) return error.ReservedGeneratedName;
    }
}
