const std = @import("std");

pub const Span = struct { start: usize, end: usize };
pub const Section = enum { types, functions };

pub const Diagnostic = struct {
    span: Span,
    message: []const u8,

    pub fn e(start: usize, end: usize, msg: []const u8) Diagnostic {
        return .{
            .span = .{ .end = end, .start = start },
            .message = msg,
        };
    }

    pub fn location(self: Diagnostic, source: []const u8) struct { line: usize, column: usize } {
        var line: usize = 1;
        var column: usize = 1;
        for (source[0..@min(self.span.start, source.len)]) |c| {
            if (c == '\n') {
                line += 1;
                column = 1;
            } else column += 1;
        }
        return .{ .line = line, .column = column };
    }
};

pub const TypeExpr = struct {
    span: Span,
    value: union(enum) {
        name: []const u8,
        natural,
        application: struct { head: *const TypeExpr, args: []const *const TypeExpr },
        bare: *const TypeExpr,
        bang: *const TypeExpr,
    },
};

pub const TypeParameter = struct { name: []const u8, span: Span };
pub const Condition = struct { field: []const u8, bit: u32, span: Span };
pub const Field = struct {
    name: []const u8,
    type: *const TypeExpr,
    condition: ?Condition,
    /// Null means no annotation was written; the effective version is one.
    since: ?u32,
    span: Span,
};
pub const Declaration = struct {
    name: []const u8,
    explicit_id: ?u32,
    section: Section,
    type_parameters: []const TypeParameter,
    fields: []const Field,
    result: *const TypeExpr,
    span: Span,
};

/// Owns the source and all syntax nodes. Source slices remain valid until deinit.
pub const Ast = struct {
    arena: std.heap.ArenaAllocator,
    source: []const u8,
    declarations: []const Declaration,

    pub fn deinit(self: *Ast) void {
        self.arena.deinit();
        self.* = undefined;
    }
};
