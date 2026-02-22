const Abridged = @import("transport/abridged.zig");

const std = @import("std");

pub const Error = error{ LengthNotRead, LengthAlreadyConsumed };

pub const Transports = std.meta.Tag(TransportUnion);

const TransportUnion = union(enum) {
    Abridged: Abridged,
};

pub const Transport = struct {
    transport: TransportUnion,

    pub fn init(transport_mode: Transports, writer: *std.Io.Writer, reader: *std.Io.Reader) !Transport {
        switch (transport_mode) {
            .Abridged => {
                return .{ .transport = .{ .Abridged = try Abridged.init(writer, reader) } };
            },
        }
    }

    pub fn recvLen(self: *Transport, io: std.Io) !usize {
        return switch (self.transport) {
            inline else => |*x| x.recvLen(io),
        };
    }

    pub fn recv(self: *Transport, io: std.Io, buf: []u8) !usize {
        return switch (self.transport) {
            inline else => |*x| x.recv(io, buf),
        };
    }

    pub fn write(self: *Transport, io: std.Io, buf: []const u8) !void {
        return switch (self.transport) {
            inline else => |*x| x.write(io, buf),
        };
    }

    pub fn writeVec(self: *Transport, io: std.Io, buf: []const []const u8) !void {
        return switch (self.transport) {
            inline else => |*x| x.writeVec(io, buf),
        };
    }
};
