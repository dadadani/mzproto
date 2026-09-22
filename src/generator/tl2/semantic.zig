const std = @import("std");
const ast = @import("ast.zig");
const ids = @import("ids.zig");

pub const Encoding = enum { bare, boxed, inferred };
pub const Builtin = enum { int, long, double, string, bytes, int128, int256, boolean, true_value, object };
pub const Type = struct {
    encoding: Encoding,
    kind: union(enum) {
        builtin: Builtin,
        natural,
        /// Index into Schema.types.
        boxed: usize,
        /// Index into Schema.declarations, selecting one constructor's payload.
        constructor: usize,
        vector: *const Type,
        /// Index into the enclosing declaration's AST type_parameters.
        parameter: usize,
        /// !X: a query whose result provides X, not an ordinary value of X.
        query: *const Type,
    },
};
pub const Presence = union(enum) {
    required,
    flag: struct { field_index: usize, bit: u5, flag_only: bool },
};
pub const Field = struct { type: *const Type, presence: Presence, since: u32 };
pub const Declaration = struct { id: u32, fields: []const Field, result: *const Type, version: u32 };
pub const BoxedType = struct { name: []const u8, constructors: []const usize, external: bool = false };
pub const Options = struct {
    /// Boxed types implemented outside the schema, e.g. hand-written MTProto codecs.
    external_types: []const []const u8 = &.{},
};

/// Owns resolved nodes; borrows syntax. Deinitialize this before its Ast.
pub const Schema = struct {
    arena: std.heap.ArenaAllocator,
    syntax: *const ast.Ast,
    declarations: []const Declaration,
    types: []const BoxedType,

    pub fn deinit(self: *Schema) void {
        self.arena.deinit();
        self.* = undefined;
    }
};

const Error = error{ InvalidSchema, OutOfMemory };

const BuiltinInfo = struct { kind: Builtin, encoding: Encoding };
pub fn builtin(name: []const u8) ?BuiltinInfo {
    const Entry = struct { []const u8, Builtin, Encoding };
    const entries = [_]Entry{
        .{ "int", .int, .bare },         .{ "Int", .int, .boxed },
        .{ "long", .long, .bare },       .{ "Long", .long, .boxed },
        .{ "double", .double, .bare },   .{ "Double", .double, .boxed },
        .{ "string", .string, .bare },   .{ "String", .string, .boxed },
        .{ "bytes", .bytes, .bare },     .{ "int128", .int128, .bare },
        .{ "Int128", .int128, .boxed },  .{ "int256", .int256, .bare },
        .{ "Int256", .int256, .boxed },  .{ "Bool", .boolean, .boxed },
        .{ "true", .true_value, .bare }, .{ "True", .true_value, .boxed },
        .{ "Object", .object, .boxed },
    };
    for (entries) |entry| if (std.mem.eql(u8, name, entry[0])) return .{ .kind = entry[1], .encoding = entry[2] };
    return null;
}

fn lastName(name: []const u8) []const u8 {
    return name[if (std.mem.lastIndexOfScalar(u8, name, '.')) |i| i + 1 else 0..];
}
fn isVector(name: []const u8) bool {
    return std.mem.eql(u8, name, "Vector") or std.mem.eql(u8, name, "vector");
}

pub fn analyze(allocator: std.mem.Allocator, syntax: *const ast.Ast, diagnostic: *?ast.Diagnostic) Error!Schema {
    return analyzeWithOptions(allocator, syntax, .{}, diagnostic);
}

