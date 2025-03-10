const std = @import("std");

pub fn ProtoMessage(comptime ty: type) type {
    return struct {
        msg_id: u64,
        seqno: i32,
        body: ty,
    };
}

pub fn MessageContainer(comptime ty: type) type {
    return struct {
        messages: []const ProtoMessage(ty),

        pub fn serializedSize(self: *const @This()) usize {
            var result: usize = 8;
            for (self.messages) |message| {
                result += 16 + message.body.serializedSize();
            }
            return result;
        }

        pub fn deserializedSize(src: []const u8, cursor: *usize, size: *usize) void {
            size.* += ensureAligned(size.*, @alignOf(*@This())) + @sizeOf(@This());

            const len = std.mem.readInt(u32, @ptrCast(src[cursor.* .. cursor.* + 4]), std.builtin.Endian.little);
            cursor.* += 4;

            size.* += ensureAligned(size.*, @alignOf([]const ProtoMessage(ty)));
            size.* += len * @sizeOf(ProtoMessage(ty));
            for (0..len) |_| {
                cursor.* += 16;
                ty.deserializedSize(src, cursor, size);
            }
        }

        pub fn cloneSize(self: *const @This(), size: *usize) void {
            size.* += ensureAligned(size.*, @alignOf(*@This())) + @sizeOf(@This());

            size.* += ensureAligned(size.*, @alignOf([]const ProtoMessage(ty)));
            size.* += self.messages.len * @sizeOf(ProtoMessage(ty));

            for (self.messages) |message| {
                message.body.cloneSize(size);
            }
        }

        pub fn clone(self: *const @This(), dest: []u8, size: *usize) *@This() {
            size.* += ensureAligned(size.*, @alignOf(*@This()));
            const result = @as(*@This(), @alignCast(@ptrCast(dest[size.*..].ptr)));
            size.* += @sizeOf(@This());

            size.* += ensureAligned(size.*, @alignOf([]const ty));
            //result.messages = @as([]const ProtoMessage(ty), @ptrCast(@alignCast(dest[size.* .. size.* + (@sizeOf(ProtoMessage(ty)) * self.messages.len)])));
            // @constCast(@as(@TypeOf(result.messages), @alignCast(std.mem.bytesAsSlice(unwrapType(@TypeOf(result.messages)), dest[written.* .. written.* + (len * @sizeOf(unwrapType(@TypeOf(result.messages))))]))));
            result.messages = @as([]const ProtoMessage(ty), @alignCast(std.mem.bytesAsSlice(ProtoMessage(ty), dest[size.* .. size.* + (@sizeOf(ProtoMessage(ty)) * self.messages.len)])));
            @memcpy(@constCast(result.messages), self.messages);
            size.* += @sizeOf(ProtoMessage(ty)) * self.messages.len;

            const messages = @constCast(result.messages);

            for (0..self.messages.len) |i| {
                messages[i].body = self.messages[i].body.clone(dest, size);
            }

            return result;
        }

        pub fn serialize(self: *const @This(), dest: []u8) usize {
            var written: usize = 0;

            written += serializeInt(@as(u32, 0x73f1f8dc), dest[written..]);

            written += serializeInt(@as(usize, self.messages.len), dest[written..]);

            for (self.messages) |message| {
                written += serializeInt(message.msg_id, dest[written..]);
                written += serializeInt(message.seqno, dest[written..]);

                const tlWritten = message.body.serialize(dest[written + 4 ..]);

                written += serializeInt(tlWritten, dest[written..]) + tlWritten;
            }

            return written;
        }
        pub fn deserialize(src: []const u8, dest: []u8, cursor: *usize, written: *usize) *@This() {
            const alignment = ensureAligned(written.*, @alignOf(*@This()));
            const result = @as(*@This(), @alignCast(@ptrCast(dest[written.* + alignment ..].ptr)));
            written.* += alignment + @sizeOf(@This());

            const len = std.mem.readInt(u32, @ptrCast(src[cursor.* .. cursor.* + 4]), std.builtin.Endian.little);
            cursor.* += 4;

            written.* += ensureAligned(written.*, @alignOf(@TypeOf(result.messages)));
            const vector = @constCast(@as(@TypeOf(result.messages), @alignCast(std.mem.bytesAsSlice(unwrapType(@TypeOf(result.messages)), dest[written.* .. written.* + (len * @sizeOf(unwrapType(@TypeOf(result.messages))))]))));
            written.* += @sizeOf(unwrapType(@TypeOf(result.messages))) * len;

            for (0..len) |i| {
                cursor.* += deserializeInt(unwrapType(@TypeOf(vector[i].msg_id)), src[cursor.*..], &vector[i].msg_id);
                cursor.* += deserializeInt(unwrapType(@TypeOf(vector[i].seqno)), src[cursor.*..], &vector[i].seqno);
                const bodylen = std.mem.readInt(u32, @ptrCast(src[cursor.* .. cursor.* + 4]), std.builtin.Endian.little);
                cursor.* += 4;
                vector[i].body = ty.deserialize(src[0 .. cursor.* + bodylen], dest, cursor, written);
            }

            result.messages = vector;

            return result;
        }
    };
}

