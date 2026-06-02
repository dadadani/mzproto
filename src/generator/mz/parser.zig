const std = @import("std");

pub const ParseError = error{
    ExpectedIdentifier,
    ExpectedColon,
    ExpectedFunctionKeyword,
    ExpectedOpenBrace,
    ExpectedOpenParen,
    ExpectedCloseParen,
    ExpectedCloseBrace,
    ExpectedComma,
    ExpectedEquals,
    ExpectedReturnType,
    InvalidDeclaration,
    InvalidDeclarationKind,
    InvalidEnumValue,
    UnexpectedToken,
    UnexpectedEndOfInput,
};

const ParserError = ParseError || std.mem.Allocator.Error;

pub const Schema = struct {
    allocator: std.mem.Allocator,
    source: []u8,
    declarations: std.ArrayListUnmanaged(Declaration) = .empty,

    pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Schema {
        const owned = try allocator.dupe(u8, input);
        errdefer allocator.free(owned);
        return parseOwned(allocator, owned);
    }

    pub fn parseOwned(allocator: std.mem.Allocator, owned_input: []u8) !Schema {
        var parser = Parser{
            .allocator = allocator,
            .source = owned_input,
        };
        return parser.parse();
    }
    
    pub fn deinit(self: *Schema) void {
        for (self.declarations.items) |*declaration| {
            declaration.deinit(self.allocator);
        }
        self.declarations.deinit(self.allocator);
        self.allocator.free(self.source);
    }
};

pub const Declaration = union(enum) {
    enum_decl: EnumDecl,
    struct_decl: StructDecl,
    union_decl: UnionDecl,
    opaque_decl: OpaqueDecl,
    function_decl: FunctionDecl,

    pub fn deinit(self: *Declaration, allocator: std.mem.Allocator) void {
        switch (self.*) {
            inline else => |*declaration| declaration.deinit(allocator),
        }
    }
};

pub const EnumDecl = struct {
    doc: ?[]u8,
    name: []const u8,
    items: std.ArrayListUnmanaged(EnumItem) = .empty,

    pub fn deinit(self: *EnumDecl, allocator: std.mem.Allocator) void {
        freeDoc(allocator, self.doc);
        for (self.items.items) |*item| {
            item.deinit(allocator);
        }
        self.items.deinit(allocator);
    }
};

pub const EnumItem = struct {
    doc: ?[]u8,
    name: []const u8,
    value: i64,

    pub fn deinit(self: *EnumItem, allocator: std.mem.Allocator) void {
        freeDoc(allocator, self.doc);
    }
};

pub const StructDecl = struct {
    doc: ?[]u8,
    name: []const u8,
    fields: std.ArrayListUnmanaged(Field) = .empty,

    pub fn deinit(self: *StructDecl, allocator: std.mem.Allocator) void {
        freeDoc(allocator, self.doc);
        for (self.fields.items) |*field| {
            field.deinit(allocator);
        }
        self.fields.deinit(allocator);
    }
};

pub const UnionDecl = struct {
    doc: ?[]u8,
    name: []const u8,
    fields: std.ArrayListUnmanaged(Field) = .empty,

    pub fn deinit(self: *UnionDecl, allocator: std.mem.Allocator) void {
        freeDoc(allocator, self.doc);
        for (self.fields.items) |*field| {
            field.deinit(allocator);
        }
        self.fields.deinit(allocator);
    }
};

pub const OpaqueDecl = struct {
    doc: ?[]u8,
    name: []const u8,
    methods: std.ArrayListUnmanaged(FunctionDecl) = .empty,

    pub fn deinit(self: *OpaqueDecl, allocator: std.mem.Allocator) void {
        freeDoc(allocator, self.doc);
        for (self.methods.items) |*method| {
            method.deinit(allocator);
        }
        self.methods.deinit(allocator);
    }
};

pub const ExecutionMode = enum {
    asynchronous,
    sync,
};