pub fn analyzeWithOptions(gpa: std.mem.Allocator, syntax: *const ast.Ast, options: Options, diagnostic: *?ast.Diagnostic) Error!Schema {
    diagnostic.* = null;
    var arena = std.heap.ArenaAllocator.init(gpa);
    const allocator = arena.allocator();
    errdefer arena.deinit();
    var ctx: Context = .{ .syntax = syntax, .diagnostic = diagnostic };
    for (options.external_types) |external_name| {
        if (external_name.len == 0 or lastName(external_name).len == 0 or !std.ascii.isUpper(lastName(external_name)[0]) or builtin(external_name) != null or isVector(external_name)) return ctx.fail(.{ .start = 0, .end = 0 }, "external types must have non-builtin boxed type names");
        const name = try allocator.dupe(u8, external_name);
        const entry = try ctx.type_names.getOrPut(allocator, name);
        if (entry.found_existing) return ctx.fail(.{ .start = 0, .end = 0 }, "duplicate external type");
        entry.value_ptr.* = ctx.types.items.len;
        try ctx.types.append(allocator, .{ .name = name, .constructors = &.{}, .external = true });
    }
    // Register every declaration and result type first, so forward references work.
    for (syntax.declarations, 0..) |decl, index| {
        if (!std.ascii.isLower(lastName(decl.name)[0])) return ctx.fail(decl.span, "constructor and function names must start with a lowercase letter");
        if (builtin(decl.name) != null or isVector(decl.name)) return ctx.fail(decl.span, "builtin declarations are supplied by the registry; redefining them is unsupported");
        const entry = try ctx.names.getOrPut(allocator, decl.name);
        if (entry.found_existing) return ctx.fail(decl.span, "duplicate declaration name");
        entry.value_ptr.* = index;

        if (decl.section == .types) {
            if (decl.type_parameters.len != 0) return ctx.fail(decl.span, "user-defined generic type constructors are unsupported");
            if (decl.result.value != .name) return ctx.fail(decl.result.span, "constructor result must be a named boxed type");
            const name = decl.result.value.name;
            if (!std.ascii.isUpper(lastName(name)[0])) return ctx.fail(decl.result.span, "constructor result must be a boxed type");
            if (builtin(name) != null or isVector(name)) return ctx.fail(decl.result.span, "redefining builtin types is unsupported");
            const type_entry = try ctx.type_names.getOrPut(allocator, name);
            if (type_entry.found_existing and ctx.types.items[type_entry.value_ptr.*].external) return ctx.fail(decl.result.span, "cannot redefine an external type");
            if (!type_entry.found_existing) {
                type_entry.value_ptr.* = ctx.types.items.len;
                try ctx.types.append(allocator, .{ .name = name, .constructors = &.{} });
            }
        }
    }
    var lists = try allocator.alloc(std.ArrayList(usize), ctx.types.items.len);
    @memset(lists, .empty);
    for (syntax.declarations, 0..) |decl, index| {
        if (decl.section == .types) try lists[ctx.type_names.get(decl.result.value.name).?].append(allocator, index);
    }
    for (ctx.types.items, lists) |*ty, *list| ty.constructors = try list.toOwnedSlice(allocator);

    var declarations: std.ArrayList(Declaration) = .empty;
    var id_map: std.AutoHashMapUnmanaged(u32, void) = .empty;

    for (syntax.declarations) |decl| {
        const id = decl.explicit_id orelse try ids.compute(allocator, decl);

        if ((try id_map.getOrPut(allocator, id)).found_existing) return ctx.fail(decl.span, "duplicate constructor ID");

        var local_names: std.StringHashMapUnmanaged(void) = .empty;

        for (decl.type_parameters) |parameter| {
            if (builtin(parameter.name) != null or isVector(parameter.name) or ctx.type_names.contains(parameter.name)) return ctx.fail(parameter.span, "type parameter shadows an existing type");

            if ((try local_names.getOrPut(allocator, parameter.name)).found_existing) return ctx.fail(parameter.span, "duplicate type parameter");
        }
        var fields: std.ArrayList(Field) = .empty;
        const inferred = try allocator.alloc(bool, decl.type_parameters.len);
        @memset(inferred, false);
        var version: u32 = 1;
        for (decl.fields, 0..) |field, field_index| {
            if ((try local_names.getOrPut(allocator, field.name)).found_existing) return ctx.fail(field.span, "duplicate field or type parameter name");
            const ty = try ctx.resolve(allocator, field.type, decl);
            if (ty.kind == .query) {
                inferred[ty.kind.query.kind.parameter] = true;
            } else if (!parametersKnown(ty, inferred)) return ctx.fail(field.type.span, "type parameter must be inferred from a preceding !X query field");
            const since = field.since orelse 1;
            version = @max(version, since);
            var presence: Presence = .required;
            if (field.condition) |condition| {
                if (condition.bit > 31) return ctx.fail(condition.span, "flag bit must be between 0 and 31");
                const flag_index = for (decl.fields[0..field_index], 0..) |previous, i| {
                    if (std.mem.eql(u8, previous.name, condition.field)) break i;
                } else return ctx.fail(condition.span, "condition must reference a preceding # field");
                const flag = fields.items[flag_index];
                if (flag.type.kind != .natural or flag.presence != .required) return ctx.fail(condition.span, "condition must reference an unconditional # field");
                if (since < flag.since) return ctx.fail(field.span, "conditional field cannot predate its flag word");
                if (ty.kind == .natural or ty.kind == .query) return ctx.fail(field.span, "conditional # fields and queries are unsupported");
                presence = .{ .flag = .{ .field_index = flag_index, .bit = @intCast(condition.bit), .flag_only = ty.kind == .builtin and ty.kind.builtin == .true_value and ty.encoding == .bare } };
            }
            if (ty.kind == .builtin and ty.kind.builtin == .true_value and ty.encoding == .bare and presence == .required) return ctx.fail(field.span, "bare true is supported only as a flag-only field");
            try fields.append(allocator, .{ .type = ty, .presence = presence, .since = since });
        }
        const result = try ctx.resolve(allocator, decl.result, decl);
        if (result.kind == .natural or result.kind == .query) return ctx.fail(decl.result.span, "unsupported result type");
        // In Telegram wrappers each implicit parameter must be inferred from a !X input.
        for (decl.type_parameters, inferred) |parameter, known| {
            if (!known) return ctx.fail(parameter.span, "type parameter must be inferred from a !X query field");
        }
        try declarations.append(allocator, .{ .id = id, .fields = try fields.toOwnedSlice(allocator), .result = result, .version = version });
    }
    const owned_declarations = try declarations.toOwnedSlice(allocator);
    const owned_types = try ctx.types.toOwnedSlice(allocator);
    return .{ .arena = arena, .syntax = syntax, .declarations = owned_declarations, .types = owned_types };
}

