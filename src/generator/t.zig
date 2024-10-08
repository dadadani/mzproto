const std = @import("std");
const base = @import("./base.zig");

const TlEnum = enum(u32) {
    InputFile = 0xf52ff27f,
    inputFileBig = 0xfa4f0bb5,
};

const TL = struct {
    ptr: *anyopaque,
    encodedSizefn: *const fn (self: *anyopaque) usize,
    encodefn: *const fn (self: *anyopaque, buffer: []u8) usize,

    pub fn encodedSize(self: TL) usize {
        return self.encodedSizefn(self.ptr);
    }

    pub fn encode(self: TL, buffer: []u8) usize {
        return self.encodefn(self.ptr, buffer);
    }

    pub fn init(ptr: anytype) TL {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn encodedSize(pointer: *anyopaque) usize {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.Pointer.child.encodedSize(self);
            }

            pub fn encode(pointer: *anyopaque, buffer: []u8) usize {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.Pointer.child.encode(self, buffer);
            }
        };

        return .{
            .ptr = ptr,
            .encodedSizefn = gen.encodedSize,
            .encodefn = gen.encode,
        };
    }
};

const InputFile = struct {
    id: i64,
    parts: i32,
    name: []const u8,
    md5_checksum: []const u8,

    pub fn encodedSize(ptr: *anyopaque) usize {
        const self: *InputFile = @ptrCast(@alignCast(ptr));
        return @sizeOf(u32) + @sizeOf(@TypeOf(self.id)) + @sizeOf(@TypeOf(self.parts)) + base.strEncodedSize(self.name) + base.strEncodedSize(self.md5_checksum);
    }

    pub fn encode(ptr: *anyopaque, buffer: []u8) usize {
        const self: *InputFile = @ptrCast(@alignCast(ptr));
        var cursor: usize = 0;
        @memcpy(buffer[cursor .. cursor + @sizeOf(u32)], std.mem.toBytes(std.mem.nativeToLittle(u32, TlEnum.InputFile)));
        cursor += @sizeOf(u32);
        @memcpy(buffer[cursor .. cursor + @sizeOf(i64)], std.mem.toBytes(std.mem.nativeToLittle(i64, self.id)));
        cursor += @sizeOf(i64);
        @memcpy(buffer[cursor .. cursor + @sizeOf(i32)], std.mem.toBytes(std.mem.nativeToLittle(i32, self.parts)));
        cursor += @sizeOf(i32);
        cursor += base.strEncode(self.name, buffer[cursor..]);
        cursor += base.strEncode(self.md5_checksum, buffer[cursor..]);
        return cursor;
    }
};

const InputFileBig = struct {
    id: i64,
    parts: i32,
    name: []const u8,

    pub fn encodedSize(self: *const InputFileBig) usize {
        var result: usize = @sizeOf(u32);
        inline for (std.meta.fields(@TypeOf(self.*))) |field| {
            if (field.type == []const u8) {
                result += base.strEncodedSize(@field(self, field.name));
            } else {
                result += @sizeOf(field.type);
            }
        }
        return result;
    }

    pub fn encode(self: *const InputFileBig, buffer: []u8) usize {
        var size: usize = 0;
        @memcpy(buffer[size .. size + @sizeOf(u32)], &std.mem.toBytes(std.mem.nativeToLittle(u32, @intFromEnum(TlEnum.inputFileBig))));
        size += @sizeOf(u32);
        inline for (std.meta.fields(@TypeOf(self.*))) |field| {
            if (field.type == []const u8) {
                const str_field = @field(self, field.name);
                size += base.strEncode(str_field, buffer[size..]);
            } else {
                @memcpy(buffer[size .. size + @sizeOf(field.type)], &std.mem.toBytes(std.mem.nativeToLittle(@TypeOf(@field(self, field.name)), @field(self, field.name))));
                size += @sizeOf(field.type);
            }
        }
        return size;
        //var cursor: usize = 0;
        //@memcpy(buffer[cursor .. cursor + @sizeOf(u32)], &std.mem.toBytes(std.mem.nativeToLittle(u32, @intFromEnum(TlEnum.inputFileBig))));
        //cursor += @sizeOf(u32);
        //@memcpy(buffer[cursor .. cursor + @sizeOf(i64)], &std.mem.toBytes(std.mem.nativeToLittle(i64, self.id)));
        //cursor += @sizeOf(i64);
        //@memcpy(buffer[cursor .. cursor + @sizeOf(i32)], &std.mem.toBytes(std.mem.nativeToLittle(i32, self.parts)));
        //cursor += @sizeOf(i32);
        //cursor += base.strEncode(self.name, buffer[cursor..]);
        //return cursor;
    }
};

test {
    const allocator = std.testing.allocator;
    var inputFileBig = InputFileBig{
        .id = 123,
        .parts = 456,
        .name = "test",
    };

    const tl = TL.init(&inputFileBig);

    const size = tl.encodedSize();

    const data = try allocator.alloc(u8, size);
    defer allocator.free(data);

    const written = tl.encode(data);

    try std.testing.expectEqual(size, written);
}
