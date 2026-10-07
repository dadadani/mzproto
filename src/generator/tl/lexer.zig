const std = @import("std");
const ast = @import("ast.zig");

pub const Kind = enum {
    identifier,
    number,
    hash,
    colon,
    dot,
    question,
    equal,
    semicolon,
    lbrace,
    rbrace,
    lparen,
    rparen,
    langle,
    rangle,
    comma,
    percent,
    bang,
    at,
    types_section,
    functions_section,
    eof,
};
pub const Token = struct { kind: Kind, span: ast.Span };

pub fn tokenize(allocator: std.mem.Allocator, source: []const u8, diagnostic: *?ast.Diagnostic) ![]const Token {
    var tokens: std.ArrayList(Token) = .empty;
    errdefer tokens.deinit(allocator);
    var i: usize = 0;
    while (i < source.len) {

        if (std.ascii.isWhitespace(source[i])) {
            i += 1;
            continue;
        }

        if (std.mem.startsWith(u8, source[i..], "//")) {
            while (i < source.len and source[i] != '\n') : (i += 1) {}
            continue;
        }

        if (std.mem.startsWith(u8, source[i..], "/*")) {
            const start = i;
            const end = std.mem.indexOf(u8, source[i + 2 ..], "*/") orelse {
                diagnostic.* = .e(start, source.len, "unterminated block comment");
                return error.InvalidSyntax;
            };
            i += end + 4;
            continue;
        }
        const start = i;
        const kind: Kind = blk: {
            if (std.mem.startsWith(u8, source[i..], "---types---")) {
                i += "---types---".len;
                break :blk .types_section;
            }

            if (std.mem.startsWith(u8, source[i..], "---functions---")) {
                i += "---functions---".len;
                break :blk .functions_section;
            }

            if (std.ascii.isAlphanumeric(source[i]) or source[i] == '_') {
                const digit = std.ascii.isDigit(source[i]);
                i += 1;
                while (i < source.len and (std.ascii.isAlphanumeric(source[i]) or source[i] == '_')) : (i += 1) {}
                break :blk if (digit) .number else .identifier;
            }

            i += 1;

            break :blk switch (source[start]) {
                '#' => .hash, // flags?
                ':' => .colon,
                '.' => .dot,
                '?' => .question,
                '=' => .equal,
                ';' => .semicolon,
                '{' => .lbrace,
                '}' => .rbrace,
                '(' => .lparen,
                ')' => .rparen,
                '<' => .langle,
                '>' => .rangle,
                ',' => .comma,
                '%' => .percent, // bare obj
                '!' => .bang,
                '@' => .at,
                else => {
                    diagnostic.* = .e(start, i, "unsupported character or TL construct");

                    return error.InvalidSyntax;
                },
            };
        };

        try tokens.append(allocator, .{ .kind = kind, .span = .{ .start = start, .end = i } });
    }

    try tokens.append(allocator, .{ .kind = .eof, .span = .{ .start = i, .end = i } });
    return tokens.toOwnedSlice(allocator);
}