fn parametersKnown(ty: *const Type, inferred: []const bool) bool {
    return switch (ty.kind) {
        .parameter => |index| inferred[index],
        .vector => |element| parametersKnown(element, inferred),
        else => true,
    };
}

const Context = struct {
    syntax: *const ast.Ast,
    diagnostic: *?ast.Diagnostic,
    names: std.StringHashMapUnmanaged(usize) = .empty,
    type_names: std.StringHashMapUnmanaged(usize) = .empty,
    types: std.ArrayList(BoxedType) = .empty,

    fn fail(self: *Context, span: ast.Span, message: []const u8) Error {
        self.diagnostic.* = .{ .span = span, .message = message };
        return error.InvalidSchema;
    }
    fn make(allocator: std.mem.Allocator, encoding: Encoding, kind: @FieldType(Type, "kind")) Error!*const Type {
        const ty = try allocator.create(Type);
        ty.* = .{ .encoding = encoding, .kind = kind };
        return ty;
    }
    fn resolve(self: *Context, allocator: std.mem.Allocator, expr: *const ast.TypeExpr, decl: ast.Declaration) Error!*const Type {
        switch (expr.value) {
            .natural => return make(allocator, .bare, .natural),
            .name => |name| {
                for (decl.type_parameters, 0..) |parameter, i| {
                    if (std.mem.eql(u8, parameter.name, name)) return make(allocator, .inferred, .{ .parameter = i });
                }

                if (builtin(name)) |info| return make(allocator, info.encoding, .{ .builtin = info.kind });

                if (isVector(name)) return self.fail(expr.span, "Vector/vector requires exactly one type argument");

                if (self.type_names.get(name)) |i| return make(allocator, .boxed, .{ .boxed = i });

                if (self.names.get(name)) |i| {
                    if (self.syntax.declarations[i].section != .types) return self.fail(expr.span, "a function cannot be used as a bare type");
                    return make(allocator, .bare, .{ .constructor = i });
                }

                return self.fail(expr.span, "unknown type or constructor");
            },
            .bare => |inner| return self.asBare(allocator, try self.resolve(allocator, inner, decl), expr.span),
            .bang => |inner| {
                if (decl.section != .functions) {
                    return self.fail(expr.span, "! is supported only on function query fields");
                }

                const ty = try self.resolve(allocator, inner, decl);
                if (ty.kind != .parameter) {
                    return self.fail(expr.span, "only !TypeParameter query expressions are supported");
                }

                return make(allocator, .boxed, .{ .query = ty });
            },
            .application => |app| {
                var head = app.head;
                var bare = false;

                while (head.value == .bare) {
                    bare = true;
                    head = head.value.bare;
                }

                if (head.value != .name or !isVector(head.value.name)) {
                    return self.fail(expr.span, "only Vector/vector type applications are supported");
                }
                if (app.args.len != 1) {
                    return self.fail(expr.span, "Vector/vector requires exactly one type argument");
                }

                const element = try self.resolve(allocator, app.args[0], decl);

                if (element.kind == .natural or element.kind == .query or (element.kind == .builtin and element.kind.builtin == .true_value and element.encoding == .bare)) {
                    return self.fail(app.args[0].span, "unsupported vector element type");
                }

                return make(allocator, if (bare or std.mem.eql(u8, head.value.name, "vector")) .bare else .boxed, .{ .vector = element });
            },
        }
    }
    fn asBare(self: *Context, allocator: std.mem.Allocator, ty: *const Type, span: ast.Span) Error!*const Type {
        if (ty.encoding == .bare) return ty;
        return switch (ty.kind) {
            .boxed => |index| blk: {
                const constructors = self.types.items[index].constructors;
                if (constructors.len != 1) return self.fail(span, "%Type requires exactly one constructor");
                break :blk make(allocator, .bare, .{ .constructor = constructors[0] });
            },
            .vector => |element| make(allocator, .bare, .{ .vector = element }),
            .builtin => |kind| switch (kind) {
                .boolean, .object => self.fail(span, "this builtin has no unambiguous bare representation"),
                else => make(allocator, .bare, .{ .builtin = kind }),
            },
            else => self.fail(span, "cannot resolve a bare representation for this type"),
        };
    }
};