pub const FutureSalt = struct {
    valid_since: u32,
    valid_until: u32,
    salt: u64,
};

pub const FutureSalts = struct {
    req_msg_id: u64,
    now: u32,
    salts: []const FutureSalt,

    pub fn serializedSize(self: *const @This()) usize {
        return 20 + (self.salts.len * 16);
    }

    pub fn serialize(self: *const @This(), dest: []u8) usize {
        var written: usize = 0;
        written += serializeInt(@as(u32, 0xae500895), dest[written..]);
        written += serializeInt(self.req_msg_id, dest[written..]);
        written += serializeInt(self.now, dest[written..]);
        written += serializeInt(self.salts.len, dest[written..]);
        for (self.salts) |salt| {
            written += serializeInt(salt.valid_since, dest[written..]);
            written += serializeInt(salt.valid_until, dest[written..]);
            written += serializeInt(salt.salt, dest[written..]);
        }
        return written;
    }

    pub fn deserializedSize(src: []const u8, cursor: *usize, size: *usize) void {
        size.* += ensureAligned(size.*, @alignOf(*@This())) + @sizeOf(@This());

        const len = std.mem.readInt(u32, @ptrCast(src[cursor.* .. cursor.* + 4]), std.builtin.Endian.little);
        cursor.* += 4;

        size.* += ensureAligned(size.*, @alignOf([]const FutureSalt));
        size.* += len * @sizeOf(FutureSalt);
        for (0..len) |_| {
            cursor.* += 16;
        }
    }

    pub fn cloneSize(self: *const @This(), size: *usize) void {
        size.* += ensureAligned(size.*, @alignOf(*@This())) + @sizeOf(@This());

        size.* += ensureAligned(size.*, @alignOf([]const FutureSalt));
        size.* += self.salts.len * @sizeOf(FutureSalt);
    }

    pub fn clone(self: *const @This(), dest: []u8, size: *usize) *@This() {
        size.* += ensureAligned(size.*, @alignOf(*@This()));
        const result = @as(*@This(), @alignCast(@ptrCast(dest[size.*..].ptr)));

        result.req_msg_id = self.req_msg_id;
        result.now = self.now;

        size.* += @sizeOf(@This());

        size.* += ensureAligned(size.*, @alignOf([]const FutureSalt));
        //result.salts = @as([]const FutureSalt, @alignCast());
        result.salts = @as([]const FutureSalt, @alignCast(std.mem.bytesAsSlice(FutureSalt, dest[size.* .. size.* + (self.salts.len * @sizeOf(FutureSalt))])));
        @memcpy(@constCast(result.salts), self.salts);
        size.* += self.salts.len * @sizeOf(FutureSalt);

        return result;
    }

    pub fn deserialize(src: []const u8, dest: []u8, cursor: *usize, written: *usize) *@This() {
        const alignment = ensureAligned(written.*, @alignOf(*@This()));
        const result = @as(*@This(), @alignCast(@ptrCast(dest[written.* + alignment ..].ptr)));
        written.* += alignment + @sizeOf(@This());

        cursor.* += deserializeInt(unwrapType(@TypeOf(result.req_msg_id)), src[cursor.*..], &result.req_msg_id);
        cursor.* += deserializeInt(unwrapType(@TypeOf(result.now)), src[cursor.*..], &result.now);

        const len = std.mem.readInt(u32, @ptrCast(src[cursor.* .. cursor.* + 4]), std.builtin.Endian.little);
        cursor.* += 4;

        written.* += ensureAligned(written.*, @alignOf(@TypeOf(result.salts)));
        const vector = @constCast(@as(@TypeOf(result.salts), @alignCast(std.mem.bytesAsSlice(unwrapType(@TypeOf(result.salts)), dest[written.* .. written.* + (len * @sizeOf(unwrapType(@TypeOf(result.salts))))]))));
        written.* += @sizeOf(unwrapType(@TypeOf(result.salts))) * len;

        for (0..len) |i| {
            cursor.* += deserializeInt(unwrapType(@TypeOf(vector[i].valid_since)), src[cursor.*..], &vector[i].valid_since);
            cursor.* += deserializeInt(unwrapType(@TypeOf(vector[i].valid_until)), src[cursor.*..], &vector[i].valid_until);
            cursor.* += deserializeInt(unwrapType(@TypeOf(vector[i].salt)), src[cursor.*..], &vector[i].salt);
        }

        result.salts = vector;

        return result;
    }
};

