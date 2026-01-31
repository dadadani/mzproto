const std = @import("std");

pub const ProtoMessage = struct {
    msg_id: u64,
    seqno: i32,
    body: []const u8,

    pub fn deserializeNoCopy(in: []const u8) @This() {
        var read: usize = 0;
        var self: @This() = undefined;

        self.msg_id = std.mem.readInt(u64, @ptrCast(in[read .. read + 8]), std.builtin.Endian.little);
        read += 8;

        self.seqno = std.mem.readInt(i32, @ptrCast(in[read .. read + 4]), std.builtin.Endian.little);
        read += 4;

        const bytes = std.mem.readInt(u32, @ptrCast(in[read .. read + 4]), std.builtin.Endian.little);
        read += 4;

        self.body = in[read .. read + bytes];

        return self;
    }
};

pub const ProtoMessageContainer = struct {
    pub fn deserializeContainer(allocator: std.mem.Allocator, in: []const u8) ![]ProtoMessage {
        const len = std.mem.readInt(u32, in[0..4], .little);

        const container = try allocator.alloc(ProtoMessage, len);
        errdefer allocator.free(container);

        var read: usize = 4;

        for (0..len) |i| {
            container[i].msg_id = std.mem.readInt(u64, @ptrCast(in[read .. read + 8]), std.builtin.Endian.little);
            read += 8;

            container[i].seqno = std.mem.readInt(i32, @ptrCast(in[read .. read + 4]), std.builtin.Endian.little);
            read += 4;

            const bytes = std.mem.readInt(u32, @ptrCast(in[read .. read + 4]), std.builtin.Endian.little);
            read += 4;

            container[i].body = in[read .. read + bytes];

            read += bytes;
        }

        return container;
    }

    pub fn serializeSize(self: *const @This()) usize {
        _ = self;
        unreachable;
    }

    pub fn serialize(self: *const @This(), dest: []u8) usize {
        _ = self;
        _ = dest;
        unreachable;
    }

    pub fn deserializeSize(in: []const u8, size: *usize) usize {
        // we only use deserializeNoCopy on this one
        _ = in;
        _ = size;
        unreachable;
    }

    pub fn cloneSize(self: *const @This(), size: *usize) void {
        // not needed
        _ = self;
        _ = size;
        unreachable;
    }

    pub fn clone(self: *const @This(), out: []align(@alignOf(@This())) u8) struct { *@This(), usize } {
        // not needed
        _ = self;
        _ = out;
        unreachable;
    }

    pub fn deserialize(in: []const u8, out: []align(@alignOf(@This())) u8) struct { *@This(), usize, usize } {
        // we only use deserializeNoCopy on this one
        _ = in;
        _ = out;
        unreachable;
    }
};

pub fn IProtoFutureSalts(comptime TL: type, comptime ProtoFutureSalt: type) type {
    const InternalProtoFutureSalts = ProtoFutureSalts(TL, ProtoFutureSalt);

    return struct {
        pub inline fn deserializeSize(in: []const u8, size: *usize) usize {
            const id = std.mem.readInt(u32, @ptrCast(in[0..4]), .little);
            std.debug.assert(id == 0xae500895);
            size.* += (@alignOf(InternalProtoFutureSalts) - 1);
            return InternalProtoFutureSalts.deserializeSize(in[4..], size);
        }

        pub fn deserialize(src: []const u8, out: []u8) struct { *InternalProtoFutureSalts, usize, usize } {
            const id = std.mem.readInt(u32, @ptrCast(src[0..4]), .little);
            std.debug.assert(id == 0xae500895);

            return InternalProtoFutureSalts.deserialize(src[4..], @alignCast(out[(@alignOf(InternalProtoFutureSalts) - 1)..]));
        }
    };
}

