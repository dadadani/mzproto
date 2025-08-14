//   Copyright (c) 2025 Daniele Cortesi <https://github.com/dadadani>
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

const xev = @import("xev").Dynamic;
const std = @import("std");

const tl = @import("lib/tl/api.zig");

const Abridged = @import("lib/network/abridged.zig").Abridged;
const NetworkDataProvider = @import("lib/network/network_data_provider.zig");
const TransportProvider = @import("lib/network/transport_provider.zig");

const ConnectionInfo = @import("lib/network/transport_provider.zig").ConnectionInfo;
const AuthKey = @import("lib/proto/auth_key.zig");

var ge = std.heap.GeneralPurposeAllocator(.{}){};
var loop: xev.Loop = undefined;
var tcp: xev.TCP = undefined;

var authGen: AuthKey.AuthGen = undefined;
const allocoso = ge.allocator();
var connection = struct { queue: xev.WriteQueue = undefined, completion: xev.Completion = undefined, transport: Abridged = Abridged{
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
    //std.log.info("incoming Data: {d}", .{b.slice[0..size]});
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
    writeRequest: xev.WriteRequest = undefined,
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

    _ = size;
    _ = b;

    //std.log.info("Data written: {x}", .{std.fmt.fmtSliceHexLower(b.slice[0..size])});

    return .disarm;
}

fn ontTcpDataToSend(data: ?[]const u8, user_data: ?*const anyopaque) void {
    _ = user_data;

    if (data) |d| {
        //std.log.info("Data to send: {d}", .{d});

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

var timer: std.time.Timer = undefined;

fn GeneratedKey(ptr: *const anyopaque, res: AuthKey.GenError!AuthKey.GeneratedAuthKey) void {
    _ = ptr;
    _ = res catch |err| {
        std.log.err("Failed to generate key: {}", .{err});
        return;
    };
    std.log.info("Generated key: took {d} ms\n", .{timer.read() / std.time.ns_per_ms});
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
    timer = std.time.Timer.start() catch {
        @panic("Failed to start timer");
    };
    authGen.start();

    return .disarm;
}

pub fn main() !void {
    std.debug.print("sizeof: {}", .{@sizeOf(tl.TL)});
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

const XevNetworkDataProvider = struct {
    tcp: ?xev.TCP,
    loop: *xev.Loop,
    networkDataProvider: ?NetworkDataProvider.NetworkDataProvider,
    completion: xev.Completion,

    fn xevConnected(
        self: ?*@This(),
        l: *xev.Loop,
        c: *xev.Completion,
        s: xev.TCP,
        r: xev.ConnectError!void,
    ) xev.CallbackAction {
        _ = l;
        _ = c;
        _ = s;

        r catch {
            self.networkDataProvider.sendEvent(.ConnectError);
            return .disarm;
        };

        self.networkDataProvider.sendEvent(.Connected);

        return .disarm;
    }

    fn xevClosed(
        self: ?*@This(),
        l: *xev.Loop,
        c: *xev.Completion,
        s: xev.TCP,
        r: xev.CloseError!void,
    ) xev.CallbackAction {
        _ = l;
        _ = c;
        _ = s;

        r catch {
            unreachable;
        };

        self.networkDataProvider.sendEvent(.Disconnected);

        return .disarm;
    }

    fn sendData(data: ?[]const u8, ptr: ?*const anyopaque) void {
        _ = ptr;
        _ = data;
    }

    fn connectedCb(ud: ?*XevNetworkDataProvider, l: *xev.Loop, c: *xev.Completion, s: xev.TCP, r: xev.ConnectError!void) xev.CallbackAction {
        if (ud == null) {
            return .disarm;
        }
        _ = l;
        _ = c;
        _ = s;

        r catch {
            ud.networkDataProvider.sendEvent(.ConnectError);
            return .disarm;
        };

        return .disarm;
    }

    fn recvEvent(event: TransportProvider.TransportEvent, ptr: ?*const anyopaque) void {
        if (ptr == null) {
            return;
        }
        const self: *XevNetworkDataProvider = @ptrCast(@alignCast(ptr.?));
        switch (event) {
            .Connect => {
                if (tcp != null) {
                    return;
                }
                const info = self.networkDataProvider.getConnectionDetails();
                self.tcp = try xev.TCP.init(info.address) catch {
                    self.networkDataProvider.sendEvent(.ConnectError);
                    return;
                };

                self.tcp.?.connect(
                    self.loop,
                    &self.completion,
                    info.address,
                    XevNetworkDataProvider,
                    self,
                );
            },

            .Disconnect => {
                if (tcp == null) {
                    return;
                }

                self.tcp.?.close(self.loop, self.completion, XevNetworkDataProvider, self, xevClosed);
            },
        }
    }

    pub fn init(allocator: std.mem.Allocator, lp: *xev.Loop, ndp: NetworkDataProvider.NetworkDataProvider) !*XevNetworkDataProvider {
        const result = try allocator.create(XevNetworkDataProvider);
        errdefer allocator.destroy(result);

        result.* = .{
            .tcp = null,
            .loop = lp,
            .networkDataProvider = ndp,
        };

        result.networkDataProvider.setUserData(result);
        result.networkDataProvider.setRecvEventCallback(recvEvent);
        result.networkDataProvider.setSendCallback(sendData);

        return result;
    }

    pub fn deinit(self: *XevNetworkDataProvider, allocator: std.mem.Allocator) void {
        allocator.destroy(self);
    }
};