pub const FunctionDecl = struct {
    doc: ?[]u8,
    name: []const u8,
    mode: ExecutionMode = .asynchronous,
    params: std.ArrayListUnmanaged(Parameter) = .empty,
    return_type: *TypeExpr,

    pub fn deinit(self: *FunctionDecl, allocator: std.mem.Allocator) void {
        freeDoc(allocator, self.doc);
        for (self.params.items) |*parameter| {
            parameter.deinit(allocator);
        }
        self.params.deinit(allocator);
        self.return_type.deinit(allocator);
    }
};

pub const Field = struct {
    doc: ?[]u8,
    name: []const u8,
    type_expr: *TypeExpr,

    pub fn deinit(self: *Field, allocator: std.mem.Allocator) void {
        freeDoc(allocator, self.doc);
        self.type_expr.deinit(allocator);
    }
};

pub const Parameter = struct {
    name: []const u8,
    type_expr: *TypeExpr,

    pub fn deinit(self: *Parameter, allocator: std.mem.Allocator) void {
        self.type_expr.deinit(allocator);
    }
};

pub const TypeExpr = union(enum) {
    named: []const u8,
    optional: *TypeExpr,
    reference: *TypeExpr,
    list: *TypeExpr,
    function: FunctionSignature,

    pub fn deinit(self: *TypeExpr, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .named => {},
            .optional => |child| child.deinit(allocator),
            .reference => |child| child.deinit(allocator),
            .list => |child| child.deinit(allocator),
            .function => |*signature| signature.deinit(allocator),
        }
        allocator.destroy(self);
    }
};

pub const FunctionSignature = struct {
    mode: ExecutionMode = .asynchronous,
    params: std.ArrayListUnmanaged(Parameter) = .empty,
    return_type: *TypeExpr,

    pub fn deinit(self: *FunctionSignature, allocator: std.mem.Allocator) void {
        for (self.params.items) |*parameter| {
            parameter.deinit(allocator);
        }
        self.params.deinit(allocator);
        self.return_type.deinit(allocator);
    }
};

