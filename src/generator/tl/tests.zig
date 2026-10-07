const std = @import("std");
const tl = @import("root.zig");
const a = std.testing.allocator;

test "boxed, bare, vectors, forward references and scoped variables" {
    const source =
        \\holder#1 boxed:Item bare:item explicit:%Item ints:Vector<int> items:vector<Item> nested:Vector<Vector<Item>> = Holder;
        \\item#2 value:int = Item;
        \\---functions---
        \\invoke#3 {X:Type} query:!X = X;
    ;
    var diag: ?tl.Diagnostic = null;
    var syntax = try tl.parse(a, source, &diag);
    defer syntax.deinit();
    var schema = try tl.analyze(a, &syntax, &diag);
    defer schema.deinit();
    const fields = schema.declarations[0].fields;
    try std.testing.expectEqual(.boxed, fields[0].type.encoding);
    try std.testing.expectEqual(.bare, fields[1].type.encoding);
    try std.testing.expectEqual(@as(usize, 1), fields[2].type.kind.constructor);
    try std.testing.expectEqual(.boxed, fields[3].type.encoding);
    try std.testing.expectEqual(.bare, fields[3].type.kind.vector.encoding);
    try std.testing.expectEqual(.bare, fields[4].type.encoding);
    try std.testing.expectEqual(.boxed, fields[4].type.kind.vector.encoding);
    try std.testing.expectEqual(.vector, std.meta.activeTag(fields[5].type.kind.vector.kind));
    try std.testing.expectEqual(@as(usize, 0), schema.declarations[2].result.kind.parameter);
    try std.testing.expectEqual(@as(usize, 0), schema.declarations[2].fields[0].type.kind.query.kind.parameter);
}

test "storage since metadata is independent of flags" {
    var diag: ?tl.Diagnostic = null;
    var syntax = try tl.parse(a, "meta#123 flags:# views:int edited_at:long @since(2) label:flags.0?string @since(3) = Meta;", &diag);
    defer syntax.deinit();
    var schema = try tl.analyze(a, &syntax, &diag);
    defer schema.deinit();
    const decl = schema.declarations[0];
    try std.testing.expectEqual(@as(u32, 3), decl.version);
    try std.testing.expectEqual(@as(u32, 1), decl.fields[1].since);
    try std.testing.expectEqual(@as(u32, 2), decl.fields[2].since);
    try std.testing.expectEqual(.required, decl.fields[2].presence);
    try std.testing.expectEqual(@as(usize, 0), decl.fields[3].presence.flag.field_index);
}

test "canonical IDs use entire declaration" {
    const cases = .{
        .{ "rpc_answer_dropped msg_id:long seq_no:int bytes:int = RpcDropAnswer;", 0xa43ad8b7 },
        .{ "msgs_ack msg_ids:Vector<long> = MsgsAck;", 0x62d6b459 },
        .{ "---functions--- invokeAfterMsg {X:Type} msg_id:long query:!X = X;", 0xcb9f372d },
        .{ "inputMessagesFilterPhoneCalls flags:# missed:flags.0?true = MessagesFilter;", 0x80c99768 },
        .{ "resPQ nonce:int128 server_nonce:int128 pq:bytes server_public_key_fingerprints:Vector<long> = ResPQ;", 0x05162463 },
    };
    inline for (cases) |case| {
        var diag: ?tl.Diagnostic = null;
        var syntax = try tl.parse(a, case[0], &diag);
        defer syntax.deinit();
        try std.testing.expectEqual(@as(u32, case[1]), try tl.ids.compute(a, syntax.declarations[0]));
    }
}

test "whitespace comments and equivalent vector syntax" {
    var diag: ?tl.Diagnostic = null;
    var syntax = try tl.parse(a, "/* hi */\r\n---functions---\nns.get#1\tvalues:(Vector int) = Vector int; // eof", &diag);
    defer syntax.deinit();
    var schema = try tl.analyze(a, &syntax, &diag);
    defer schema.deinit();
    try std.testing.expectEqual(.vector, std.meta.activeTag(schema.declarations[0].result.kind));
    try std.testing.expectEqualStrings("ns.get", syntax.declarations[0].name);
}

test "invalid syntax and semantics provide diagnostics" {
    const syntax_errors = [_][]const u8{
        "x = X",     "x#xyz = X;",              "/*",                                  "x a:Vector<> = X;",
        "x a: = X;", "x a:int @sincee(2) = X;", "vector {t:Type} # [ t ] = Vector t;",
    };
    for (syntax_errors) |source| {
        var diag: ?tl.Diagnostic = null;
        try std.testing.expectError(error.InvalidSyntax, tl.parse(a, source, &diag));
        try std.testing.expect(diag != null);
    }
    const semantic_errors = [_][]const u8{
        "x a:Missing = X;",                           "x a:flags.0?int flags:# = X;",
        "x flags:# a:flags.32?int = X;",              "x a:int a:long = X;",
        "x a:%X = X; y = X;",                         "x a:Vector<int,long> = X;",
        "x#1 = X; y#1 = Y;",                          "x a:!X = X;",
        "---functions--- invoke {X:Type} a:int = X;",
    };
    for (semantic_errors) |source| {
        var diag: ?tl.Diagnostic = null;
        var syntax = try tl.parse(a, source, &diag);
        defer syntax.deinit();
        try std.testing.expectError(error.InvalidSchema, tl.analyze(a, &syntax, &diag));
        try std.testing.expect(diag != null);
    }
}

