const std = @import("std");
const Error = @import("../transport.zig").Error;

const Abridged = @This();

const Mode = enum { SingleByte, FullBytes, Payload };

writer: *std.Io.Writer,
reader: *std.Io.Reader,

mode: Mode = .SingleByte,
len: usize = 0,

mutex_read: std.Io.Mutex = .init,
mutex_write: std.Io.Mutex = .init,

pub fn init(writer: *std.Io.Writer, reader: *std.Io.Reader) !Abridged {
    var self = Abridged{
        .reader = reader,
        .writer = writer,
    };
    try self.writer.writeByte(0xef);
    try self.writer.flush();
    return self;
}

pub fn recvLen(self: *Abridged, io: std.Io) !usize {
    try self.mutex_read.lock(io);
    defer self.mutex_read.unlock(io);

    switch (self.mode) {
        .SingleByte => {
            var lenB: [1]u8 = undefined;

            try self.reader.readSliceAll(&lenB);
            if (lenB[0] >= 127) {
                self.mode = .FullBytes;
            } else {
                self.mode = .Payload;
                self.len = (@as(usize, lenB[0]) * 4);
            }
        },
        .FullBytes => {},
        .Payload => {},
    }

    if (self.mode == .FullBytes) {
        var len: [4]u8 = .{0} ** 4;
        try self.reader.readSliceAll(len[0..3]);
        self.len = @as(usize, std.mem.readInt(u32, &len, .little)) * 4;
        self.mode = .Payload;
    }

    return self.len;
}

pub fn recv(self: *Abridged, io: std.Io, buf: []u8) !usize {
    try self.mutex_read.lock(io);
    defer self.mutex_read.unlock(io);

    switch (self.mode) {
        .SingleByte, .FullBytes => {
            return Error.LengthNotRead;
        },
        .Payload => {
            const len_dest = @min(buf.len, self.len);
            try self.reader.readSliceAll(buf[0..len_dest]);
            self.len -= len_dest;
            if (self.len == 0) {
                self.mode = .SingleByte;
            }
            return len_dest;
        },
    }
}

pub fn write(self: *Abridged, io: std.Io, buf: []const u8) !void {
    try self.mutex_write.lock(io);
    defer self.mutex_write.unlock(io);

    const len = @as(u8, @intCast(buf.len / 4));

    if (len < 0x7F) {
        _ = try self.writer.writeVec(&.{ &.{len}, buf });
        try self.writer.flush();
    } else {
        var buf_dest: [4]u8 = undefined;
        std.mem.writeInt(u32, &buf_dest, @as(u32, len), .little);
        _ = try self.writer.writeVec(&.{ &.{0x7F}, buf_dest[0..3], buf });
        try self.writer.flush();
    }
}

pub fn writeVec(self: *Abridged, io: std.Io, buf: []const []const u8) !void {
    try self.mutex_write.lock(io);
    defer self.mutex_write.unlock(io);

    var len: usize = 0;
    for (buf) |i| {
        len += i.len;
    }
    len = len / 4;

    if (len < 0x7F) {
        try self.writer.writeByte(@intCast(len));
        _ = try self.writer.writeVec(buf);
        try self.writer.flush();
    } else {
        var buf_dest: [4]u8 = undefined;
        std.mem.writeInt(u32, &buf_dest, @as(u32, @intCast(len)), .little);
        try self.writer.writeByte(0x7F);
        _ = try self.writer.write(buf_dest[0..3]);
        _ = try self.writer.writeVec(buf);
        try self.writer.flush();
    }
}

