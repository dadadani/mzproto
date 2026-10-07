const std = @import("std");
pub const mtproto = @import("tlbase/mtproto.zig");
pub const cursor = @import("tlbase/cursor.zig");
const Error = cursor.Error;
const Dialect = cursor.Dialect;
const Encoding = cursor.Encoding;
const Mode = cursor.Mode;
const Result = cursor.Result;
const Reader = cursor.Deserializer;
const Writer = cursor.Serializer;
const Buffer = cursor.ObjectBuffer;

pub const ResultOps = struct {
    out_alignment: usize,
    measure: *const fn ([]const u8) Error!cursor.Layout,
    decodeInto: *const fn (noalias input: []const u8, noalias workspace: []u8) Error!DecodedResult,
    decodeExact: *const fn (noalias input: []const u8, noalias workspace: []u8) Error!DecodedResult,

    pub fn forType(comptime Function: type) ResultOps {
        const Adapter = ResultAdapter(Function.Result);
        return .{
            .out_alignment = Adapter.alignment,
            .measure = Adapter.measure,
            .decodeInto = Adapter.decodeInto,
            .decodeExact = Adapter.decodeExact,
        };
    }
};

pub const DecodedResult = struct {
    value: *const anyopaque,
    type_token: *const u8,
    tl_bytes: usize,
    object_bytes: usize,

    pub fn from(self: @This(), comptime Function: type) error{UnexpectedResultType}!Function.Result.Read {
        const T = Function.Result.Read;
        if (self.type_token != &ResultIdentity(T).token) return error.UnexpectedResultType;

        return @as(*const T, @ptrCast(@alignCast(self.value))).*;
    }
};

fn ResultIdentity(comptime T: type) type {
    return struct {
        const Type = T;
        var token: u8 = 0;
    };
}

fn ResultAdapter(comptime S: type) type {
    return struct {
        const alignment = @max(@alignOf(S.Read), objectAlignment(S));

        fn measure(input: []const u8) Error!cursor.Layout {
            var r = Reader.init(input);
            var memory = try Buffer(.measure).init(&.{});
            try memory.alloc(S.Read, 1);
            try read(S, .measure, &r, &memory, .telegram);
            return .{ .tl_bytes = r.position, .object_bytes = memory.position };
        }

        fn decodeInto(noalias input: []const u8, noalias workspace: []u8) Error!DecodedResult {
            if (@intFromPtr(workspace.ptr) % alignment != 0) return error.MisalignedOutputBuffer;
            var r = Reader.init(input);
            var memory = try Buffer(.serialize).init(workspace);
            const root = try memory.alloc(S.Read, 1);
            root[0] = try read(S, .serialize, &r, &memory, .telegram);

            return .{
                .value = @ptrCast(&root[0]),
                .type_token = &ResultIdentity(S.Read).token,
                .tl_bytes = r.position,
                .object_bytes = memory.position,
            };
        }

        fn decodeExact(noalias input: []const u8, noalias workspace: []u8) Error!DecodedResult {
            const decoded = try decodeInto(input, workspace);
            if (decoded.tl_bytes != input.len) return error.InvalidData;
            return decoded;
        }
    };
}

pub const FieldOptions = struct {
    since: u32 = 1,
    flag_word: bool = false,
    flag_index: ?usize = null,
    bit: u5 = 0,
    flag_only: bool = false,
};

pub fn Field(comptime name: []const u8, comptime S: type, comptime options: FieldOptions) type {
    return struct {
        pub const field_name = name;
        pub const Spec = S;
        pub const opts = options;
    };
}
pub fn Primitive(comptime T: type, comptime id: ?u32) type {
    return struct {
        pub const kind = .primitive;
        pub const Write = T;
        pub const Read = T;
        pub const Borrow = T;
        pub const constructor_id = id;
    };
}
pub const Bytes = struct {
    pub const kind = .bytes;
    pub const Write = []const u8;
    pub const Read = []const u8;
    pub const Borrow = []const u8;
};
pub const Boolean = struct {
    pub const kind = .boolean;
    pub const Write = bool;
    pub const Read = bool;
    pub const Borrow = bool;
};
pub fn BoxedBytes(comptime id: u32) type {
    return struct {
        pub const kind = .bytes;
        pub const Write = []const u8;
        pub const Read = []const u8;
        pub const Borrow = []const u8;
        pub const constructor_id = id;
    };
}
pub fn Ref(comptime T: type, comptime encoding: Encoding) type {
    return struct {
        pub const kind = .object;
        pub const Object = T;
        pub const wire_encoding = encoding;
        pub const Write = if (@hasDecl(T, "tl_constructors")) T else *const T;
        pub const Read = if (@hasDecl(T, "tl_constructors")) T.Decoded else *const T.Decoded;
        pub const Borrow = T.View;
    };
}
pub fn Vector(comptime E: type, comptime encoding: Encoding) type {
    return struct {
        pub const kind = .vector;
        pub const Element = E;
        pub const wire_encoding = encoding;
        pub const Write = []const E.Write;
        pub const Read = []const E.Read;
        pub const Borrow = VectorView(E);
    };
}