fn allocationCase(allocator: std.mem.Allocator) !void {
    {
        var diag: ?tl.Diagnostic = null;
        var syntax = try tl.parse(allocator, "x#1 flags:# a:flags.0?true values:Vector<int> = X;", &diag);
        defer syntax.deinit();
        var schema = try tl.analyze(allocator, &syntax, &diag);
        defer schema.deinit();
    }
}

test "allocation failures release syntax and semantic arenas" {
    try std.testing.checkAllAllocationFailures(a, allocationCase, .{});
}

test "shared flags, multiple flag words and flag-only booleans" {
    var diag: ?tl.Diagnostic = null;
    var syntax = try tl.parse(a, "x flags:# flags2:# enabled:flags.31?true count:flags.31?int text:flags2.0?string = X;", &diag);
    defer syntax.deinit();
    var schema = try tl.analyze(a, &syntax, &diag);
    defer schema.deinit();
    const fields = schema.declarations[0].fields;
    try std.testing.expect(fields[2].presence.flag.flag_only);
    try std.testing.expectEqual(@as(u5, 31), fields[2].presence.flag.bit);
    try std.testing.expect(!fields[3].presence.flag.flag_only);
    try std.testing.expectEqual(fields[2].presence.flag.field_index, fields[3].presence.flag.field_index);
    try std.testing.expectEqual(@as(usize, 1), fields[4].presence.flag.field_index);
}

test "vector syntax variants have identical IDs and independent encoding" {
    const variants = [_][]const u8{
        "x values:Vector<int> = X;",
        "x values:(Vector int) = X;",
        "x values:Vector int = X;",
    };
    var expected: ?u32 = null;
    for (variants) |source| {
        var diag: ?tl.Diagnostic = null;
        var syntax = try tl.parse(a, source, &diag);
        defer syntax.deinit();
        var schema = try tl.analyze(a, &syntax, &diag);
        defer schema.deinit();
        if (expected) |id| try std.testing.expectEqual(id, schema.declarations[0].id);
        expected = schema.declarations[0].id;
    }
    var diag: ?tl.Diagnostic = null;
    var syntax = try tl.parse(a, "x a:%Vector<int> b:%(Vector Int) c:%Vector int d:vector<int> e:%Int f:Vector %Int = X;", &diag);
    defer syntax.deinit();
    var schema = try tl.analyze(a, &syntax, &diag);
    defer schema.deinit();
    const fields = schema.declarations[0].fields;
    for (fields[0..4]) |field| try std.testing.expectEqual(.bare, field.type.encoding);
    try std.testing.expectEqual(.boxed, fields[1].type.kind.vector.encoding);
    try std.testing.expectEqual(.bare, fields[4].type.encoding);
    try std.testing.expectEqual(.bare, fields[5].type.kind.vector.encoding);
}

test "multiple constructors and recursive namespace references" {
    var diag: ?tl.Diagnostic = null;
    var syntax = try tl.parse(a,
        \\ns.nil#1 = ns.List;
        \\ns.cons#2 next:ns.List = ns.List;
        \\holder#3 payload:ns.cons = Holder;
        \\---functions---
        \\ns.get#4 = ns.List;
        \\---types---
        \\end#5 = End;
    , &diag);
    defer syntax.deinit();
    var schema = try tl.analyze(a, &syntax, &diag);
    defer schema.deinit();
    try std.testing.expectEqual(@as(usize, 2), schema.types[0].constructors.len);
    try std.testing.expectEqual(@as(usize, 0), schema.declarations[1].fields[0].type.kind.boxed);
    try std.testing.expectEqual(@as(usize, 1), schema.declarations[2].fields[0].type.kind.constructor);
    try std.testing.expectEqual(.types, syntax.declarations[4].section);
}

test "grouped generic parameters retain identity and query direction" {
    var diag: ?tl.Diagnostic = null;
    var syntax = try tl.parse(a, "---functions--- invoke {X Y:Type} first:!X value:X second:!Y = Y;", &diag);
    defer syntax.deinit();
    var schema = try tl.analyze(a, &syntax, &diag);
    defer schema.deinit();
    const decl = schema.declarations[0];
    try std.testing.expectEqual(@as(usize, 0), decl.fields[1].type.kind.parameter);
    try std.testing.expectEqual(@as(usize, 1), decl.fields[2].type.kind.query.kind.parameter);
    try std.testing.expectEqual(@as(usize, 1), decl.result.kind.parameter);
}

