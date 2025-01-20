const xev = @import("xev");
const std = @import("std");

const tl = @import("lib/tl/api.zig");

const Abridged = @import("lib/network/abridged.zig").Abridged;
const NetworkDataProvider = @import("lib/network/network_data_provider.zig");
const TransportProvider = @import("lib/network/transport_provider.zig");

const AuthKey = @import("lib/proto//auth_key.zig");

var ge = std.heap.GeneralPurposeAllocator(.{}){};
var loop: xev.Loop = undefined;
var tcp: xev.TCP = undefined;

var authGen: AuthKey.AuthGen = undefined;
const allocoso = ge.allocator();
var connection = struct { queue: xev.TCP.WriteQueue = undefined, completion: xev.Completion = undefined, transport: Abridged = Abridged{
    .allocator = ge.allocator(),
}, readBuf: []u8 = &[0]u8{} }{};

fn onTcpData(
    ud: ?*@TypeOf(connection),
    l: *xev.Loop,
    c: *xev.Completion,
    s: xev.TCP,
    b: xev.ReadBuffer,
    r: xev.ReadError!usize,
) xev.CallbackAction {
    _ = l;
    _ = c;
    _ = ud;

    const size = r catch |err| {
        connection.transport.networkProvider().sendEvent(.Disconnected);
        std.log.err("Failed to read: {}", .{err});
        return .disarm;
    };
    std.log.info("incoming Data: {d}", .{b.slice[0..size]});
    connection.transport.networkProvider().recv(b.slice[0..size]) catch |err| {
        std.log.err("Failed to process data: {}", .{err});
        return .disarm;
    };

    read(s) catch |err| {
        std.log.err("Failed to read: {}", .{err});
        return .disarm;
    };

    return .disarm;
}

const WriteSession = struct {
    completion: xev.Completion = undefined,
    data: []u8 = undefined,
    writeRequest: xev.TCP.WriteRequest = undefined,
};

fn onDataWritten(
    ud: ?*WriteSession,
    l: *xev.Loop,
    c: *xev.Completion,
    s: xev.TCP,
    b: xev.WriteBuffer,
    r: xev.WriteError!usize,
) xev.CallbackAction {
    _ = l;
    _ = c;
    _ = s;

    defer {
        ge.allocator().free(ud.?.*.data);
        ge.allocator().destroy(ud.?);
    }

    const size = r catch |err| {
        std.log.err("Failed to write: {}", .{err});
        return .disarm;
    };

    std.log.info("Data written: {x}", .{std.fmt.fmtSliceHexLower(b.slice[0..size])});

    return .disarm;
}

fn ontTcpDataToSend(data: ?[]const u8, user_data: ?*const anyopaque) void {
    _ = user_data;

    if (data) |d| {
        std.log.info("Data to send: {d}", .{d});

        const write = ge.allocator().create(WriteSession) catch |err| {
            std.log.err("Failed to create write session: {}", .{err});
            return;
        };

        write.data = ge.allocator().dupe(u8, d) catch |err| {
            std.log.err("Failed to allocate buffer: {}", .{err});
            return;
        };

        tcp.queueWrite(&loop, &connection.queue, &write.writeRequest, .{ .slice = write.data }, WriteSession, write, onDataWritten);
        //tcp.write(&loop, &write.completion, .{ .slice = write.data }, WriteSession, write, onDataWritten);
    } else {
        std.log.err("Data is null, we should close the connection here", .{});
        //tcp.cl
    }
}

fn read(conn: xev.TCP) !void {
    if (connection.readBuf.len == 0) {
        connection.readBuf = try ge.allocator().alloc(u8, connection.transport.networkProvider().suggestedRecvSize());
    } else {
        connection.readBuf = try ge.allocator().realloc(connection.readBuf, connection.transport.networkProvider().suggestedRecvSize());
    }

    conn.read(&loop, &connection.completion, xev.ReadBuffer{ .slice = connection.readBuf }, @TypeOf(connection), &connection, onTcpData);
}

fn GeneratedKey(ptr: *const anyopaque, res: AuthKey.GenError!AuthKey.GeneratedAuthKey) void {
    _ = ptr;
    _ = res catch |err| {
        std.log.err("Failed to generate key: {}", .{err});
        return;
    };
    std.log.info("Generated key:.....\n", .{});
}

fn connectedCb(ud: ?*void, l: *xev.Loop, c: *xev.Completion, s: xev.TCP, r: xev.ConnectError!void) xev.CallbackAction {
    _ = ud;
    _ = l;
    _ = c;
    r catch |err| {
        std.log.err("Failed to connect: {}", .{err});
        return .disarm;
    };
    connection.transport.networkProvider().setSendCallback(ontTcpDataToSend);
    connection.transport.networkProvider().sendEvent(.Connected);
    std.log.info("Connected!", .{});

    read(s) catch |err| {
        std.log.err("Failed to read: {}", .{err});
        return .disarm;
    };

    authGen = AuthKey.AuthGen{ .allocator = allocoso, .connection = connection.transport.transportProvider(), .callback = GeneratedKey, .user_data = &connection, .dcId = 2, .testMode = true, .media = false };
    authGen.start();

    return .disarm;
}

pub fn main() !void {
    defer {
        switch (ge.deinit()) {
            std.heap.Check.leak => std.log.err("Memory leak detected", .{}),
            std.heap.Check.ok => {},
        }
    }

    loop = try xev.Loop.init(.{});
    defer loop.deinit();

    const address = try std.net.Ip4Address.parse("149.154.167.40", 443);
    tcp = try xev.TCP.init(.{ .in = address });
    tcp.connect(&loop, &connection.completion, std.net.Address{ .in = address }, void, null, connectedCb);

    try loop.run(.until_done);
}