pub fn RPCResult(comptime ty: type) type {
    return struct {
        req_msg_id: u64,
        body: ty,

        pub fn serializedSize(self: *const @This()) usize {
            return 12 + self.body.serializedSize();
        }

        pub fn serialize(self: *const @This(), dest: []u8) usize {
            var written: usize = 0;

            written += serializeInt(@as(u32, 0xf35c6d01), dest[written..]);

            written += serializeInt(self.req_msg_id, dest[written..]);

            written += self.body.serialize(dest[written..]);

            return written;
        }

        pub fn deserializedSize(src: []const u8, cursor: *usize, size: *usize) void {
            size.* += ensureAligned(size.*, @alignOf(*@This())) + @sizeOf(@This());
            cursor.* += 8;

            ty.deserializedSize(src, cursor, size);
        }

        pub fn cloneSize(self: *const @This(), size: *usize) void {
            size.* += ensureAligned(size.*, @alignOf(*@This())) + @sizeOf(@This());
            self.body.cloneSize(size);
        }

        pub fn clone(self: *const @This(), dest: []u8, size: *usize) *@This() {
            size.* += ensureAligned(size.*, @alignOf(*@This()));
            const result = @as(*@This(), @alignCast(@ptrCast(dest[size.*..].ptr)));
            size.* += @sizeOf(@This());

            result.req_msg_id = self.req_msg_id;
            result.body = self.body.clone(dest, size);

            return result;
        }

        pub fn deserialize(src: []const u8, dest: []u8, cursor: *usize, written: *usize) *@This() {
            const alignment = ensureAligned(written.*, @alignOf(*@This()));
            const result = @as(*@This(), @alignCast(@ptrCast(dest[written.* + alignment ..].ptr)));
            written.* += alignment + @sizeOf(@This());

            cursor.* += deserializeInt(unwrapType(@TypeOf(result.req_msg_id)), src[cursor.*..], &result.req_msg_id);

            result.body = ty.deserialize(src, dest, cursor, written);

            return result;
        }
    };
}