const Parser = struct {
    allocator: std.mem.Allocator,
    source: []u8,
    pending_doc: std.ArrayListUnmanaged(u8) = .empty,

    fn parse(self: *Parser) ParserError!Schema {
        var schema = Schema{
            .allocator = self.allocator,
            .source = self.source,
        };
        errdefer schema.deinit();
        defer self.pending_doc.deinit(self.allocator);

        var lines = LineIterator{ .source = self.source };
        while (lines.next()) |line| {
            const trimmed = trimLine(line);
            if (trimmed.len == 0) {
                self.clearPendingDoc();
                continue;
            }

            if (std.mem.startsWith(u8, trimmed, "//")) {
                try self.pushDocLine(commentText(trimmed));
                continue;
            }

            const code = trimLine(stripInlineComment(line));
            if (code.len == 0) {
                self.clearPendingDoc();
                continue;
            }
            if (isClosingBrace(code)) {
                return ParseError.UnexpectedToken;
            }

            const declaration = try self.parseDeclaration(&lines, code, try self.takePendingDoc());
            errdefer {
                var cleanup = declaration;
                cleanup.deinit(self.allocator);
            }
            try schema.declarations.append(self.allocator, declaration);
        }

        return schema;
    }

    fn parseDeclaration(self: *Parser, lines: *LineIterator, line: []const u8, doc: ?[]u8) ParserError!Declaration {
        var cursor = Cursor{ .text = line };
        const name = try cursor.parseIdentifier();
        try cursor.expectByte(':', ParseError.ExpectedColon);

        if (cursor.consumeKeyword("enum")) {
            try cursor.expectByte('{', ParseError.ExpectedOpenBrace);
            try cursor.expectEnd();

            var decl = EnumDecl{ .doc = doc, .name = name };
            errdefer decl.deinit(self.allocator);
            try self.parseEnumBody(lines, &decl);
            return .{ .enum_decl = decl };
        }

        if (cursor.consumeKeyword("struct")) {
            try cursor.expectByte('{', ParseError.ExpectedOpenBrace);
            try cursor.expectEnd();

            var decl = StructDecl{ .doc = doc, .name = name };
            errdefer decl.deinit(self.allocator);
            try self.parseFieldBody(lines, &decl.fields);
            return .{ .struct_decl = decl };
        }

        if (cursor.consumeKeyword("union")) {
            try cursor.expectByte('{', ParseError.ExpectedOpenBrace);
            try cursor.expectEnd();

            var decl = UnionDecl{ .doc = doc, .name = name };
            errdefer decl.deinit(self.allocator);
            try self.parseFieldBody(lines, &decl.fields);
            return .{ .union_decl = decl };
        }

        if (cursor.consumeKeyword("opaque")) {
            try cursor.expectByte('{', ParseError.ExpectedOpenBrace);
            try cursor.expectEnd();

            var decl = OpaqueDecl{ .doc = doc, .name = name };
            errdefer decl.deinit(self.allocator);
            try self.parseOpaqueBody(lines, &decl);
            return .{ .opaque_decl = decl };
        }

        if (try self.maybeParseFunctionDecl(name, doc, &cursor)) |function| {
            errdefer function.deinit(self.allocator);
            return .{ .function_decl = function };
        }

        return ParseError.InvalidDeclarationKind;
    }

    fn parseEnumBody(self: *Parser, lines: *LineIterator, decl: *EnumDecl) ParserError!void {
        var docs = DocCollector{};
        defer docs.deinit(self.allocator);

        while (lines.next()) |line| {
            const trimmed = trimLine(line);
            if (trimmed.len == 0) {
                docs.clear();
                continue;
            }

            if (std.mem.startsWith(u8, trimmed, "//")) {
                try docs.push(self.allocator, commentText(trimmed));
                continue;
            }

            const code = trimLine(stripInlineComment(line));
            if (code.len == 0) {
                docs.clear();
                continue;
            }
            if (isClosingBrace(code)) {
                docs.clear();
                return;
            }

            var item = try self.parseEnumItem(code, try docs.take(self.allocator));
            errdefer item.deinit(self.allocator);
            try decl.items.append(self.allocator, item);
        }

        return ParseError.ExpectedCloseBrace;
    }

    fn parseFieldBody(self: *Parser, lines: *LineIterator, fields: *std.ArrayListUnmanaged(Field)) ParserError!void {
        var docs = DocCollector{};
        defer docs.deinit(self.allocator);

        while (lines.next()) |line| {
            const trimmed = trimLine(line);
            if (trimmed.len == 0) {
                docs.clear();
                continue;
            }

            if (std.mem.startsWith(u8, trimmed, "//")) {
                try docs.push(self.allocator, commentText(trimmed));
                continue;
            }

            const code = trimLine(stripInlineComment(line));
            if (code.len == 0) {
                docs.clear();
                continue;
            }
            if (isClosingBrace(code)) {
                docs.clear();
                return;
            }

            var field = try self.parseField(code, try docs.take(self.allocator));
            errdefer field.deinit(self.allocator);
            try fields.append(self.allocator, field);
        }

        return ParseError.ExpectedCloseBrace;
    }

    fn parseOpaqueBody(self: *Parser, lines: *LineIterator, decl: *OpaqueDecl) ParserError!void {
        var docs = DocCollector{};
        defer docs.deinit(self.allocator);

        while (lines.next()) |line| {
            const trimmed = trimLine(line);
            if (trimmed.len == 0) {
                docs.clear();
                continue;
            }

            if (std.mem.startsWith(u8, trimmed, "//")) {
                try docs.push(self.allocator, commentText(trimmed));
                continue;
            }

            const code = trimLine(stripInlineComment(line));
            if (code.len == 0) {
                docs.clear();
                continue;
            }
            if (isClosingBrace(code)) {
                docs.clear();
                return;
            }

            var method = try self.parseOpaqueMethod(code, try docs.take(self.allocator));
            errdefer method.deinit(self.allocator);
            try decl.methods.append(self.allocator, method);
        }

        return ParseError.ExpectedCloseBrace;
    }

    fn parseEnumItem(_: *Parser, line: []const u8, doc: ?[]u8) ParserError!EnumItem {
        var cursor = Cursor{ .text = line };
        const name = try cursor.parseIdentifier();
        try cursor.expectByte('=', ParseError.ExpectedEquals);
        const value_text = try cursor.parseIdentifier();
        const value = std.fmt.parseInt(i64, value_text, 10) catch return ParseError.InvalidEnumValue;
        cursor.skipSpaces();
        _ = cursor.consumeOptionalByte(',');
        try cursor.expectEnd();

        return .{
            .doc = doc,
            .name = name,
            .value = value,
        };
    }

    fn parseField(self: *Parser, line: []const u8, doc: ?[]u8) ParserError!Field {
        var cursor = Cursor{ .text = line };
        const name = try cursor.parseIdentifier();
        try cursor.expectByte(':', ParseError.ExpectedColon);
        const type_expr = try self.parseTypeExpr(&cursor);
        errdefer type_expr.deinit(self.allocator);
        cursor.skipSpaces();
        _ = cursor.consumeOptionalByte(',');
        try cursor.expectEnd();

        return .{
            .doc = doc,
            .name = name,
            .type_expr = type_expr,
        };
    }

    fn parseOpaqueMethod(self: *Parser, line: []const u8, doc: ?[]u8) ParserError!FunctionDecl {
        var cursor = Cursor{ .text = line };
        const name = try cursor.parseIdentifier();
        const signature = blk: {
            if (cursor.consumeOptionalByte(':')) {
                const maybe_signature = try self.maybeParseFunctionType(&cursor);
                if (maybe_signature == null) {
                    return ParseError.ExpectedFunctionKeyword;
                }
                break :blk maybe_signature.?;
            }

            break :blk try self.parseFunctionSignature(&cursor, .asynchronous);
        };
        errdefer {
            var cleanup = signature;
            cleanup.deinit(self.allocator);
        }
        cursor.skipSpaces();
        _ = cursor.consumeOptionalByte(',');
        try cursor.expectEnd();

        return .{
            .doc = doc,
            .name = name,
            .mode = signature.mode,
            .params = signature.params,
            .return_type = signature.return_type,
        };
    }

    fn maybeParseFunctionDecl(self: *Parser, name: []const u8, doc: ?[]u8, cursor: *Cursor) ParserError!?FunctionDecl {
        const signature = try self.maybeParseFunctionType(cursor);
        if (signature == null) {
            return null;
        }
        errdefer {
            var cleanup = signature.?;
            cleanup.deinit(self.allocator);
        }
        try cursor.expectEnd();

        return .{
            .doc = doc,
            .name = name,
            .mode = signature.?.mode,
            .params = signature.?.params,
            .return_type = signature.?.return_type,
        };
    }

    fn maybeParseFunctionType(self: *Parser, cursor: *Cursor) ParserError!?FunctionSignature {
        if (cursor.consumeKeyword("sync")) {
            if (!cursor.consumeKeyword("func")) {
                return ParseError.ExpectedFunctionKeyword;
            }
            return try self.parseFunctionSignature(cursor, .sync);
        }

        if (cursor.consumeKeyword("func")) {
            return try self.parseFunctionSignature(cursor, .asynchronous);
        }

        return null;
    }

    fn parseFunctionSignature(self: *Parser, cursor: *Cursor, mode: ExecutionMode) ParserError!FunctionSignature {
        var params = try self.parseParameters(cursor);
        errdefer {
            for (params.items) |*parameter| {
                parameter.deinit(self.allocator);
            }
            params.deinit(self.allocator);
        }

        try cursor.expectByte(':', ParseError.ExpectedReturnType);
        const return_type = try self.parseTypeExpr(cursor);
        errdefer return_type.deinit(self.allocator);

        return .{
            .mode = mode,
            .params = params,
            .return_type = return_type,
        };
    }

    fn parseParameters(self: *Parser, cursor: *Cursor) ParserError!std.ArrayListUnmanaged(Parameter) {
        var params: std.ArrayListUnmanaged(Parameter) = .empty;
        errdefer {
            for (params.items) |*parameter| {
                parameter.deinit(self.allocator);
            }
            params.deinit(self.allocator);
        }

        try cursor.expectByte('(', ParseError.ExpectedOpenParen);
        cursor.skipSpaces();
        if (cursor.consumeOptionalByte(')')) {
            return params;
        }

        while (true) {
            const name = try cursor.parseIdentifier();
            try cursor.expectByte(':', ParseError.ExpectedColon);
            const type_expr = try self.parseTypeExpr(cursor);
            errdefer type_expr.deinit(self.allocator);
            try params.append(self.allocator, .{
                .name = name,
                .type_expr = type_expr,
            });

            cursor.skipSpaces();
            if (cursor.consumeOptionalByte(')')) {
                break;
            }
            try cursor.expectByte(',', ParseError.ExpectedComma);
        }

        return params;
    }

    fn parseTypeExpr(self: *Parser, cursor: *Cursor) ParserError!*TypeExpr {
        cursor.skipSpaces();
        if (cursor.consumeOptionalByte('?')) {
            const child = try self.parseTypeExpr(cursor);
            errdefer child.deinit(self.allocator);
            return self.allocType(.{ .optional = child });
        }

        if (cursor.consumeKeyword("ref")) {
            const child = try self.parseTypeExpr(cursor);
            errdefer child.deinit(self.allocator);
            return self.allocType(.{ .reference = child });
        }

        if (cursor.consumeKeyword("list")) {
            const child = try self.parseTypeExpr(cursor);
            errdefer child.deinit(self.allocator);
            return self.allocType(.{ .list = child });
        }

        if (cursor.consumeKeyword("sync")) {
            if (!cursor.consumeKeyword("func")) {
                return ParseError.ExpectedFunctionKeyword;
            }
            var signature = try self.parseFunctionSignature(cursor, .sync);
            errdefer signature.deinit(self.allocator);
            return self.allocType(.{ .function = signature });
        }

        if (cursor.consumeKeyword("func")) {
            var signature = try self.parseFunctionSignature(cursor, .asynchronous);
            errdefer signature.deinit(self.allocator);
            return self.allocType(.{ .function = signature });
        }

        const name = try cursor.parseIdentifier();
        return self.allocType(.{ .named = name });
    }

    fn allocType(self: *Parser, type_expr: TypeExpr) ParserError!*TypeExpr {
        const ptr = try self.allocator.create(TypeExpr);
        ptr.* = type_expr;
        return ptr;
    }

    fn pushDocLine(self: *Parser, line: []const u8) ParserError!void {
        if (self.pending_doc.items.len != 0) {
            try self.pending_doc.append(self.allocator, '\n');
        }
        try self.pending_doc.appendSlice(self.allocator, line);
    }

    fn takePendingDoc(self: *Parser) ParserError!?[]u8 {
        if (self.pending_doc.items.len == 0) {
            return null;
        }

        const doc = try self.allocator.dupe(u8, self.pending_doc.items);
        self.pending_doc.clearRetainingCapacity();
        return doc;
    }

    fn clearPendingDoc(self: *Parser) void {
        self.pending_doc.clearRetainingCapacity();
    }
};

