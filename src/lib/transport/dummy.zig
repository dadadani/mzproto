const std = @import("std");
const Error = @import("../transport.zig").Transport.Error;

const Dummy = @This();

client_recv_queue: std.Io.Queue([]u8),
server_recv_queue: std.Io.Queue([]u8),

allocator: std.mem.Allocator,

mutex: std.Io.Mutex = .init,
client_recv_buf: ?[]u8,
buf_len_remaining: usize = 0,

pub fn init(allocator: std.mem.Allocator, buffer_client: [][]u8, buffer_server: [][]u8) !Dummy {
    return .{
        .client_recv_queue = .init(buffer_client),
        .server_recv_queue = .init(buffer_server),
        .allocator = allocator,
        .client_recv_buf = null,
    };
}

pub fn serverRecv(self: *Dummy, io: std.Io) ![]u8 {
    return self.server_recv_queue.getOne(io);
}

pub fn serverWrite(self: *Dummy, io: std.Io, buf: []const u8) !void {
    const dest = try self.allocator.dupe(u8, buf);
    errdefer self.allocator.free(dest);

    try self.client_recv_queue.putOne(io, dest);
}

pub fn recvLen(self: *Dummy, io: std.Io) Error!usize {
    try self.mutex.lock(io);

    defer {
        self.mutex.unlock(io);
    }
    if (self.client_recv_buf) |_| {
        return self.buf_len_remaining;
    }

    const buf = self.client_recv_queue.getOne(io) catch |err| {
        if (err == std.Io.Cancelable.Canceled) {
            return std.Io.Cancelable.Canceled;
        }

        return Error.WriteFailed;
    };

    try std.Io.checkCancel(io);

    self.client_recv_buf = buf;
    self.buf_len_remaining = buf.len;
    return self.buf_len_remaining;
}

pub fn recv(self: *Dummy, io: std.Io, buf: []u8) Error!usize {

    try self.mutex.lock(io);

    defer {
        self.mutex.unlock(io);
    }

    if (self.client_recv_buf) |recv_buf| {
        if (buf.len == 0) {
            return 0;
        }
        const len_dest = @min(buf.len, self.buf_len_remaining);
        @memcpy(buf[0..len_dest], recv_buf[recv_buf.len - self.buf_len_remaining ..][0..len_dest]);
        self.buf_len_remaining -= len_dest;
        if (self.buf_len_remaining == 0) {
            self.allocator.free(recv_buf);
            self.client_recv_buf = null;
        }
        return len_dest;
    } else {
        return Error.LengthNotRead;
    }
}

pub fn write(self: *Dummy, io: std.Io, buf: []const u8) Error!void {
    const dest = self.allocator.dupe(u8, buf) catch {
        return Error.WriteFailed;
    };
    errdefer self.allocator.free(dest);

    self.server_recv_queue.putOne(io, dest) catch |err| {
        if (err == std.Io.Cancelable.Canceled) {
            return std.Io.Cancelable.Canceled;
        }

        return Error.WriteFailed;
    };
}

pub fn writeVec(self: *Dummy, io: std.Io, buf: []const []const u8) Error!void {
    var len: usize = 0;
    for (buf) |sbuf| {
        len += sbuf.len;
    }

    const dest = self.allocator.alloc(u8, len) catch {
        return Error.WriteFailed;
    };
    errdefer self.allocator.free(dest);

    len = 0;
    for (buf) |sbuf| {
        @memcpy(dest[len .. len + sbuf.len], sbuf);
        len += sbuf.len;
    }

    self.server_recv_queue.putOne(io, dest) catch |err| {
        if (err == std.Io.Cancelable.Canceled) {
            return std.Io.Cancelable.Canceled;
        }

        return Error.WriteFailed;
    };
}

pub fn deinit(self: *Dummy, io: std.Io) void {
    self.mutex.lockUncancelable(io);
    self.client_recv_queue.close(io);
    self.server_recv_queue.close(io);

    while (true) {
        const get = self.client_recv_queue.getOneUncancelable(io) catch {
            break;
        };
        self.allocator.free(get);
    }

    while (true) {
        const get = self.server_recv_queue.getOneUncancelable(io) catch {
            break;
        };
        self.allocator.free(get);
    }

    if (self.client_recv_buf) |buf| {
        self.allocator.free(buf);
        self.buf_len_remaining = 0;
    }
}

test "server writes to client" {
    const dummyTransport = @import("../transport_connector.zig").dummyTransport;
    const io = std.testing.io;
    const holder, const dummy = try dummyTransport(std.testing.allocator);
    defer holder.deinit(io);
    {
        const first_half = "dsaodjsaodjsaojcoiancd";
        const second_half = "dsaijdsaijdoj34j2kcdapkcsa-asdsadpsa]";
        const text1 = first_half ++ second_half;
        try dummy.serverWrite(io, text1);

        const len = try holder.transport.recvLen(io);

        try std.testing.expectEqual(text1.len, len);

        var buf: [256]u8 = undefined;

        const read = try holder.transport.recv(io, buf[0..first_half.len]);
        try std.testing.expectEqual(first_half.len, read);
        try std.testing.expectEqualStrings(first_half, buf[0..first_half.len]);

        const read2 = try holder.transport.recv(io, buf[first_half.len..][0..second_half.len]);
        try std.testing.expectEqual(second_half.len, read2);
        try std.testing.expectEqualStrings(text1, buf[0..text1.len]);
    }
}

test "client writes to client" {
    const dummyTransport = @import("../transport_connector.zig").dummyTransport;
    const io = std.testing.io;
    const holder, const dummy = try dummyTransport(std.testing.allocator);
    defer holder.deinit(io);
    {
        const text1 = "jrdsadsa43243229jfodunfdaun923428ur02e-dkajisajd";

        try holder.transport.write(io, text1);

        const inc = try dummy.serverRecv(io);
        defer std.testing.allocator.free(inc);

        try std.testing.expectEqualStrings(text1, inc);
    }
}

test "client writes to client with writeVec" {
    const dummyTransport = @import("../transport_connector.zig").dummyTransport;
    const io = std.testing.io;
    const holder, const dummy = try dummyTransport(std.testing.allocator);
    defer holder.deinit(io);
    {
        const first_half = "dosojidosaji4532ibfasdijasn";
        const second_half = "dsuiadibsacbidcndsciosdi";
        const text1 = first_half ++ second_half;

        var a: [2][]const u8 = undefined;

        a[0] = @ptrCast(first_half);
        a[1] = @ptrCast(second_half);

        try holder.transport.writeVec(io, &a);

        const inc = try dummy.serverRecv(io);
        defer std.testing.allocator.free(inc);

        try std.testing.expectEqualStrings(text1, inc);
    }
}