pub fn objectAlignment(comptime S: type) usize {
    return objectAlignmentMany(.{S});
}

/// Compute one bound for multiple descriptors without revisiting shared graphs.
pub fn objectAlignmentMany(comptime specs: anytype) usize {
    @setEvalBranchQuota(20_000_000);
    comptime var visited: []const type = &.{};
    var alignment: usize = 1;
    for (specs) |S| alignment = @max(alignment, allocationAlignment(S, &visited));
    return alignment;
}

fn allocationAlignment(comptime S: type, comptime visited: *[]const type) usize {
    switch (S.kind) {
        .vector => return @max(@alignOf(S.Element.Read), allocationAlignment(S.Element, visited)),
        .object => {
            const T = S.Object;
            for (visited.*) |Seen| if (Seen == T) return 1;
            visited.* = visited.* ++ .{T};
            var alignment: usize = 1;
            if (@hasDecl(T, "tl_constructors")) {
                for (T.tl_constructors) |C| {
                    alignment = @max(alignment, allocationAlignment(Ref(C, .boxed), visited));
                }
            } else {
                alignment = @alignOf(T.Decoded);
                for (T.tl_fields) |F| {
                    alignment = @max(alignment, allocationAlignment(F.Spec, visited));
                }
            }
            return alignment;
        },
        else => return 1,
    }
}

pub const Frame = struct { dialect: Dialect = .storage, version: u32, payload: []const u8, id: u32, depth: usize = 0 };

pub fn readFrame(comptime T: type, r: *Reader, comptime encoding: Encoding) Error!Frame {
    const id = if (encoding == .boxed) try r.int() else T.tl_id;
    const version = r.version;
    if (version == 0) return error.UnsupportedVersion;
    const payload = try r.frame();
    if (@hasDecl(T, "tl_constructors")) {
        inline for (T.tl_constructors) |C| {
            if (id == C.tl_id) {
                return .{ .version = version, .payload = payload.input, .id = id, .depth = r.depth };
            }
        }
        return error.InvalidConstructor;
    } else {
        if (id != T.tl_id) return error.InvalidConstructor;
        return .{ .version = version, .payload = payload.input, .id = id, .depth = r.depth };
    }
}

pub fn write(comptime S: type, w: *Writer, value: S.Write, dialect: Dialect) Error!void {
    switch (S.kind) {
        .primitive => {
            if (S.constructor_id) |id| try w.int(id);
            if (S.Write == f64) try w.double(value) else try w.integer(S.Write, value);
        },
        .bytes => {
            if (@hasDecl(S, "constructor_id")) try w.int(S.constructor_id);
            try w.bytes(value, dialect);
        },
        .boolean => try w.boolean(value),
        .true_value => {
            if (!value) return error.InvalidData;
            try w.int(0x3fedd339);
        },
        .object => try encodeObject(S.Object, w, value, dialect, S.wire_encoding),
        .vector => {
            try w.enter();
            defer w.leave();
            if (dialect == .telegram) try w.vectorHeader(value.len, S.wire_encoding) else try w.int(try cursor.count(value.len));
            const mark = if (dialect == .storage) try w.beginFrame() else 0;
            for (value) |item| try write(S.Element, w, item, dialect);
            if (dialect == .storage) try w.finishFrame(mark);
        },
        else => unreachable,
    }
}