const DocCollector = struct {
    buffer: std.ArrayListUnmanaged(u8) = .empty,

    fn push(self: *DocCollector, allocator: std.mem.Allocator, line: []const u8) !void {
        if (self.buffer.items.len != 0) {
            try self.buffer.append(allocator, '\n');
        }
        try self.buffer.appendSlice(allocator, line);
    }

    fn take(self: *DocCollector, allocator: std.mem.Allocator) !?[]u8 {
        if (self.buffer.items.len == 0) {
            return null;
        }

        const doc = try allocator.dupe(u8, self.buffer.items);
        self.buffer.clearRetainingCapacity();
        return doc;
    }

    fn clear(self: *DocCollector) void {
        self.buffer.clearRetainingCapacity();
    }

    fn deinit(self: *DocCollector, allocator: std.mem.Allocator) void {
        self.buffer.deinit(allocator);
    }
};

const Cursor = struct {
    text: []const u8,
    index: usize = 0,

    fn skipSpaces(self: *Cursor) void {
        while (self.index < self.text.len and isSpace(self.text[self.index])) : (self.index += 1) {}
    }

    fn parseIdentifier(self: *Cursor) ![]const u8 {
        self.skipSpaces();
        const start = self.index;
        while (self.index < self.text.len and isIdentifierChar(self.text[self.index])) : (self.index += 1) {}
        if (start == self.index) {
            return ParseError.ExpectedIdentifier;
        }
        return self.text[start..self.index];
    }

    fn expectByte(self: *Cursor, byte: u8, err: ParseError) !void {
        self.skipSpaces();
        if (self.index >= self.text.len or self.text[self.index] != byte) {
            return err;
        }
        self.index += 1;
    }

    fn consumeOptionalByte(self: *Cursor, byte: u8) bool {
        self.skipSpaces();
        if (self.index >= self.text.len or self.text[self.index] != byte) {
            return false;
        }
        self.index += 1;
        return true;
    }

    fn consumeKeyword(self: *Cursor, keyword: []const u8) bool {
        self.skipSpaces();
        if (!std.mem.startsWith(u8, self.text[self.index..], keyword)) {
            return false;
        }

        const end = self.index + keyword.len;
        if (end < self.text.len and isIdentifierChar(self.text[end])) {
            return false;
        }

        self.index = end;
        return true;
    }

    fn expectEnd(self: *Cursor) !void {
        self.skipSpaces();
        if (self.index != self.text.len) {
            return ParseError.UnexpectedToken;
        }
    }
};

