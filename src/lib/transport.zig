const std = @import("std");

pub const Transports = std.meta.Tag(TransportUnion);

const TransportUnion = union(enum) {
    TcpAbridged: Transport.TcpAbridged,
};

pub const Transport = struct {
    pub const TcpAbridged = @import("transport/tcp_abridged.zig");

    pub const Error = error{ LengthNotRead, LengthAlreadyConsumed } || std.Io.Writer.Error || std.Io.Reader.Error || std.Io.Cancelable;

    pub const Enum = std.meta.Tag(TransportUnion);

    transport: TransportUnion,

    pub fn recvLen(self: *Transport, io: std.Io) Error!usize {
        return switch (self.transport) {
            inline else => |*x| x.recvLen(io),
        };
    }

    pub fn recv(self: *Transport, io: std.Io, buf: []u8) Error!usize {
        return switch (self.transport) {
            inline else => |*x| x.recv(io, buf),
        };
    }

    pub fn write(self: *Transport, io: std.Io, buf: []const u8) Error!void {
        return switch (self.transport) {
            inline else => |*x| x.write(io, buf),
        };
    }

    pub fn writeVec(self: *Transport, io: std.Io, buf: [][]const u8) Error!void {
        return switch (self.transport) {
            inline else => |*x| x.writeVec(io, buf),
        };
    }

    pub fn deinit(self: *Transport, io: std.Io) void {
        return switch (self.transport) {
            inline else => |*x| x.deinit(io),
        };
    }
};