pub fn read(comptime S: type, comptime mode: Mode, r: *Reader, memory: *Buffer(mode), dialect: Dialect) Error!Result(mode, S.Read) {
    switch (S.kind) {
        .primitive => {
            if (S.constructor_id) |id| try r.expectId(id);
            const v = if (S.Read == f64) try r.double() else try r.integer(S.Read);
            if (mode == .serialize) return v;
        },
        .boolean => {
            const v = try r.boolean();
            if (mode == .serialize) return v;
        },
        .true_value => {
            try r.expectId(0x3fedd339);
            if (mode == .serialize) return true;
        },
        .bytes => {
            if (@hasDecl(S, "constructor_id")) try r.expectId(S.constructor_id);
            return memory.copy(try r.bytes(dialect));
        },
        .object => return decodeObject(S.Object, mode, r, memory, dialect, S.wire_encoding),
        .vector => {
            try r.enter();
            defer r.leave();
            const n = if (dialect == .telegram) try r.vectorHeader(S.wire_encoding) else try r.int();
            var framed = if (dialect == .storage) try r.frame() else undefined;
            const input = if (dialect == .storage) &framed else r;
            const minimum = minimumWireSize(S.Element, dialect);
            if (minimum != 0 and n > input.remaining() / minimum) return error.InvalidData;
            const items = try memory.alloc(S.Element.Read, n);
            for (0..n) |i| {
                const item = try read(S.Element, mode, input, memory, dialect);
                if (mode == .serialize) items[i] = item;
            }
            if (dialect == .storage) try input.finish();
            if (mode == .serialize) return items;
        },
        else => unreachable,
    }
}

fn minimumWireSize(comptime S: type, dialect: Dialect) usize {
    return switch (S.kind) {
        .primitive => @divExact(@bitSizeOf(S.Read), 8) + @as(usize, if (S.constructor_id != null) 4 else 0),
        .boolean, .true_value => 4,
        .bytes => if (@hasDecl(S, "constructor_id")) 8 else 4,
        .vector => if (dialect == .storage or S.wire_encoding == .boxed) 8 else 4,
        // Bare Telegram constructors can have an empty payload.
        .object => @as(usize, if (dialect == .storage) 4 else 0) + @as(usize, if (S.wire_encoding == .boxed) 4 else 0),
        else => unreachable,
    };
}

pub fn borrow(comptime S: type, r: *Reader) Error!S.Borrow {
    switch (S.kind) {
        .primitive => {
            if (S.constructor_id) |id| try r.expectId(id);
            return if (S.Read == f64) r.double() else r.integer(S.Read);
        },
        .boolean => return r.boolean(),
        .true_value => {
            try r.expectId(0x3fedd339);
            return true;
        },
        .bytes => {
            if (@hasDecl(S, "constructor_id")) try r.expectId(S.constructor_id);
            return r.bytes(.storage);
        },
        .object => {
            try r.enter();
            defer r.leave();
            return .{ ._mztl_frame = try readFrame(S.Object, r, S.wire_encoding) };
        },
        .vector => {
            try r.enter();
            defer r.leave();
            const n = try r.int();
            const payload = try r.frame();
            if (n > payload.remaining()) return error.InvalidData;
            return .{ .payload = payload.input, .count = n, .depth = r.depth, .version = r.version };
        },
        else => unreachable,
    }
}

pub fn VectorView(comptime E: type) type {
    return struct {
        payload: []const u8,
        count: u32,
        depth: usize,
        version: u32 = 1,
        pub fn len(self: @This()) usize {
            return self.count;
        }
        pub fn iterator(self: @This()) Iterator {
            return .{ .reader = .{ .input = self.payload, .depth = self.depth, .version = self.version }, .remaining = self.count };
        }
        pub fn validateAll(self: @This()) Error!void {
            var r: Reader = .{ .input = self.payload, .depth = self.depth, .version = self.version };
            var memory = try Buffer(.measure).init(&.{});
            for (0..self.count) |_| try read(E, .measure, &r, &memory, .storage);
            try r.finish();
        }
        pub const Iterator = struct {
            reader: Reader,
            remaining: u32,
            pub fn next(self: *Iterator) Error!?E.Borrow {
                if (self.remaining == 0) {
                    try self.reader.finish();
                    return null;
                }
                const result = try borrow(E, &self.reader);
                self.remaining -= 1;
                if (self.remaining == 0) try self.reader.finish();
                return result;
            }
        };
    };
}

