const std = @import("std");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");

const Error = error{ InvalidSyntax, OutOfMemory };

pub fn parse(allocator: std.mem.Allocator, source: []const u8, diagnostic: *?ast.Diagnostic) Error!ast.Ast {
    diagnostic.* = null;

    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();

    const arena_allocator = arena.allocator();

    const owned = try arena_allocator.dupe(u8, source);
    var p: Parser = .{
        .source = owned,
        .tokens = try lexer.tokenize(arena_allocator, owned, diagnostic),
        .diagnostic = diagnostic,
    };

    var declarations: std.ArrayList(ast.Declaration) = .empty;
    var section: ast.Section = .types;

    while (p.peek() != .eof) {
        if (p.eat(.types_section)) {
            section = .types;
            continue;
        }

        if (p.eat(.functions_section)) {
            section = .functions;
            continue;
        }

        try declarations.append(arena_allocator, try p.declaration(arena_allocator, section));
    }

    const owned_declarations = try declarations.toOwnedSlice(arena_allocator);

    return .{ .arena = arena, .source = owned, .declarations = owned_declarations };
}

const Parser = struct {
    source: []const u8,
    tokens: []const lexer.Token,
    diagnostic: *?ast.Diagnostic,
    index: usize = 0,
    depth: usize = 0,

    fn peek(self: *Parser) lexer.Kind {
        return self.tokens[self.index].kind;
    }

    fn eat(self: *Parser, kind: lexer.Kind) bool {
        if (self.peek() != kind) return false;
        self.index += 1;
        return true;
    }

    fn fail(self: *Parser, message: []const u8) Error {
        self.diagnostic.* = .{ .span = self.tokens[self.index].span, .message = message };
        return error.InvalidSyntax;
    }

    fn expect(self: *Parser, kind: lexer.Kind, message: []const u8) Error!lexer.Token {
        const token = self.tokens[self.index];
        if (!self.eat(kind)) return self.fail(message);
        return token;
    }

    fn text(self: *Parser, token: lexer.Token) []const u8 {
        return self.source[token.span.start..token.span.end];
    }

    fn name(self: *Parser, allocator: std.mem.Allocator) Error![]u8 {
        const first = try self.expect(.identifier, "expected an identifier");
        var out: std.ArrayList(u8) = .empty;
        try out.appendSlice(allocator, self.text(first));
        while (self.eat(.dot)) {
            const member = try self.expect(.identifier, "expected a namespace member");
            try out.append(allocator, '.');
            try out.appendSlice(allocator, self.text(member));
        }
        return out.toOwnedSlice(allocator);
    }

    fn number(self: *Parser) Error!u32 {
        const token = try self.expect(.number, "expected a decimal integer");
        for (self.text(token)) |c| if (!std.ascii.isDigit(c)) return self.fail("invalid decimal integer");
        return std.fmt.parseInt(u32, self.text(token), 10) catch return self.fail("invalid decimal integer");
    }

    fn node(self: *Parser, allocator: std.mem.Allocator, start: usize, value: @FieldType(ast.TypeExpr, "value")) Error!*const ast.TypeExpr {
        const n = try allocator.create(ast.TypeExpr);
        n.* = .{ .span = .{ .start = start, .end = self.tokens[self.index - 1].span.end }, .value = value };
        return n;
    }

    fn atom(self: *Parser, allocator: std.mem.Allocator) Error!*const ast.TypeExpr {
        self.depth += 1;
        defer self.depth -= 1;

        if (self.depth > 128) return self.fail("type nesting exceeds 128 levels");

        const start = self.tokens[self.index].span.start;

        var n = blk: {
            if (self.eat(.percent)) break :blk try self.node(allocator, start, .{
                .bare = try self.atom(allocator),
            });

            if (self.eat(.bang)) break :blk try self.node(allocator, start, .{
                .bang = try self.atom(allocator),
            });

            if (self.eat(.hash)) break :blk try self.node(allocator, start, .natural);

            if (self.eat(.lparen)) {
                const inner = try self.expression(allocator, true);
                _ = try self.expect(.rparen, "expected ')' after type expression");
                break :blk inner;
            }

            break :blk try self.node(allocator, start, .{ .name = try self.name(allocator) });
        };

        while (self.eat(.langle)) {
            var args: std.ArrayList(*const ast.TypeExpr) = .empty;
            try args.append(allocator, try self.expression(allocator, true));

            while (self.eat(.comma)) try args.append(allocator, try self.expression(allocator, true));

            _ = try self.expect(.rangle, "expected '>' after type arguments");
            n = try self.node(allocator, start, .{ .application = .{ .head = n, .args = try args.toOwnedSlice(allocator) } });
        }

        return n;
    }

    fn expression(self: *Parser, allocator: std.mem.Allocator, space_application: bool) Error!*const ast.TypeExpr {
        const head = try self.atom(allocator);
        var args: std.ArrayList(*const ast.TypeExpr) = .empty;

        while (switch (self.peek()) {
            .identifier, .lparen, .percent, .bang => true,
            else => false,
        }) {
            if (!space_application and self.peek() == .identifier and self.tokens[self.index + 1].kind == .colon) break;
            try args.append(allocator, try self.atom(allocator));
        }

        if (args.items.len == 0) return head;

        return self.node(allocator, head.span.start, .{
            .application = .{ .head = head, .args = try args.toOwnedSlice(allocator) },
        });
    }

    fn declaration(self: *Parser, allocator: std.mem.Allocator, section: ast.Section) Error!ast.Declaration {
        const start = self.tokens[self.index].span.start;
        const declaration_name = try self.name(allocator);

        var id: ?u32 = null;
        if (self.eat(.hash)) {
            const token = self.tokens[self.index];
            if (token.kind != .number and token.kind != .identifier) return self.fail("expected a hexadecimal constructor ID");

            const hex = self.text(token);
            if (hex.len == 0 or hex.len > 8) return self.fail("constructor ID must contain 1 to 8 hexadecimal digits");
            for (hex) |c| if (!std.ascii.isHex(c)) return self.fail("invalid hexadecimal constructor ID");

            id = std.fmt.parseInt(u32, hex, 16) catch return self.fail("invalid hexadecimal constructor ID");

            self.index += 1;
        }

        var parameters: std.ArrayList(ast.TypeParameter) = .empty;

        while (self.eat(.lbrace)) {
            var names: std.ArrayList(ast.TypeParameter) = .empty;
            while (self.peek() == .identifier) {
                const token = try self.expect(.identifier, "expected a type parameter");
                try names.append(allocator, .{ .name = self.text(token), .span = token.span });
            }

            if (names.items.len == 0) return self.fail("expected a type parameter");
            _ = try self.expect(.colon, "expected ':' in type parameter declaration");

            const kind = try self.expect(.identifier, "only implicit Type parameters are supported");
            if (!std.mem.eql(u8, self.text(kind), "Type")) return self.fail("only implicit Type parameters are supported");

            _ = try self.expect(.rbrace, "expected '}' after type parameters");

            try parameters.appendSlice(allocator, names.items);
        }

        var fields: std.ArrayList(ast.Field) = .empty;
        while (self.peek() != .equal) {
            const token = try self.expect(.identifier, "expected a named field or '='; this TL construct is unsupported");
            _ = try self.expect(.colon, "expected ':' after field name");

            var condition: ?ast.Condition = null;

            if (self.peek() == .identifier and self.tokens[self.index + 1].kind == .dot and self.tokens[self.index + 2].kind == .number) {
                const flag = self.tokens[self.index];
                self.index += 2;
                const bit = try self.number();
                _ = try self.expect(.question, "expected '?' after flag bit");
                condition = .{ .field = self.text(flag), .bit = bit, .span = .{ .start = flag.span.start, .end = self.tokens[self.index - 1].span.end } };
            }

            const ty = try self.expression(allocator, false);
            var since: ?u32 = null;

            if (self.eat(.at)) {
                const annotation = try self.expect(.identifier, "expected 'since' annotation");
                if (!std.mem.eql(u8, self.text(annotation), "since")) return self.fail("unknown annotation; expected @since(version)");

                _ = try self.expect(.lparen, "expected '(' after @since");

                since = try self.number();
                if (since.? == 0) return self.fail("storage versions start at 1");

                _ = try self.expect(.rparen, "expected ')' after version");
            }

            try fields.append(allocator, .{ .name = self.text(token), .type = ty, .condition = condition, .since = since, .span = .{ .start = token.span.start, .end = self.tokens[self.index - 1].span.end } });
        }

        _ = try self.expect(.equal, "expected '='");

        const result = try self.expression(allocator, true);

        const end = try self.expect(.semicolon, "expected ';' after declaration");

        return .{ .name = declaration_name, .explicit_id = id, .section = section, .type_parameters = try parameters.toOwnedSlice(allocator), .fields = try fields.toOwnedSlice(allocator), .result = result, .span = .{ .start = start, .end = end.span.end } };
    }
};
