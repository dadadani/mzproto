const std = @import("std");
const Error = @import("../transport.zig").Error;

const Stream = @This();

stream: std.Io.net.Stream = undefined,

writer: std.Io.net.Stream.Writer = undefined,
reader: std.Io.net.Stream.Reader = undefined,

pub const Config = union(enum) {
    ip: struct {
        address: std.Io.net.IpAddress,
        options: std.Io.net.IpAddress.ConnectOptions,
    },
};

pub fn init(io: std.Io, config: Config, read_buf: []u8, write_buf: []u8) !Stream {
    switch (config) {
        .ip => |x| {
            var self = Stream{};
            self.stream = try x.address.connect(io, x.options);
            self.reader = self.stream.reader(io, read_buf);
            self.writer = self.stream.writer(io, write_buf);
            return self;
        },
    }
}

pub fn recvLen(self: *Stream, io: std.Io) !usize {
    _ = self;
    _ = io;

    // we don't have a way to know how many bytes we need to read here...
    @panic("unsupported");
}

pub fn recv(self: *Stream, _: std.Io, buf: []u8) !usize {
    try self.reader.interface.readSliceAll(buf);
    return buf.len;
}

pub fn write(self: *Stream, _: std.Io, buf: []const u8) !void {
    try self.writer.interface.writeAll(buf);
    try self.writer.interface.flush();
}

pub fn writeVec(self: *Stream, _: std.Io, buf: [][]const u8) !void {
    try self.writer.interface.writeVecAll(buf);
    try self.writer.interface.flush();
}

pub fn deinit(self: *Stream, io: std.Io) void {
    self.stream.close(io);
}