pub fn ProtoFutureSalts(comptime TL: type, comptime ProtoFutureSalt: type) type {
    return struct {
        req_msg_id: u64,
        now: u32,
        salts: []const ProtoFutureSalt,

        pub fn serializeSize(self: *const @This()) usize {
            return 16 + (self.salts.len * 16);
        }

        pub fn toTL(self: *const @This()) TL {
            return TL{ .ProtoFutureSalts = self };
        }

        pub fn serialize(self: *const @This(), dest: []u8) usize {
            var written: usize = 0;
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

        pub fn deserializeSize(in: []const u8, size: *usize) usize {
            size.* += @sizeOf(@This());
            var read: usize = 12;

            const len = std.mem.readInt(u32, @ptrCast(in[read .. read + 4]), std.builtin.Endian.little);
            read += 4;

            size.* += ensureAligned(size.*, @alignOf([]const ProtoFutureSalt));
            size.* += len * @sizeOf(ProtoFutureSalt);
            for (0..len) |_| {
                read += 16;
            }
            return read;
        }

        pub fn cloneSize(self: *const @This(), size: *usize) void {
            size.* += @sizeOf(@This());

            size.* += ensureAligned(size.*, @alignOf([]const ProtoFutureSalt));
            size.* += self.salts.len * @sizeOf(ProtoFutureSalt);
        }

        pub fn clone(self: *const @This(), out: []align(@alignOf(@This())) u8) struct { *@This(), usize } {
            var written: usize = 0;
            const self_out = @as(*@This(), @ptrCast(@alignCast(out[0..].ptr)));

            self_out.req_msg_id = self.req_msg_id;
            self_out.now = self.now;

            written += @sizeOf(@This());

            written += ensureAligned(@intFromPtr(out[written..].ptr), @alignOf([]const ProtoFutureSalt));
            //result.salts = @as([]const FutureSalt, @alignCast());
            self_out.salts = @as([]const ProtoFutureSalt, @alignCast(std.mem.bytesAsSlice(ProtoFutureSalt, out[written .. written + (self.salts.len * @sizeOf(ProtoFutureSalt))])));
            @memcpy(@constCast(self_out.salts), self.salts);
            written += self.salts.len * @sizeOf(ProtoFutureSalt);

            return .{ self_out, written };
        }

        pub fn deserialize(src: []const u8, out: []align(@alignOf(@This())) u8) struct { *@This(), usize, usize } {
            //const alignment = ensureAligned(written.*, @alignOf(*@This()));

            const self = @as(*@This(), @ptrCast(@alignCast(out[0..].ptr)));
            var written: usize = @sizeOf(@This());
            var read: usize = 0;

            read += deserializeInt(unwrapType(@TypeOf(self.req_msg_id)), src[read..], &self.req_msg_id);
            read += deserializeInt(unwrapType(@TypeOf(self.now)), src[read..], &self.now);

            const len = std.mem.readInt(u32, @ptrCast(src[read .. read + 4]), std.builtin.Endian.little);
            read += 4;

            written += ensureAligned(@intFromPtr(out[written..].ptr), @alignOf(@TypeOf(self.salts)));
            const vector = @constCast(@as(@TypeOf(self.salts), @alignCast(std.mem.bytesAsSlice(unwrapType(@TypeOf(self.salts)), out[written .. written + (len * @sizeOf(unwrapType(@TypeOf(self.salts))))]))));
            written += @sizeOf(unwrapType(@TypeOf(self.salts))) * len;

            for (0..len) |i| {
                read += deserializeInt(unwrapType(@TypeOf(vector[i].valid_since)), src[read..], &vector[i].valid_since);
                read += deserializeInt(unwrapType(@TypeOf(vector[i].valid_until)), src[read..], &vector[i].valid_until);
                read += deserializeInt(unwrapType(@TypeOf(vector[i].salt)), src[read..], &vector[i].salt);
            }

            self.salts = vector;

            return .{ self, written, read };
        }
    };
}
pub fn ProtoRPCResult() type {
    return struct {
        req_msg_id: u64,
        body: []const u8,

        pub fn deserializeNoCopy(in: []const u8) @This() {
            return .{ .req_msg_id = std.mem.readInt(u64, in[0..8], .little), .body = in[8..] };
        }

        pub fn serializeSize(self: *const @This()) usize {
            _ = self;
            unreachable;
        }

        pub fn serialize(self: *const @This(), dest: []u8) usize {
            _ = self;
            _ = dest;
            unreachable;
        }

        pub fn deserializeSize(in: []const u8, size: *usize) usize {
            // we only use deserializeNoCopy on this one
            _ = in;
            _ = size;
            unreachable;
        }

        pub fn cloneSize(self: *const @This(), size: *usize) void {
            // not needed
            _ = self;
            _ = size;
            unreachable;
        }

        pub fn clone(self: *const @This(), out: []align(@alignOf(@This())) u8) struct { *@This(), usize } {
            // not needed
            _ = self;
            _ = out;
            unreachable;
        }

        pub fn deserialize(in: []const u8, out: []align(@alignOf(@This())) u8) struct { *@This(), usize, usize } {
            // we only use deserializeNoCopy on this one
            _ = in;
            _ = out;
            unreachable;
        }
    };
}

pub const ProtoRpcError = struct {
    error_code: u32,
    error_message: []const u8,

    pub fn deserializeNoCopy(in: []const u8) ProtoRpcError {
        return .{ .error_code = std.mem.readInt(u32, @ptrCast(in[0 .. 0 + @sizeOf(u32)]), .little), .error_message = deserializeStringNoCopy(in[4..]) };
    }

    pub fn deserializeSize(in: []const u8, size: *usize) usize {
        size.* += @sizeOf(ProtoRpcError);
        var read: usize = 0;
        read += @sizeOf(u32);
        size.* += strDeserializedSize(in[read..], &read);
        return read;
    }
    pub fn deserialize(noalias in: []const u8, noalias out: []align(@alignOf(ProtoRpcError)) u8) struct { *ProtoRpcError, usize, usize } {
        var written: usize = @sizeOf(ProtoRpcError);
        const self = @as(*ProtoRpcError, @ptrCast(@alignCast(out[0..@sizeOf(ProtoRpcError)])));
        var read: usize = 0;
        {
            const d = std.mem.readInt(u32, @ptrCast(in[read .. read + @sizeOf(u32)]), std.builtin.Endian.little);
            read += @sizeOf(u32);
            self.error_code = d;
        }
        {
            const d = deserializeString(in[read..], out[written..]);
            self.error_message = out[written .. written + d[0]];
            written += d[0];
            read += d[1];
        }
        return .{ self, written, read };
    }
    pub fn serializeSize(self: *const ProtoRpcError) usize {
        var size: usize = 0;
        size += @sizeOf(@TypeOf(self.error_code));
        size += strSerializedSize(self.error_message);
        return size;
    }
    pub fn serialize(self: *const ProtoRpcError, out: []u8) usize {
        var written: usize = 0;
        written += serializeInt(self.error_code, out[written..]);
        written += serializeString(self.error_message, out[written..]);
        return written;
    }
    pub fn cloneSize(self: *const ProtoRpcError, size: *usize) void {
        size.* += @sizeOf(ProtoRpcError);
        size.* += self.error_message.len;
    }
    pub fn clone(self: *const ProtoRpcError, out: []align(@alignOf(ProtoRpcError)) u8) struct { *ProtoRpcError, usize } {
        var written: usize = @sizeOf(ProtoRpcError);
        const self_out: *ProtoRpcError = @ptrCast(@alignCast(out[0..@sizeOf(ProtoRpcError)]));
        @memcpy(out[0..@sizeOf(ProtoRpcError)], @as([*]const u8, @ptrCast(self))[0..@sizeOf(ProtoRpcError)]);
        @memcpy(out[written .. written + self.error_message.len], self.error_message);
        self_out.error_message = out[written .. written + self.error_message.len];
        written += self.error_message.len;
        return .{ self_out, written };
    }
};

// This type is required by some functions calls that might return a vector
pub fn Vector(comptime ty: type) type {
    return struct {
        elements: []const ty,

        // We don't do serialization with this type

        pub fn serializeSize(self: *const @This()) usize {
            _ = self;
            unreachable;
        }

        pub fn serialize(self: *const @This(), dest: []u8) usize {
            _ = self;
            _ = dest;
            unreachable;
        }

        pub fn cloneSize(self: *const @This(), size: *usize) void {
            size.* += @sizeOf(@This());
            size.* += ensureAligned(size.*, @alignOf([]const ty));
            size.* += self.elements.len * @sizeOf(ty);
            for (self.elements) |element| {
                element.cloneSize(size);
            }
        }

        pub fn clone(self: *const @This(), out: []align(@alignOf(@This())) u8) struct { *@This(), usize } {
            const self_out = @as(*@This(), @ptrCast(@alignCast(out[0..].ptr)));
            var written: usize = 0;

            written += @sizeOf(@This());

            written += ensureAligned(@intFromPtr(out[written..].ptr), @alignOf([]const ty));
            //result.elements = @as([]const ty, @alignCast(dest[size.* .. size.* + (@sizeOf(ty) * self.elements.len)]));
            self_out.elements = @as([]const ty, @alignCast(std.mem.bytesAsSlice(ty, out[written .. written + (@sizeOf(ty) * self.elements.len)])));
            written += @sizeOf(ty) * self.elements.len;

            const elements = @constCast(self_out.elements);

            for (0..self.elements.len) |i| {
                const cloned = self.elements[i].clone(out[written..]);
                elements[i] = cloned[0];
                written += cloned[1];
            }

            return .{ self_out, written };
        }

        pub fn deserializeSize(in: []const u8, size: *usize) usize {
            size.* += @sizeOf(@This());
            var read: usize = 0;

            const len = std.mem.readInt(u32, @ptrCast(in[read .. read + 4]), std.builtin.Endian.little);
            read += 4;

            size.* += ensureAligned(size.*, @alignOf([]const ty));
            size.* += len * @sizeOf(ty);

            if (len > 0) {
                const el = in[read..].len / len;

                if (el != 4 and el != 8) {
                    for (0..len) |_| {
                        read += ty.deserializeSize(in[read..], size);
                    }
                } else {
                    read += in[read..].len;
                }
            }

            return read;
        }

        pub fn deserialize(in: []const u8, out: []align(@alignOf(@This())) u8) struct { *@This(), usize, usize } {
            const self = @as(*@This(), @ptrCast(@alignCast(out[0..].ptr)));
            var written: usize = @sizeOf(@This());
            var read: usize = 0;

            const len = std.mem.readInt(u32, @ptrCast(in[read .. read + 4]), std.builtin.Endian.little);
            read += 4;

            written += ensureAligned(@intFromPtr(out[written..].ptr), @alignOf(@TypeOf(self.elements)));
            const vector = @constCast(@as(@TypeOf(self.elements), @alignCast(std.mem.bytesAsSlice(unwrapType(@TypeOf(self.elements)), out[written .. written + (len * @sizeOf(unwrapType(@TypeOf(self.elements))))]))));
            written += @sizeOf(unwrapType(@TypeOf(self.elements))) * len;

            if (len > 0) {
                const el = in[read..].len / len;

                // TODO: Although this works, we should change the TL parser to actually provide a "result decoder", we have the expected type in the schema already
                if (el == 4) {
                    for (0..len) |i| {
                        vector[i] = ty{ .Int = std.mem.readInt(u32, @ptrCast(in[read .. read + 4]), std.builtin.Endian.little) };
                        read += 4;
                    }
                } else if (el == 8) {
                    for (0..len) |i| {
                        vector[i] = ty{ .Long = std.mem.readInt(u64, @ptrCast(in[read .. read + 8]), std.builtin.Endian.little) };
                        read += 8;
                    }
                } else {
                    for (0..len) |i| {
                        const d = ty.deserialize(in[written..], out[read..]);
                        vector[i] = d[0];
                        written += d[1];
                        read += d[2];
                    }
                }
            }

            self.elements = vector;

            return .{ self, written, read };
        }
    };
}

pub inline fn makePadding(n: anytype, topad: anytype) usize {
    const remainder = topad % n;
    return if (remainder == 0) 0 else n - remainder;
}

/// Returns how many bytes are needed to encode bytes into a TL string. Includes length and padding
pub fn strSerializedSize(s: []const u8) usize {
    const len_headers: usize =
        if (s.len <= 253)
            // If the length of `s` is <= 253, only one byte is sent
            1
        else
            // If the length of `s` is >= 254, we send one byte with value `254` followed by the length as 3 bytes in little-endian order
            1 + 3;

    const len = len_headers + s.len;

    // The total length must be divisible by 4
    const padding = makePadding(4, len);

    return len + padding;
}

/// Serializes bytes into a TL encoded string.
/// Returns how many bytes were written.
///
/// You may check how many bytes are needed for the output with `strSerializedSize`.
pub fn serializeString(noalias in: []const u8, noalias out: []u8) usize {
    std.debug.assert(in.len <= std.math.maxInt(u24));

    if (in.len <= 253) {
        // I guess most of the time we would have a shorter string
        @branchHint(.likely);

        // 1 byte for the length, followed by the string itself
        const len = 1 + in.len;
        const padding = makePadding(4, len);

        out[0] = @intCast(in.len);
        @memcpy(out[1 .. 1 + in.len], in);

        // Set the padding bytes to 0
        @memset(out[len .. len + padding], 0);

        return len + padding;
    }

    // 1 + 3 byte for the length, followed by the string itself
    const len = 1 + 3 + in.len;
    const padding = makePadding(4, len);

    // Always 254
    out[0] = 254;

    // The length of `in`, encoded as 3 bytes in little-endian order
    std.mem.writeInt(u24, out[1..4], @intCast(in.len), .little);

    @memcpy(out[4 .. 4 + in.len], in);

    // Set the padding bytes to 0
    @memset(out[len .. len + padding], 0);

    return len + padding;
}

/// Returns the size of the TL encoded string once deserialized.
/// Writes the length of the full serialized sequence into `read`
pub fn strDeserializedSize(src: []const u8, read: *usize) usize {
    if (src[0] <= 253) {
        // I guess most of the time we would have a shorter string
        @branchHint(.likely);

        const len_serialized = 1 + @as(u32, src[0]);
        const padding = makePadding(4, len_serialized);

        read.* += len_serialized + padding;

        return src[0];
    }

    const len = std.mem.readInt(u24, src[1..4], .little);

    const len_serialized = 1 + 3 + @as(u32, len);
    const padding = makePadding(4, len_serialized);

    read.* += len_serialized + padding;

    return len;
}

/// Deserializes a TL encoded string into a sequence of bytes
///
/// Returns 1. How many bytes were deserialized 2. How many bytes were read
///
/// You may check how many bytes are needed for the output with `strDeserializedSize`.
pub fn deserializeString(noalias src: []const u8, noalias dest: []u8) struct { usize, usize } {
    if (src[0] <= 253) {
        // I guess most of the time we would have a shorter string
        @branchHint(.likely);

        const len_serialized = 1 + @as(u32, src[0]);
        const padding = makePadding(4, len_serialized);

        @memcpy(dest[0..src[0]], src[1..len_serialized]);

        return .{ src[0], len_serialized + padding };
    }

    const len = std.mem.readInt(u24, src[1..4], .little);

    const len_serialized = 1 + 3 + @as(u32, len);
    const padding = makePadding(4, len_serialized);

    @memcpy(dest[0..len], src[1 + 3 .. len_serialized]);

    return .{ len, len_serialized + padding };
}

pub fn deserializeStringNoCopy(src: []const u8) []const u8 {
    if (src[0] <= 253) {
        // I guess most of the time we would have a shorter string
        @branchHint(.likely);

        const len_serialized = 1 + @as(u32, src[0]);
        //const padding = makePadding(4, len_serialized);

        return src[1..len_serialized];
    }

    const len = std.mem.readInt(u24, src[1..4], .little);

    const len_serialized = 1 + 3 + @as(u32, len);
    //const padding = makePadding(4, len_serialized);

    return src[1 + 3 .. len_serialized];
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
            std.mem.writeInt(u32, @ptrCast(out[0..4]), @intCast(in), .little);

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

pub fn bytesToSlice(in: []u8, size: usize, comptime T: type) struct { []T, usize } {
    const alignment = ensureAligned(@intFromPtr(in.ptr), @alignOf(T));
    const real_size = size * @sizeOf(T);
    const slice = std.mem.bytesAsSlice(T, in[alignment .. alignment + real_size]);

    return .{ @ptrCast(@alignCast(@constCast(slice))), alignment + real_size };

    //const {s}_vector = @constCast(@as(@TypeOf(result.{s}), @alignCast(std.mem.bytesAsSlice(base.unwrapType(@TypeOf(result.{s})), dest[written.* .. written.* + (len * @sizeOf(base.unwrapType(@TypeOf(result.{s}))))]))));
}

pub fn ensureAligned(in: usize, align_n: usize) usize {
    const remainder = in % align_n;
    return if (remainder == 0) 0 else align_n - remainder;
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

    const expected = "qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm12345678a90";

    const data = [_]u8{ 254, 69, 1, 0, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 97, 57, 48, 0, 0, 0 };

    var read: usize = 0;
    const dest = try allocator.alloc(u8, strDeserializedSize(&data, &read));
    defer allocator.free(dest);

    const desr = deserializeString(&data, dest);

    try std.testing.expectEqual(expected.len, desr[0]);

    try std.testing.expectEqual(332, desr[1]);

    try std.testing.expectEqualStrings(expected, dest);
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

pub fn TLInt(comptime TL: type, value: anytype) TL {
    switch (@TypeOf(value)) {
        u32, i32 => {
            return TL{ .Int = @bitCast(value) };
        },
        u64, i64 => {
            return TL{ .Long = @bitCast(value) };
        },
        else => @compileError("unsupported"),
    }
}

pub fn shortTypeName(comptime T: type) []const u8 {
    var iter = std.mem.splitBackwardsScalar(u8, @typeName(T), '.');
    return iter.first();
}