const LineIterator = struct {
    source: []const u8,
    index: usize = 0,

    fn next(self: *LineIterator) ?[]const u8 {
        if (self.index >= self.source.len) {
            return null;
        }

        const start = self.index;
        while (self.index < self.source.len and self.source[self.index] != '\n') : (self.index += 1) {}
        const end = self.index;
        if (self.index < self.source.len) {
            self.index += 1;
        }

        var line = self.source[start..end];
        if (line.len != 0 and line[line.len - 1] == '\r') {
            line = line[0 .. line.len - 1];
        }
        return line;
    }
};

fn isIdentifierChar(byte: u8) bool {
    return std.ascii.isAlphanumeric(byte) or byte == '_' or byte == '.';
}

fn isSpace(byte: u8) bool {
    return byte == ' ' or byte == '\t' or byte == '\r';
}

fn trimLine(line: []const u8) []const u8 {
    return std.mem.trim(u8, line, " \t\r");
}

fn stripInlineComment(line: []const u8) []const u8 {
    if (std.mem.indexOf(u8, line, "//")) |index| {
        return line[0..index];
    }
    return line;
}

fn commentText(line: []const u8) []const u8 {
    return std.mem.trimStart(u8, line[2..], " \t");
}

fn isClosingBrace(line: []const u8) bool {
    return std.mem.eql(u8, line, "}") or std.mem.eql(u8, line, "},");
}