// This type is required by some functions calls that might return a vector
pub fn Vector(comptime ty: type) type {
    return struct {
        elements: []const ty,

        // We don't do serialization with this type

        pub fn serializedSize(self: *const @This()) usize {
            _ = self;
            unreachable;
        }

        pub fn serialize(self: *const @This(), dest: []u8) usize {
            _ = self;
            _ = dest;
            unreachable;
        }

        pub fn cloneSize(self: *const @This(), size: *usize) void {
            size.* += ensureAligned(size.*, @alignOf(*@This())) + @sizeOf(@This());
            size.* += ensureAligned(size.*, @alignOf([]const ty));
            size.* += self.elements.len * @sizeOf(ty);
            for (self.elements) |element| {
                element.cloneSize(size);
            }
        }

        pub fn clone(self: *const @This(), dest: []u8, size: *usize) *@This() {
            size.* += ensureAligned(size.*, @alignOf(*@This()));
            const result = @as(*@This(), @alignCast(@ptrCast(dest[size.*..].ptr)));
            size.* += @sizeOf(@This());

            size.* += ensureAligned(size.*, @alignOf([]const ty));
            //result.elements = @as([]const ty, @alignCast(dest[size.* .. size.* + (@sizeOf(ty) * self.elements.len)]));
            result.elements = @as([]const ty, @alignCast(std.mem.bytesAsSlice(ty, dest[size.* .. size.* + (@sizeOf(ty) * self.elements.len)])));
            size.* += @sizeOf(ty) * self.elements.len;

            const elements = @constCast(result.elements);

            for (0..self.elements.len) |i| {
                elements[i] = self.elements[i].clone(dest, size);
            }

            return result;
        }

        pub fn deserializedSize(src: []const u8, cursor: *usize, size: *usize) void {
            size.* += ensureAligned(size.*, @alignOf(*@This())) + @sizeOf(@This());

            const len = std.mem.readInt(u32, @ptrCast(src[cursor.* .. cursor.* + 4]), std.builtin.Endian.little);
            cursor.* += 4;

            size.* += ensureAligned(size.*, @alignOf([]const ty));
            size.* += len * @sizeOf(ty);

            if (len > 0) {
                const el = src[cursor.*..].len / len;

                if (el != 4 and el != 8) {
                    for (0..len) |_| {
                        ty.deserializedSize(src, cursor, size);
                    }
                }
            }
        }

        pub fn deserialize(src: []const u8, dest: []u8, cursor: *usize, written: *usize) *@This() {
            const alignment = ensureAligned(written.*, @alignOf(*@This()));
            const result = @as(*@This(), @alignCast(@ptrCast(dest[written.* + alignment ..].ptr)));
            written.* += alignment + @sizeOf(@This());

            const len = std.mem.readInt(u32, @ptrCast(src[cursor.* .. cursor.* + 4]), std.builtin.Endian.little);
            cursor.* += 4;

            written.* += ensureAligned(written.*, @alignOf(@TypeOf(result.elements)));
            const vector = @constCast(@as(@TypeOf(result.elements), @alignCast(std.mem.bytesAsSlice(unwrapType(@TypeOf(result.elements)), dest[written.* .. written.* + (len * @sizeOf(unwrapType(@TypeOf(result.elements))))]))));
            written.* += @sizeOf(unwrapType(@TypeOf(result.elements))) * len;

            if (len > 0) {
                const el = src[cursor.*..].len / len;

                if (el == 4) {
                    for (0..len) |i| {
                        vector[i] = ty{ .Int = std.mem.readInt(i32, @ptrCast(src[cursor.* .. cursor.* + 4]), std.builtin.Endian.little) };
                        cursor.* += 4;
                    }
                } else if (el == 8) {
                    for (0..len) |i| {
                        vector[i] = ty{ .Long = std.mem.readInt(i64, @ptrCast(src[cursor.* .. cursor.* + 4]), std.builtin.Endian.little) };
                        cursor.* += 8;
                    }
                } else {
                    for (0..len) |i| {
                        vector[i] = ty.deserialize(src, dest, cursor, written);
                    }
                }
            }

            result.elements = vector;

            return result;
        }
    };
}

