const std = @import("std");
const tl = @import("tl_parser");
const gen = @import("generate.zig");

test "generator enforces dialect and generated-name boundaries before emitting code" {
    const cases = .{
        .{ "x value:int @since(2) = X;", .telegram, error.StorageAnnotationInTelegram },
        .{ "x value:int = X;", .storage, error.StorageRequiresExplicitConstructorIds },
        .{ "---functions--- get#1 = Int;", .storage, error.StorageRequiresExplicitConstructorIds },
        .{ "any#1 = AnyFunction;", .telegram, error.ReservedGeneratedName },
        .{ "x#1 serialize:int = X;", .storage, error.ReservedGeneratedName },
    };
    inline for (cases) |case| {
        var diagnostic: ?tl.Diagnostic = null;
        var syntax = try tl.parse(std.testing.allocator, case[0], &diagnostic);
        defer syntax.deinit();
        var schema = try tl.analyze(std.testing.allocator, &syntax, &diagnostic);
        defer schema.deinit();
        var output = std.Io.Writer.Allocating.init(std.testing.allocator);
        defer output.deinit();
        try std.testing.expectError(case[2], gen.generate(std.testing.allocator, &schema, case[1], &output.writer));
        try std.testing.expectEqual(@as(usize, 0), output.written().len);
    }
}

test "generator output owns no leaked temporary names or descriptors" {
    var diagnostic: ?tl.Diagnostic = null;
    var syntax = try tl.parse(std.testing.allocator, "x#1 value:int label:string @since(2) = X;", &diagnostic);
    defer syntax.deinit();
    var schema = try tl.analyze(std.testing.allocator, &syntax, &diagnostic);
    defer schema.deinit();
    var output = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer output.deinit();
    try gen.generate(std.testing.allocator, &schema, .storage, &output.writer);
    try std.testing.expect(std.mem.indexOf(u8, output.written(), ".since = 2") != null);
    try std.testing.expect(std.mem.indexOf(u8, output.written(), "pub const Decoded") != null);
}
