const std = @import("std");
const Transport = @import("../transport.zig").Transport;

const Abridged = @This();

const Mode = enum { SingleByte, FullBytes, Payload };

transport: *Transport,

mode: Mode = .SingleByte,
len: usize = 0,

mutex_read: std.Io.Mutex = .init,
mutex_write: std.Io.Mutex = .init,

pub fn init(transport: *Transport, io: std.Io) !Abridged {
    var self = Abridged{
        .transport = transport,
    };
    try self.transport.write(io, &.{0xef});
    //  try self.writer.flush();
    return self;
}

pub fn recvLen(self: *Abridged, io: std.Io) Transport.Error!usize {
    try self.mutex_read.lock(io);
    defer self.mutex_read.unlock(io);

    switch (self.mode) {
        .SingleByte => {
            var lenB: [1]u8 = undefined;
            _ = try self.transport.recv(io, &lenB);
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
        _ = try self.transport.recv(io, len[0..3]);
        self.len = @as(usize, std.mem.readInt(u32, &len, .little)) * 4;
        self.mode = .Payload;
    }

    return self.len;
}

pub fn recv(self: *Abridged, io: std.Io, buf: []u8) Transport.Error!usize {
    try self.mutex_read.lock(io);
    defer self.mutex_read.unlock(io);

    switch (self.mode) {
        .SingleByte, .FullBytes => {
            return Transport.Error.LengthNotRead;
        },
        .Payload => {
            const len_dest = @min(buf.len, self.len);
            _ = try self.transport.recv(io, buf[0..len_dest]);
            self.len -= len_dest;
            if (self.len == 0) {
                self.mode = .SingleByte;
            }
            return len_dest;
        },
    }
}

pub fn write(self: *Abridged, io: std.Io, buf: []const u8) Transport.Error!void {
    try self.mutex_write.lock(io);
    defer self.mutex_write.unlock(io);

    const len = @as(u8, @intCast(buf.len / 4));

    if (len < 0x7F) {
        const l = [_]u8{len};
        var vec = [_][]const u8{ &l, buf };
        _ = try self.transport.writeVec(io, &vec);
        // try self.transport.flush();
    } else {
        var buf_dest: [4]u8 = undefined;
        std.mem.writeInt(u32, &buf_dest, @as(u32, len), .little);
        var v = [_][]const u8{ &.{0x7F}, buf_dest[0..3], buf };
        _ = try self.transport.writeVec(io, &v);
        //  try self.writer.flush();
    }
}

pub fn writeVec(self: *Abridged, io: std.Io, buf: [][]const u8) Transport.Error!void {
    try self.mutex_write.lock(io);
    defer self.mutex_write.unlock(io);

    var len: usize = 0;
    for (buf) |i| {
        len += i.len;
    }
    len = len / 4;

    if (len < 0x7F) {
        try self.transport.write(io, &.{@intCast(len)});
        _ = try self.transport.writeVec(io, buf);
        // try self.writer.flush();
    } else {
        var buf_dest: [4]u8 = undefined;
        std.mem.writeInt(u32, &buf_dest, @as(u32, @intCast(len)), .little);
        //  try self.writer.writeByte(0x7F);
        // _ = try self.writer.write(buf_dest[0..3]);
        _ = try self.transport.write(io, &.{ 0x7F, buf_dest[0], buf_dest[1], buf_dest[2] });

        _ = try self.transport.writeVec(io, buf);
        //    try self.writer.flush();
    }
}

pub fn deinit(self: *Abridged, io: std.Io) void {
    self.transport.deinit(io);
}