pub fn strSerializedSize(s: []const u8) usize {
    var result: usize = 0;
    if (s.len <= 253) {
        result = 1 + s.len;
    } else {
        result = 4 + s.len;
    }

    while (result % 4 != 0) : (result += 1) {}

    return result;
}

pub fn serializeString(in: []const u8, out: []u8) usize {
    var result: usize = 0;
    if (in.len <= 253) {
        out[0] = @intCast(in.len);
        result = 1;

        @memcpy(out[1 .. 1 + in.len], in);
        result += in.len;
    } else {
        out[0] = 254;
        const len = std.mem.toBytes(std.mem.nativeToLittle(usize, in.len));
        out[1] = len[0];
        out[2] = len[1];
        out[3] = len[2];
        result = 4;

        @memcpy(out[4 .. 4 + in.len], in);
        result += in.len;
    }

    while (result % 4 != 0) {
        out[result] = 0;
        result += 1;
    }

    return result;
}

pub fn strDeserializedSize(src: []const u8, read: *usize) usize {
    var len: usize = src[0];
    var lenn: usize = 0;

    if (len >= 254) {
        read.* += 4;
        lenn += 4;
        var actualLen: [4]u8 = undefined;

        @memcpy((&actualLen)[0..3], src[1..4]);
        actualLen[3] = 0;
        len = std.mem.readInt(u32, &actualLen, std.builtin.Endian.little);
    } else {
        read.* += 1;
        lenn += 1;
    }

    read.* += len;

    lenn += len;

    while (lenn % 4 != 0) {
        read.* += 1;
        lenn += 1;
    }

    return len;
}

pub fn serializeInt(in: anytype, out: []u8) usize {
    const in_ty: @TypeOf(in) = in;
    switch (@TypeOf(in_ty)) {
        i64, u64, i32, u32, f64, i128, u128, i256, u256 => {
            const bytes = std.mem.toBytes(std.mem.nativeToLittle(@TypeOf(in_ty), in));
            @memcpy(out[0..bytes.len], &bytes);
            return @sizeOf(@TypeOf(in_ty));
        },
        usize => {
            const bytes = std.mem.toBytes(std.mem.nativeToLittle(u32, @intCast(in)));
            @memcpy(out[0..bytes.len], &bytes);
            return @sizeOf(u32);
        },
        else => {
            @compileError("Unsupported type");
        },
    }
}

pub fn deserializeInt(comptime T: type, in: []const u8, out: *T) usize {
    switch (T) {
        i64, u64, i32, u32, i128, u128, i256, u256 => {
            const bytes = in[0..@sizeOf(T)];
            out.* = std.mem.readInt(T, bytes, std.builtin.Endian.little);
            return @sizeOf(T);
        },
        f64 => {
            const bytes = in[0..@sizeOf(f64)];
            out.* = @bitCast(std.mem.readInt(u64, bytes, std.builtin.Endian.little));
            return @sizeOf(f64);
        },
        usize => {
            const bytes = in[0..@sizeOf(u32)];
            out.* = @as(usize, std.mem.readInt(u32, bytes, std.builtin.Endian.little));
            return @sizeOf(u32);
        },
        else => {
            @compileError("Unsupported type");
        },
    }
}

pub fn deserializeString(src: []const u8, dest: *[]const u8) usize {
    var read: usize = 0;
    var len: usize = src[0];
    if (len >= 254) {
        read += 4;
        var actualLen: [4]u8 = undefined;

        @memcpy((&actualLen)[0..3], src[1..4]);
        actualLen[3] = 0;

        len = std.mem.readInt(u32, &actualLen, std.builtin.Endian.little);
        dest.* = dest.*[0..len];
        @memcpy(@constCast(dest.*), src[4 .. 4 + len]);
    } else {
        read += 1;
        dest.* = dest.*[0..len];
        @memcpy(@constCast(dest.*), src[1 .. 1 + len]);
    }
    read += len;

    while (read % 4 != 0) {
        std.debug.assert(src[read] == 0);
        read += 1;
    }

    return read;
}