test "storage errors never silently discard annotations" {
    const syntax_errors = [_][]const u8{
        "x#1 a:int @since(0) = X;",          "x#1 a:int @since(-1) = X;",
        "x#1 a:int @since(4294967296) = X;", "x#1 a:int @since(1_0) = X;",
        "x#1 a:int @other(2) = X;",          "x#1 a:int @since(2) @since(3) = X;",
    };
    for (syntax_errors) |source| {
        var diag: ?tl.Diagnostic = null;
        try std.testing.expectError(error.InvalidSyntax, tl.parse(a, source, &diag));
        try std.testing.expect(diag != null);
    }
}

test "empty schemas and source ownership" {
    var diag: ?tl.Diagnostic = null;
    var empty = try tl.parse(a, " // comment\n /* block */ ---types---", &diag);
    defer empty.deinit();
    var empty_schema = try tl.analyze(a, &empty, &diag);
    defer empty_schema.deinit();
    try std.testing.expectEqual(@as(usize, 0), empty_schema.declarations.len);
    const source = try a.dupe(u8, "ns /* comment */ . item#1 = ns.Item;");
    var syntax = tl.parse(a, source, &diag) catch |err| {
        a.free(source);
        return err;
    };
    a.free(source);
    defer syntax.deinit();
    var schema = try tl.analyze(a, &syntax, &diag);
    defer schema.deinit();
    try std.testing.expectEqualStrings("ns.item", syntax.declarations[0].name);
}

test "source locations and explicit IDs" {
    var diag: ?tl.Diagnostic = null;
    const source = "// heading\r\nx#abc value:Missing = X;";
    var syntax = try tl.parse(a, source, &diag);
    defer syntax.deinit();
    try std.testing.expectEqual(@as(u32, 0xabc), syntax.declarations[0].explicit_id.?);
    try std.testing.expectError(error.InvalidSchema, tl.analyze(a, &syntax, &diag));
    const loc = diag.?.location(source);
    try std.testing.expectEqual(@as(usize, 2), loc.line);
    try std.testing.expectEqual(@as(usize, 13), loc.column);
    var valid = try tl.parse(a, "x#abc = X;", &diag);
    defer valid.deinit();
    var schema = try tl.analyze(a, &valid, &diag);
    defer schema.deinit();
    try std.testing.expectEqual(@as(u32, 0xabc), schema.declarations[0].id);
}

test "external types are explicit and cannot become bare" {
    var diag: ?tl.Diagnostic = null;
    var syntax = try tl.parse(a, "---functions--- get#1 = External;", &diag);
    defer syntax.deinit();
    try std.testing.expectError(error.InvalidSchema, tl.analyze(a, &syntax, &diag));
    var schema = try tl.analyzeWithOptions(a, &syntax, .{ .external_types = &.{"External"} }, &diag);
    defer schema.deinit();
    try std.testing.expect(schema.types[0].external);
    var bare = try tl.parse(a, "x#1 value:%External = X;", &diag);
    defer bare.deinit();
    try std.testing.expectError(error.InvalidSchema, tl.analyzeWithOptions(a, &bare, .{ .external_types = &.{"External"} }, &diag));
}

test "semantic validation covers generic scope and invalid conditions" {
    const cases = [_][]const u8{
        "---functions--- f {X:Type} x:X query:!X = X;",
        "---functions--- f {X:Type} query:!X = Y;",
        "---functions--- f {X X:Type} query:!X = X;",
        "---functions--- f {X:Type} query:!X = X; g query:!X = X;",
        "x flag:int value:flag.0?int = X;",
        "x flags:# next:flags.0?# = X;",
        "x flags:# next:flags.0?int value:next.1?int = X;",
        "x value:%Bool = X;",
        "x value:Vector = X;",
        "x = X; x = Y;",
        "x value:true = X;",
    };
    for (cases) |source| {
        var diag: ?tl.Diagnostic = null;
        var syntax = try tl.parse(a, source, &diag);
        defer syntax.deinit();
        try std.testing.expectError(error.InvalidSchema, tl.analyze(a, &syntax, &diag));
        try std.testing.expect(diag != null);
    }
}

test "type nesting limit produces a diagnostic" {
    var source: std.ArrayList(u8) = .empty;
    defer source.deinit(a);
    try source.appendSlice(a, "x value:");
    for (0..130) |_| try source.appendSlice(a, "Vector<");
    try source.appendSlice(a, "int");
    for (0..130) |_| try source.append(a, '>');
    try source.appendSlice(a, " = X;");
    var diag: ?tl.Diagnostic = null;
    try std.testing.expectError(error.InvalidSyntax, tl.parse(a, source.items, &diag));
    try std.testing.expectEqualStrings("type nesting exceeds 128 levels", diag.?.message);
}
