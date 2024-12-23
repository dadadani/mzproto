const std = @import("std");

pub const TLBool = enum(u8) { False, True };

pub const FutureSalt = struct {
    valid_since: u32,
    valid_until: u32,
    salt: u64,
};

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

pub fn deserializeString(allocator: std.mem.Allocator, src: []const u8, dest: *[]const u8) !usize {
    var read: usize = 0;
    var len: usize = src[0];
    if (len >= 254) {
        read += 4;
        var actualLen: [4]u8 = undefined;

        @memcpy((&actualLen)[0..3], src[1..4]);
        actualLen[3] = 0;

        len = std.mem.readInt(u32, &actualLen, std.builtin.Endian.little);
        dest.* = try allocator.alloc(u8, len);
        @memcpy(@constCast(dest.*), src[4 .. 4 + len]);
    } else {
        read += 1;
        dest.* = try allocator.alloc(u8, len);
        @memcpy(@constCast(dest.*), src[1 .. 1 + len]);
    }
    read += len;

    while (read % 4 != 0) {
        std.debug.assert(src[read] == 0);
        read += 1;
    }

    return read;
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

test "deserialize string" {
    const data = [_]u8{ 253, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 0, 0 };

    const allocator = std.testing.allocator;
    defer _ = std.testing.allocator_instance.detectLeaks();

    var dest: []const u8 = undefined;

    const read = try deserializeString(allocator, &data, &dest);
    defer allocator.free(dest);

    try std.testing.expectEqual(256, read);

    try std.testing.expectEqualStrings("qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjklzxcvbnm1234567890q", dest);
}

test "deserialize long string" {
    const allocator = std.testing.allocator;
    defer _ = std.testing.allocator_instance.detectLeaks();

    const data = [_]u8{ 254, 69, 1, 0, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 97, 57, 48, 0, 0, 0 };

    var dest: []const u8 = undefined;

    const read = try deserializeString(allocator, &data, &dest);
    defer allocator.free(dest);

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
            @compileError("Unsupported type");
        },
    }
}
