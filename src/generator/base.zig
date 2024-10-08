const std = @import("std");

pub const TLId = enum(u32) {
    InputFile = 0xf52ff27f,
    InputFileBig = 0xfa4f0bb5,
};

pub const TLObjects = union(TLId) {
    InputFile: struct { id: u64, parts: u32, name: []const u8, md5_checksum: []const u8 },
    InputFileBig: struct {
        id: u64,
        parts: u32,
        name: []const u8,
    },
};

pub const Test = struct {
    asd: u32,
    asdtest: [][]const u8,
};

fn unionPayloadPtr(comptime T: type, union_ptr: anytype) ?*T {
    const U = @typeInfo(@TypeOf(union_ptr)).Pointer.child;
    var i = 0;
    inline for (@typeInfo(U).Union.fields) |field| {
        defer i += 1;
        if (field.field_type != T)
            continue;
        if (@intFromEnum(union_ptr.*) == i)
            return &@field(union_ptr, field.name);
    }
    return null;
}

pub fn encodedSize(ty: type, in: anytype) usize {
    const in_ty: ty = in;
    const info = @typeInfo(@TypeOf(in_ty));
    switch (info) {
        .Struct => {
            var result: usize = 0;
            result = result;
            inline for (std.meta.fields(@TypeOf(in_ty))) |field| {
                //_ = field;
                result += encodedSize(field.type, @field(in_ty, field.name));
            }
            return result;
        },
        .Union => {
            const field = unionPayloadPtr(@TypeOf(in_ty), in_ty);
            if (field == null) {
                @panic("failed to access union field");
            }
            return field.encodedSize();
        },
        .Array, .Pointer => {
            if (@TypeOf(in_ty) == []const u8 or @TypeOf(in_ty) == []u8) {
                return strEncodedSize(in_ty);
            }
            return vectorEncodedSize(in_ty);
        },
        .Int => {
            switch (@TypeOf(in_ty)) {
                i64, u64, i32, u32, f64, i128, u128, i256, u256 => {
                    return @sizeOf(@TypeOf(in_ty));
                },
                usize => {
                    return @sizeOf(u32);
                },
                else => {
                    @panic("Unsupported type");
                },
            }
        },
        else => {
            std.debug.print("got {}", .{info});
            @panic("a");
        },
    }
}

fn vectorEncodedSize(in: anytype) usize {
    // structure of a vector: id (4 bytes) + # (4 bytes) + each element
    var result: usize = 4 + 4;

    for (in) |data| {
        result += encodedSize(@TypeOf(data), data);
    }
    return result;
}

inline fn strEncodedSize(s: []const u8) usize {
    var result: usize = 0;
    if (s.len <= 253) {
        result = 1 + s.len;
    } else {
        result = 3 + s.len;
    }

    while (result % 4 != 0) : (result += 1) {}

    return result;
}

pub fn strEncode(in: []const u8, out: []u8) usize {
    var result: usize = 0;
    if (in.len <= 253) {
        out[0] = @intCast(in.len);
        result = 1;
    } else {
        out[0] = 254;
        const len = std.mem.toBytes(std.mem.nativeToLittle(usize, in.len));
        out[1] = len[0];
        out[2] = len[1];
        out[3] = len[2];
        result = 4;
    }

    @memcpy(out[4 .. 4 + in.len], in);
    result += in.len;

    while (result % 4 != 0) {
        out[result] = 0;
        result += 1;
    }

    return result;
}
