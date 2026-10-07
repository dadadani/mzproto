const std = @import("std");

pub const Dialect = enum { telegram, storage };
pub const Encoding = enum { bare, boxed };
pub const Error = error{
    EndOfInput,
    BufferTooSmall,
    Overflow,
    InvalidData,
    InvalidConstructor,
    UnsupportedVersion,
    UnsupportedView,
    MisalignedOutputBuffer,
    InconsistentFlags,
    DepthLimit,
    MissingRequiredField,
};
pub const vector_id: u32 = 0x1cb5c415;
pub const bool_true: u32 = 0x997275b5;
pub const bool_false: u32 = 0xbc799737;

pub fn add(a: usize, b: usize) Error!usize {
    return std.math.add(usize, a, b) catch error.Overflow;
}
pub fn multiply(a: usize, b: usize) Error!usize {
    return std.math.mul(usize, a, b) catch error.Overflow;
}
pub fn count(n: usize) Error!u32 {
    return std.math.cast(u32, n) orelse error.Overflow;
}

/// A null destination selects counting mode; writes use exactly the same path.
pub const Serializer = struct {
    destination: ?[]u8,
    position: usize = 0,
    depth: usize = 0,
    version: u32 = 1,

    pub fn init(output: []u8) Serializer {
        return .{ .destination = output };
    }

    pub fn measuring() Serializer {
        return .{ .destination = null };
    }

    pub fn out(self: Serializer) []const u8 {
        return if (self.destination) |b| b[0..self.position] else &.{};
    }

    pub fn reserve(self: *Serializer, n: usize) Error!?[]u8 {
        const end = try add(self.position, n);
        if (self.destination) |b| {
            if (end > b.len) return error.BufferTooSmall;
            const result = b[self.position..end];
            self.position = end;
            return result;
        }
        self.position = end;
        return null;
    }

    pub fn integer(self: *Serializer, comptime T: type, value: T) Error!void {
        if (try self.reserve(@divExact(@bitSizeOf(T), 8))) |b| std.mem.writeInt(T, @ptrCast(b.ptr), value, .little);
    }

    pub fn int(self: *Serializer, value: u32) Error!void {
        try self.integer(u32, value);
    }

    pub fn long(self: *Serializer, value: u64) Error!void {
        try self.integer(u64, value);
    }

    pub fn double(self: *Serializer, value: f64) Error!void {
        try self.long(@bitCast(value));
    }

    pub fn boolean(self: *Serializer, value: bool) Error!void {
        try self.int(if (value) bool_true else bool_false);
    }

    pub fn raw(self: *Serializer, value: []const u8) Error!void {
        if (try self.reserve(value.len)) |b| @memcpy(b, value);
    }

    pub fn bytes(self: *Serializer, value: []const u8, dialect: Dialect) Error!void {
        if (dialect == .storage) {
            try self.int(try count(value.len));
            return self.raw(value);
        }
        if (value.len > std.math.maxInt(u24)) return error.Overflow;
        const header: usize = if (value.len < 254) 1 else 4;
        if (header == 1) try self.integer(u8, @intCast(value.len)) else {
            try self.integer(u8, 254);
            try self.integer(u24, @intCast(value.len));
        }
        try self.raw(value);
        const padding = (4 - ((header + value.len) % 4)) % 4;
        if (try self.reserve(padding)) |b| @memset(b, 0);
    }

    pub fn vectorHeader(self: *Serializer, len: usize, encoding: Encoding) Error!void {
        if (len > std.math.maxInt(i32)) return error.Overflow;
        if (encoding == .boxed) try self.int(vector_id);
        try self.int(try count(len));
    }

    /// Reserve a storage payload length; finishFrame patches it without a second traversal.
    pub fn beginFrame(self: *Serializer) Error!usize {
        const mark = self.position;
        try self.int(0);
        return mark;
    }

    pub fn finishFrame(self: *Serializer, mark: usize) Error!void {
        if (mark > self.position or self.position - mark < 4) return error.InvalidData;
        const n = try count(self.position - mark - 4);
        if (self.destination) |b| std.mem.writeInt(u32, @ptrCast(b[mark..].ptr), n, .little);
    }

    pub fn enter(self: *Serializer) Error!void {
        if (self.depth == 128) return error.DepthLimit;
        self.depth += 1;
    }

    pub fn leave(self: *Serializer) void {
        self.depth -= 1;
    }
};