fn freeDoc(allocator: std.mem.Allocator, doc: ?[]u8) void {
    if (doc) |value| {
        allocator.free(value);
    }
}

test "parse mzproto schema with docs and owned deinit" {
    const allocator = std.testing.allocator;

    var schema = try Schema.parse(allocator,
        \\// test schema.
        \\
        \\
        \\// The storage backend to use for storing data.
        \\StorageBackend: enum {
        \\    // Saves the authentication keys on a binary file, while everything else is saved in memory
        \\    //
        \\    // Warning: asdasdadsadasdsadasdas
        \\    MemoryDcBinStorage = 0,
        \\}
        \\
        \\// The configuration for mzproto
        \\Config: struct {
        \\    // Application identifier for Telegram API access, which can be obtained at https://my.telegram.org
        \\    api_id: u32,
        \\    // Application identifier hash for Telegram API access, which can be obtained at https://my.telegram.org
        \\    api_hash: string,
        \\    
        \\    // Application version
        \\    app_version: string,
        \\    // Model of the device the application is being run on;
        \\    device_model: string,
        \\    // Version of the operating system the application is being run on
        \\    system_version: string,
        \\    // Language code of the system language
        \\    system_language: string,
        \\    
        \\    // Whether the client should use test servers
        \\    testmode: ?bool,
        \\    // Whether the client should use IPv6
        \\    enable_ipv6: ?bool,
        \\    // Whether the client should use IPv4
        \\    enable_ipv4: ?bool,
        \\
        \\    // Whether the client should add branding to the user agent
        \\    add_branding: ?bool,
        \\
        \\    // Storage backend to use for storing data
        \\    storage_backend: StorageBackend,
        \\    // Path to the storage backend
        \\    storage_path: string,
        \\}
        \\
        \\TestSub1: struct {
        \\    a: i32,
        \\    b: i32,
        \\
        \\    // we could also define more "built-in" types, like...
        \\    some: bytes,
        \\    some1: time,
        \\
        \\    // if we want, we can make "referenced objects"
        \\    ref_obj: ref Config
        \\
        \\    // a list
        \\    obj_list: list bytes
        \\
        \\    obj_list_ref: list ref Config
        \\
        \\    //random comment, this MUST not be part of the function `sum` below
        \\
        \\    sum: sync func(): i32
        \\    sum2: func(c: i32): i32
        \\}
        \\
        \\TestSub2: struct {
        \\    a: i64,
        \\    b: i64,
        \\
        \\    sum: func(): i64
        \\}
        \\
        \\Message: struct {
        \\    id: u64,
        \\}
        \\
        \\TestUnion: union {
        \\    sub1: TestSub1,
        \\    sub2: TestSub2,
        \\}
        \\    
        \\// Sends a message using the language-native client instance.
        \\sendMessage: func(text: string): Message
        \\
        \\// Terminates the language-native client instance.
        \\terminate: sync func(): void
        \\
    );
    defer schema.deinit();

    try std.testing.expectEqual(@as(usize, 8), schema.declarations.items.len);

    const storage = schema.declarations.items[0].enum_decl;
    try std.testing.expectEqualStrings("StorageBackend", storage.name);
    try std.testing.expectEqualStrings("The storage backend to use for storing data.", storage.doc.?);
    try std.testing.expectEqual(@as(usize, 1), storage.items.items.len);
    try std.testing.expectEqualStrings(
        "Saves the authentication keys on a binary file, while everything else is saved in memory\n\nWarning: asdasdadsadasdsadasdas",
        storage.items.items[0].doc.?,
    );
    try std.testing.expectEqualStrings("MemoryDcBinStorage", storage.items.items[0].name);
    try std.testing.expectEqual(@as(i64, 0), storage.items.items[0].value);

    const config = schema.declarations.items[1].struct_decl;
    try std.testing.expectEqualStrings("Config", config.name);
    try std.testing.expectEqualStrings("The configuration for mzproto", config.doc.?);
    try std.testing.expectEqual(@as(usize, 12), config.fields.items.len);
    try std.testing.expectEqualStrings("Application identifier for Telegram API access, which can be obtained at https://my.telegram.org", config.fields.items[0].doc.?);
    try std.testing.expect(config.fields.items[6].type_expr.* == .optional);
    try std.testing.expectEqualStrings("bool", config.fields.items[6].type_expr.optional.named);

    const test_sub_1 = schema.declarations.items[2].struct_decl;
    try std.testing.expectEqual(@as(usize, 9), test_sub_1.fields.items.len);
    try std.testing.expectEqualStrings("ref_obj", test_sub_1.fields.items[4].name);
    try std.testing.expect(test_sub_1.fields.items[4].type_expr.* == .reference);
    try std.testing.expectEqualStrings("Config", test_sub_1.fields.items[4].type_expr.reference.named);
    try std.testing.expectEqualStrings("a list", test_sub_1.fields.items[5].doc.?);
    try std.testing.expect(test_sub_1.fields.items[6].doc == null);
    try std.testing.expect(test_sub_1.fields.items[6].type_expr.* == .list);
    try std.testing.expect(test_sub_1.fields.items[6].type_expr.list.* == .reference);
    try std.testing.expectEqualStrings("Config", test_sub_1.fields.items[6].type_expr.list.reference.named);
    try std.testing.expect(test_sub_1.fields.items[7].doc == null);
    try std.testing.expect(test_sub_1.fields.items[7].type_expr.* == .function);
    try std.testing.expectEqual(.sync, test_sub_1.fields.items[7].type_expr.function.mode);
    try std.testing.expectEqual(@as(usize, 0), test_sub_1.fields.items[7].type_expr.function.params.items.len);
    try std.testing.expectEqualStrings("i32", test_sub_1.fields.items[7].type_expr.function.return_type.named);
    try std.testing.expect(test_sub_1.fields.items[8].type_expr.* == .function);
    try std.testing.expectEqual(.asynchronous, test_sub_1.fields.items[8].type_expr.function.mode);
    try std.testing.expectEqual(@as(usize, 1), test_sub_1.fields.items[8].type_expr.function.params.items.len);
    try std.testing.expectEqualStrings("c", test_sub_1.fields.items[8].type_expr.function.params.items[0].name);
    try std.testing.expectEqualStrings("i32", test_sub_1.fields.items[8].type_expr.function.params.items[0].type_expr.named);

    const message = schema.declarations.items[4].struct_decl;
    try std.testing.expectEqualStrings("Message", message.name);
    try std.testing.expectEqual(@as(usize, 1), message.fields.items.len);
    try std.testing.expectEqualStrings("id", message.fields.items[0].name);
    try std.testing.expectEqualStrings("u64", message.fields.items[0].type_expr.named);

    const test_union = schema.declarations.items[5].union_decl;
    try std.testing.expectEqual(@as(usize, 2), test_union.fields.items.len);
    try std.testing.expectEqualStrings("TestSub1", test_union.fields.items[0].type_expr.named);

    const send_message = schema.declarations.items[6].function_decl;
    try std.testing.expectEqualStrings("Sends a message using the language-native client instance.", send_message.doc.?);
    try std.testing.expectEqualStrings("sendMessage", send_message.name);
    try std.testing.expectEqual(.asynchronous, send_message.mode);
    try std.testing.expectEqual(@as(usize, 1), send_message.params.items.len);
    try std.testing.expectEqualStrings("text", send_message.params.items[0].name);
    try std.testing.expectEqualStrings("string", send_message.params.items[0].type_expr.named);
    try std.testing.expectEqualStrings("Message", send_message.return_type.named);

    const terminate = schema.declarations.items[7].function_decl;
    try std.testing.expectEqualStrings("Terminates the language-native client instance.", terminate.doc.?);
    try std.testing.expectEqualStrings("terminate", terminate.name);
    try std.testing.expectEqual(.sync, terminate.mode);
    try std.testing.expectEqual(@as(usize, 0), terminate.params.items.len);
    try std.testing.expectEqualStrings("void", terminate.return_type.named);
}