fn flagWords(comptime T: type, value: *const T, version: u32) Error![T.tl_fields.len]u32 {
    var flags: [T.tl_fields.len]u32 = @splat(0);
    var assigned: [T.tl_fields.len]u32 = @splat(0);
    inline for (T.tl_fields) |F| {
        if (version >= F.opts.since) {
            if (F.opts.flag_index) |index| {
                const present = if (F.opts.flag_only)
                    (if (F.opts.since > 1) @field(value, F.field_name) orelse false else @field(value, F.field_name))
                else
                    @field(value, F.field_name) != null;
                const mask = @as(u32, 1) << F.opts.bit;
                if (assigned[index] & mask != 0 and ((flags[index] & mask != 0) != present)) return error.InconsistentFlags;
                assigned[index] |= mask;
                if (present) flags[index] |= mask;
            }
        }
    }
    return flags;
}

pub fn encodeObject(comptime T: type, w: *Writer, value: Ref(T, .boxed).Write, dialect: Dialect, comptime encoding: Encoding) Error!void {
    @setEvalBranchQuota(20_000_000);
    if (@hasDecl(T, "tl_constructors")) {
        switch (value) {
            inline else => |v| try encodeObject(@typeInfo(@TypeOf(v)).pointer.child, w, v, dialect, .boxed),
        }
    } else {
        try w.enter();
        defer w.leave();
        const flags = try flagWords(T, value, w.version);
        if (encoding == .boxed) try w.int(T.tl_id);
        const mark = if (dialect == .storage) try w.beginFrame() else 0;
        inline for (T.tl_fields, 0..) |F, i| {
            if (w.version >= F.opts.since) {
                if (F.opts.flag_word) {
                    try w.int(flags[i]);
                } else if (!F.opts.flag_only) {
                    if (F.opts.flag_index != null) {
                        if (@field(value, F.field_name)) |v| try write(F.Spec, w, v, dialect);
                    } else if (F.opts.since > 1) {
                        try write(F.Spec, w, @field(value, F.field_name) orelse return error.MissingRequiredField, dialect);
                    } else try write(F.Spec, w, @field(value, F.field_name), dialect);
                }
            }
        }
        if (dialect == .storage) try w.finishFrame(mark);
    }
}

pub fn FieldBorrow(comptime T: type, comptime name: []const u8) type {
    inline for (T.tl_fields) |F| if (std.mem.eql(u8, F.field_name, name)) {
        return if (F.opts.flag_index != null and !F.opts.flag_only or F.opts.since > 1) ?F.Spec.Borrow else F.Spec.Borrow;
    };
    @compileError("unknown field");
}

fn decodeFields(comptime T: type, comptime mode: Mode, r: *Reader, memory: *Buffer(mode), dialect: Dialect, version: u32) Error!Result(mode, *const T.Decoded) {
    const object = try memory.alloc(T.Decoded, 1);
    var flags: [T.tl_fields.len]u32 = @splat(0);

    inline for (T.tl_fields, 0..) |F, i| {
        if (version < F.opts.since) {
            if (mode == .serialize and !F.opts.flag_word and F.opts.since > 1) {
                @field(object[0], F.field_name) = null;
            }
        } else if (F.opts.flag_word) {
            flags[i] = try r.int();
            if (dialect == .storage) try validateFlags(T, i, flags[i], version);
        } else {
            const present = if (F.opts.flag_index) |index| flags[index] & (@as(u32, 1) << F.opts.bit) != 0 else true;
            if (F.opts.flag_only) {
                if (mode == .serialize) @field(object[0], F.field_name) = present;
            } else if (present) {
                const v = try read(F.Spec, mode, r, memory, dialect);
                if (mode == .serialize) @field(object[0], F.field_name) = v;
            } else if (mode == .serialize) {
                @field(object[0], F.field_name) = null;
            }
        }
    }

    if (mode == .serialize) {
        return &object[0];
    }
}

fn validateFlags(comptime T: type, comptime index: usize, flags: u32, version: u32) Error!void {
    var allowed: u32 = 0;
    inline for (T.tl_fields) |F| {
        if (F.opts.flag_index == index) {
            if (version >= F.opts.since) allowed |= @as(u32, 1) << F.opts.bit;
        }
    }
    if (flags & ~allowed != 0) return error.InvalidData;
}