pub const Deserializer = struct {
    input: []const u8,
    position: usize = 0,
    depth: usize = 0,
    version: u32 = 1,

    pub fn init(input: []const u8) Deserializer {
        return .{ .input = input };
    }

    pub fn remaining(self: Deserializer) usize {
        return self.input.len - self.position;
    }

    pub fn take(self: *Deserializer, n: usize) Error![]const u8 {
        if (n > self.remaining()) return error.EndOfInput;
        const b = self.input[self.position..][0..n];
        self.position += n;
        return b;
    }

    pub fn integer(self: *Deserializer, comptime T: type) Error!T {
        const b = try self.take(@divExact(@bitSizeOf(T), 8));
        return std.mem.readInt(T, @ptrCast(b.ptr), .little);
    }

    pub fn int(self: *Deserializer) Error!u32 {
        return self.integer(u32);
    }

    pub fn long(self: *Deserializer) Error!u64 {
        return self.integer(u64);
    }

    pub fn double(self: *Deserializer) Error!f64 {
        return @bitCast(try self.long());
    }

    pub fn boolean(self: *Deserializer) Error!bool {
        return switch (try self.int()) {
            bool_true => true,
            bool_false => false,
            else => error.InvalidConstructor,
        };
    }

    pub fn expectId(self: *Deserializer, expected: u32) Error!void {
        if (try self.int() != expected) return error.InvalidConstructor;
    }

    pub fn bytes(self: *Deserializer, dialect: Dialect) Error![]const u8 {
        if (dialect == .storage) return self.take(try self.int());

        const first = try self.integer(u8);
        if (first == 255) return error.InvalidData;

        const len: usize = if (first == 254) try self.integer(u24) else first;
        if (first == 254 and len < 254) return error.InvalidData;

        const b = try self.take(len);
        const header: usize = if (first == 254) 4 else 1;

        const padding = try self.take((4 - ((len + header) % 4)) % 4);
        for (padding) |v| if (v != 0) return error.InvalidData;

        return b;
    }

    pub fn vectorHeader(self: *Deserializer, encoding: Encoding) Error!u32 {
        if (encoding == .boxed) try self.expectId(vector_id);
        const len = try self.int();
        if (len > std.math.maxInt(i32)) return error.InvalidData;
        return len;
    }

    pub fn frame(self: *Deserializer) Error!Deserializer {
        const payload = try self.take(try self.int());
        return .{ .input = payload, .depth = self.depth, .version = self.version };
    }

    pub fn finish(self: Deserializer) Error!void {
        if (self.remaining() != 0) return error.InvalidData;
    }

    pub fn enter(self: *Deserializer) Error!void {
        if (self.depth == 128) return error.DepthLimit;
        self.depth += 1;
    }

    pub fn leave(self: *Deserializer) void {
        self.depth -= 1;
    }
};

pub const Mode = enum { measure, serialize };
pub fn Result(comptime mode: Mode, comptime T: type) type {
    return if (mode == .measure) void else T;
}
pub const Layout = struct { tl_bytes: usize, object_bytes: usize };

pub fn ObjectBuffer(comptime mode: Mode) type {
    return struct {
        const Self = @This();
        output: []u8,
        position: usize = 0,

        pub fn init(output: []u8) Error!Self {
            return .{ .output = output };
        }

        pub fn alloc(self: *Self, comptime T: type, n: usize) Error!Result(mode, []T) {
            const padding = (@alignOf(T) - self.position % @alignOf(T)) % @alignOf(T);
            const start = try add(self.position, padding);
            const end = try add(start, try multiply(n, @sizeOf(T)));
            if (mode == .serialize) {
                if (@intFromPtr(self.output.ptr) % @alignOf(T) != 0) return error.MisalignedOutputBuffer;
                if (end > self.output.len) return error.BufferTooSmall;
                self.position = end;
                return @as([*]T, @ptrCast(@alignCast(self.output[start..].ptr)))[0..n];
            }
            self.position = end;
        }

        pub fn copy(self: *Self, bytes: []const u8) Error!Result(mode, []const u8) {
            const dest = try self.alloc(u8, bytes.len);
            if (mode == .serialize) {
                @memcpy(dest, bytes);
                return dest;
            }
        }
    };
}