/// Calculates how many bytes are needed to align a pointer
pub fn ensureAligned(in: usize, align_n: usize) usize {
    var result: usize = 0;

    while ((in + result) % align_n != 0) {
        result += 1;
    }

    return result;
}

test "serialize string" {
    const data = "qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890q";

    const allocator = std.testing.allocator;

    const size = strSerializedSize(data);
    try std.testing.expectEqual(256, size);

    const dest = try allocator.alloc(u8, size);
    defer allocator.free(dest);

    const written = serializeString(data, dest);
    try std.testing.expectEqual(256, written);

    const expected = [_]u8{ 253, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 0, 0 };

    try std.testing.expectEqualStrings(&expected, dest);
}

test "serialize long string" {
    const data = "qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm12345678a90";

    const allocator = std.testing.allocator;

    const size = strSerializedSize(data);
    try std.testing.expectEqual(332, size);

    const dest = try allocator.alloc(u8, size);
    defer allocator.free(dest);

    const written = serializeString(data, dest);
    try std.testing.expectEqual(332, written);

    const expected = [_]u8{ 254, 69, 1, 0, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 97, 57, 48, 0, 0, 0 };

    try std.testing.expectEqualStrings(&expected, dest);
}

test "deserialize string" {}

test "deserialize long string" {
    const allocator = std.testing.allocator;
    defer _ = std.testing.allocator_instance.detectLeaks();

    const data = [_]u8{ 254, 69, 1, 0, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 97, 57, 48, 0, 0, 0 };

    var read: usize = 0;
    var dest: []const u8 = try allocator.alloc(u8, strDeserializedSize(&data, &read));
    defer allocator.free(dest);

    read = deserializeString(&data, &dest);

    try std.testing.expectEqual(332, read);

    try std.testing.expectEqualStrings("qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm12345678a90", dest);
}

pub fn vectorLen(src: []const u8, read: *usize) usize {
    const vid = std.mem.readInt(u32, src[0..4], std.builtin.Endian.little);
    std.debug.assert(vid == 0x1cb5c415);

    const len = std.mem.readInt(u32, src[4..8], std.builtin.Endian.little);

    read.* += 8;

    return len;
}

const DeserializeError = error{InvalidBool};

pub fn deserializeTLVector(allocator: std.mem.Allocator, src: []const u8, comptime T: type, deserializer: *const anyopaque) !.{ usize, []*const T } {
    _ = deserializer;
    _ = allocator;
    var ty = T;

    while (@typeInfo(ty).pointer) {
        ty = @typeInfo(ty).pointer.child;

        var read: usize = 4;

        if (std.mem.readInt(u32, src[0..4], std.builtin.Endian.little) != 0x1cb5c415) {
            return DeserializeError.InvalidVectorID;
        }

        //var len: usize = std.mem.readInt(u32, src[4..8], std.builtin.Endian.little);
        read += 4;
    }
}

pub fn deserializeBool(src: []const u8, read: *usize) bool {
    const id = std.mem.readInt(u32, src[0..4], std.builtin.Endian.little);
    if (id == 0x997275b5) {
        read.* += 4;
        return true;
    } else if (id == 0xbc799737) {
        read.* += 4;
        return false;
    } else {
        @panic("Invalid bool id");
    }
}

pub fn unwrapType(comptime T: type) type {
    switch (@typeInfo(T)) {
        .optional => {
            return unwrapType(@typeInfo(T).optional.child);
        },
        .pointer => {
            return @typeInfo(T).pointer.child;
        },
        else => {
            return T;
        },
    }
}