pub fn decodeObject(comptime T: type, comptime mode: Mode, r: *Reader, memory: *Buffer(mode), dialect: Dialect, comptime encoding: Encoding) Error!Result(mode, Ref(T, .boxed).Read) {
    @setEvalBranchQuota(20_000_000);

    try r.enter();
    defer r.leave();

    if (@hasDecl(T, "tl_constructors")) {
        if (dialect == .storage) {
            const frame = try readFrame(T, r, .boxed);
            inline for (T.tl_constructors, comptime std.meta.fieldNames(T.Decoded)) |C, field| {
                if (frame.id == C.tl_id) {
                    var payload: Reader = .{ .input = frame.payload, .depth = r.depth, .version = r.version };
                    const obj = try decodeFields(C, mode, &payload, memory, dialect, frame.version);
                    try payload.finish();
                    if (mode == .serialize) return @unionInit(T.Decoded, field, obj) else return;
                }
            }
        } else {
            const id = try r.int();
            inline for (T.tl_constructors, comptime std.meta.fieldNames(T.Decoded)) |C, field| {
                if (id == C.tl_id) {
                    const obj = try decodeFields(C, mode, r, memory, dialect, 1);
                    if (mode == .serialize) return @unionInit(T.Decoded, field, obj) else return;
                }
            }
        }
        return error.InvalidConstructor;
    } else {
        if (dialect == .storage) {
            const frame = try readFrame(T, r, encoding);
            var payload: Reader = .{ .input = frame.payload, .depth = r.depth, .version = r.version };
            const obj = try decodeFields(T, mode, &payload, memory, dialect, frame.version);
            try payload.finish();
            return obj;
        }
        if (encoding == .boxed) try r.expectId(T.tl_id);
        return decodeFields(T, mode, r, memory, dialect, 1);
    }
}

pub fn getField(comptime T: type, comptime name: []const u8, frame: Frame) Error!FieldBorrow(T, name) {
    var r: Reader = .{ .input = frame.payload, .depth = frame.depth, .version = frame.version };
    var flags: [T.tl_fields.len]u32 = @splat(0);

    inline for (T.tl_fields, 0..) |F, i| {
        const selected = comptime std.mem.eql(u8, F.field_name, name);
        if (frame.version < F.opts.since) {
            if (selected and F.opts.since > 1) return null;
        } else if (F.opts.flag_word) {
            flags[i] = try r.int();
            try validateFlags(T, i, flags[i], frame.version);
        } else {
            const present = if (F.opts.flag_index) |index| flags[index] & (@as(u32, 1) << F.opts.bit) != 0 else true;
            if (F.opts.flag_only) {
                if (selected) return present;
            } else if (present) {
                const v = if (F.Spec.kind == .bytes and frame.dialect == .telegram) blk: {
                    if (@hasDecl(F.Spec, "constructor_id")) try r.expectId(F.Spec.constructor_id);
                    break :blk try r.bytes(.telegram);
                } else try borrow(F.Spec, &r);
                if (selected) return v;
            } else if (selected) return null;
        }
    }

    unreachable;
}

pub fn validateView(comptime T: type, frame: Frame) Error!void {
    var r: Reader = .{ .input = frame.payload, .depth = frame.depth, .version = frame.version };
    var memory = try Buffer(.measure).init(&.{});

    if (@hasDecl(T, "tl_constructors")) {
        inline for (T.tl_constructors) |C| if (frame.id == C.tl_id) {
            try decodeFields(C, .measure, &r, &memory, frame.dialect, frame.version);
            return r.finish();
        };
        return error.InvalidConstructor;
    } else {
        try decodeFields(T, .measure, &r, &memory, frame.dialect, frame.version);
        try r.finish();
    }
}

