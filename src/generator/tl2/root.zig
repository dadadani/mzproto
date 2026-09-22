//! Telegram-focused TL syntax and semantics, with an opt-in storage dialect.
pub const ast = @import("ast.zig");
pub const lexer = @import("lexer.zig");
pub const semantic = @import("semantic.zig");
pub const ids = @import("ids.zig");
pub const parse = @import("parser.zig").parse;
pub const Options = @import("parser.zig").Options;
pub const analyze = semantic.analyze;
pub const analyzeWithOptions = semantic.analyzeWithOptions;
pub const Ast = ast.Ast;
pub const Schema = semantic.Schema;
pub const Diagnostic = ast.Diagnostic;

test {
    _ = @import("tests.zig");
}
