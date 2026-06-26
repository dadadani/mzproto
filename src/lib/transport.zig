const std = @import("std");

pub const Transports = std.meta.Tag(TransportUnion);

const TransportUnion = union(enum) {
    StreamAbridged: Transport.StreamAbridged,
    Dummy: if (@import("builtin").is_test) Transport.Dummy else struct {},
};

pub const Transport = struct {
    pub const StreamAbridged = @import("transport/stream_abridged.zig");

    pub const Dummy = @import("transport/dummy.zig");

    pub const Error = error{ LengthNotRead, LengthAlreadyConsumed } || std.Io.Writer.Error || std.Io.Reader.Error || std.Io.Cancelable;

    pub const Enum = std.meta.Tag(TransportUnion);

    transport: TransportUnion,

    pub fn recvLen(self: *Transport, io: std.Io) Error!usize {
        return switch (self.transport) {
            .Dummy => |*x| if (@import("builtin").is_test) x.recvLen(io) else unreachable,
            inline else => |*x| x.recvLen(io),
        };
    }

    pub fn recv(self: *Transport, io: std.Io, buf: []u8) Error!usize {
        return switch (self.transport) {
            .Dummy => |*x| if (@import("builtin").is_test) x.recv(io, buf) else unreachable,
            inline else => |*x| x.recv(io, buf),
        };
    }

    pub fn write(self: *Transport, io: std.Io, buf: []const u8) Error!void {
        return switch (self.transport) {
            .Dummy => |*x| if (@import("builtin").is_test) x.write(io, buf) else unreachable,
            inline else => |*x| x.write(io, buf),
        };
    }

    pub fn writeVec(self: *Transport, io: std.Io, buf: []const []const u8) Error!void {
        return switch (self.transport) {
            .Dummy => |*x| if (@import("builtin").is_test) x.writeVec(io, buf) else unreachable,
            inline else => |*x| x.writeVec(io, buf),
        };
    }

    pub fn deinit(self: *Transport, io: std.Io) void {
        return switch (self.transport) {
            .Dummy => |*x| if (@import("builtin").is_test) x.deinit(io) else unreachable,
            inline else => |*x| x.deinit(io),
        };
    }
};