pub fn TLValue(comptime S: type, comptime dialect: Dialect) type {
    return struct {
        pub const out_alignment = objectAlignment(S);
        pub fn serializedSize(value: S.Write) Error!usize {
            var w = Writer.measuring();
            try write(S, &w, value, dialect);
            return w.position;
        }
        pub fn serialize(value: S.Write, out: []u8) Error![]const u8 {
            var w = Writer.init(out);
            try write(S, &w, value, dialect);
            return w.out();
        }
        pub fn measure(input: []const u8) Error!cursor.Layout {
            var r = Reader.init(input);
            var memory = try Buffer(.measure).init(&.{});
            try read(S, .measure, &r, &memory, dialect);
            return .{ .tl_bytes = r.position, .object_bytes = memory.position };
        }
        pub fn decodeInto(noalias input: []const u8, noalias workspace: []align(out_alignment) u8) Error!struct { value: S.Read, tl_bytes: usize, object_bytes: usize } {
            var r = Reader.init(input);
            var memory = try Buffer(.serialize).init(workspace);
            const v = try read(S, .serialize, &r, &memory, dialect);
            return .{ .value = v, .tl_bytes = r.position, .object_bytes = memory.position };
        }
        pub fn decodeExact(noalias input: []const u8, noalias workspace: []align(out_alignment) u8) Error!S.Read {
            const result = try decodeInto(input, workspace);
            if (result.tl_bytes != input.len) return error.InvalidData;
            return result.value;
        }
    };
}

pub fn StorageTLValue(comptime S: type) type {
    const dialect: Dialect = .storage;
    return struct {
        pub const out_alignment = objectAlignment(S);

        pub fn serializedSize(version: u32, value: S.Write) Error!usize {
            if (version == 0) return error.UnsupportedVersion;
            var w = Writer.measuring();
            w.version = version;
            try write(S, &w, value, dialect);
            return w.position;
        }
        pub fn serialize(version: u32, value: S.Write, out: []u8) Error![]const u8 {
            if (version == 0) return error.UnsupportedVersion;
            var w = Writer.init(out);
            w.version = version;
            try write(S, &w, value, dialect);
            return w.out();
        }
        pub fn measure(version: u32, input: []const u8) Error!cursor.Layout {
            if (version == 0) return error.UnsupportedVersion;
            var r = Reader.init(input);
            r.version = version;
            var memory = try Buffer(.measure).init(&.{});
            try read(S, .measure, &r, &memory, dialect);
            return .{ .tl_bytes = r.position, .object_bytes = memory.position };
        }
        pub fn decodeInto(version: u32, noalias input: []const u8, noalias workspace: []align(out_alignment) u8) Error!struct { value: S.Read, tl_bytes: usize, object_bytes: usize } {
            if (version == 0) return error.UnsupportedVersion;
            var r = Reader.init(input);
            r.version = version;
            var memory = try Buffer(.serialize).init(workspace);
            const v = try read(S, .serialize, &r, &memory, dialect);
            return .{ .value = v, .tl_bytes = r.position, .object_bytes = memory.position };
        }
        pub fn decodeExact(version: u32, noalias input: []const u8, noalias workspace: []align(out_alignment) u8) Error!S.Read {
            const result = try decodeInto(version, input, workspace);
            if (result.tl_bytes != input.len) return error.InvalidData;
            return result.value;
        }
    };
}

fn basicViewSupported(comptime T: type) bool {
    for (T.tl_fields) |F| {
        switch (F.Spec.kind) {
            .object, .vector => return false,
            else => {},
        }
    }
    return true;
}

pub fn TLObject(comptime T: type, comptime dialect: Dialect) type {
    return struct {
        const C = if (dialect == .storage) StorageTLValue(Ref(T, .boxed)) else TLValue(Ref(T, .boxed), dialect);

        pub const out_alignment = C.out_alignment;
        pub const serialize = C.serialize;
        pub const serializedSize = C.serializedSize;
        pub const measure = C.measure;
        pub const decodeInto = C.decodeInto;
        pub const decodeExact = C.decodeExact;

        pub fn cloneSize(value: Ref(T, .boxed).Read) Error!usize {
            var memory = try Buffer(.measure).init(&.{});
            try cloneValue(Ref(T, .boxed), .measure, value, &memory, 0);
            return memory.position;
        }

        pub fn cloneInto(value: Ref(T, .boxed).Read, noalias workspace: []align(out_alignment) u8) Error!struct { value: Ref(T, .boxed).Read, object_bytes: usize } {
            var memory = try Buffer(.serialize).init(workspace);
            const v = try cloneValue(Ref(T, .boxed), .serialize, value, &memory, 0);
            return .{ .value = v, .object_bytes = memory.position };
        }

        pub const view = if (dialect == .storage) storageView else telegramView;
        fn telegramView(input: []const u8) Error!T.View {
            var r = Reader.init(input);
            const id = try r.int();
            if (@hasDecl(T, "tl_constructors")) {
                inline for (T.tl_constructors) |Constructor| {
                    if (id == Constructor.tl_id) {
                        if (!comptime basicViewSupported(Constructor)) return error.UnsupportedView;
                        return .{ ._mztl_frame = .{ .dialect = .telegram, .version = 1, .id = id, .payload = input[r.position..], .depth = 1 } };
                    }
                }
                return error.InvalidConstructor;
            } else {
                if (id != T.tl_id) return error.InvalidConstructor;
                if (!comptime basicViewSupported(T)) return error.UnsupportedView;
                return .{ ._mztl_frame = .{ .dialect = .telegram, .version = 1, .id = id, .payload = input[r.position..], .depth = 1 } };
            }
        }
        fn storageView(version: u32, input: []const u8) Error!T.View {
            if (version == 0) return error.UnsupportedVersion;
            var r = Reader.init(input);
            r.version = version;
            try r.enter();
            const frame = try readFrame(T, &r, .boxed);
            try r.finish();
            return .{ ._mztl_frame = frame };
        }
    };
}

pub const True = struct {
    pub const kind = .true_value;
    pub const Write = bool;
    pub const Read = bool;
    pub const Borrow = bool;
};

pub fn UnionView(comptime T: type) type {
    return struct {
        _mztl_frame: Frame,
        pub fn constructorId(self: @This()) u32 {
            return self._mztl_frame.id;
        }
        pub fn storedVersion(self: @This()) u32 {
            return self._mztl_frame.version;
        }
        pub fn as(self: @This(), comptime C: type) Error!C.View {
            comptime {
                var found = false;
                for (T.tl_constructors) |Candidate| {
                    if (Candidate == C) {
                        found = true;
                        break;
                    }
                }
                if (!found) @compileError("constructor does not belong to this boxed type");
            }
            if (self._mztl_frame.id != C.tl_id) return error.InvalidConstructor;
            return .{ ._mztl_frame = self._mztl_frame };
        }
        pub fn validateAll(self: @This()) Error!void {
            return validateView(T, self._mztl_frame);
        }
    };
}

fn cloneValue(comptime S: type, comptime mode: Mode, value: S.Read, memory: *Buffer(mode), depth: usize) Error!Result(mode, S.Read) {
    @setEvalBranchQuota(20_000_000);
    if (depth > 128) return error.DepthLimit;
    switch (S.kind) {
        .primitive, .boolean, .true_value => if (mode == .serialize) {
            return value;
        },
        .bytes => return memory.copy(value),
        .vector => {
            const dest = try memory.alloc(S.Element.Read, value.len);
            for (value, 0..) |item, i| {
                const v = try cloneValue(S.Element, mode, item, memory, depth + 1);
                if (mode == .serialize) dest[i] = v;
            }
            if (mode == .serialize) return dest;
        },
        .object => {
            const T = S.Object;
            if (@hasDecl(T, "tl_constructors")) {
                switch (value) {
                    inline else => |v, tag| {
                        inline for (T.tl_constructors, comptime std.meta.fieldNames(T.Decoded)) |C, field| {
                            if (comptime std.mem.eql(u8, @tagName(tag), field)) {
                                const cloned = try cloneValue(Ref(C, .bare), mode, v, memory, depth + 1);
                                if (mode == .serialize) return @unionInit(T.Decoded, field, cloned) else return;
                            }
                        }
                        unreachable;
                    },
                }
            } else {
                const dest = try memory.alloc(T.Decoded, 1);
                inline for (T.tl_fields) |F| {
                    if (!F.opts.flag_word) {
                        const optional = F.opts.since > 1 or (F.opts.flag_index != null and !F.opts.flag_only);
                        if (optional) {
                            if (@field(value, F.field_name)) |v| {
                                const cloned = try cloneValue(F.Spec, mode, v, memory, depth + 1);
                                if (mode == .serialize) @field(dest[0], F.field_name) = cloned;
                            } else if (mode == .serialize) {
                                @field(dest[0], F.field_name) = null;
                            }
                        } else {
                            const cloned = try cloneValue(F.Spec, mode, @field(value, F.field_name), memory, depth + 1);
                            if (mode == .serialize) @field(dest[0], F.field_name) = cloned;
                        }
                    }
                }
                if (mode == .serialize) return &dest[0];
            }
        },
        else => unreachable,
    }
}
