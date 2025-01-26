const std = @import("std");

pub const NetworkDataProvider = @import("network_data_provider.zig").NetworkDataProvider;
pub const SendCallbackFn = @import("network_data_provider.zig").SendCallbackFn;
pub const ConnectionEvent = @import("network_data_provider.zig").ConnectionEvent;

pub const TransportProvider = @import("transport_provider.zig").TransportProvider;
pub const RecvDataCallback = @import("transport_provider.zig").RecvDataCallback;
pub const RecvEventCallback = @import("transport_provider.zig").RecvEventCallback;
pub const ConnectionInfo = @import("transport_provider.zig").ConnectionInfo;

pub const TransportEvent = @import("transport_provider.zig").TransportEvent;
pub const TransportRecvEventCallback = @import("network_data_provider.zig").RecvEventCallback;

/// Abridged Protocol
///
/// See https://core.telegram.org/mtproto/mtproto-transports#abridged
pub const Abridged = struct {
    allocator: std.mem.Allocator,
    recvDataCallback: ?*const RecvDataCallback = null,
    recvEventCallback: ?*const RecvEventCallback = null,
    transport_user_data: ?*const anyopaque = null,

    read_status: enum { ReadingLength, ReadingLengthExtended, ReadingBody, Terminated } = .ReadingLength,
    connection_open: bool = false,

    read_buf: []u8 = &[_]u8{},
    read_len_net: usize = 0,

    extended_len_buf: [4]u8 = undefined,
    extended_len_read: u4 = 0,

    net_user_data: ?*const anyopaque = null,
    netSendCallback: ?*const SendCallbackFn = null,

    transportEventCallback: ?*const TransportRecvEventCallback = null,

    connecton_info: ConnectionInfo = undefined,

    pub fn deinit(self: *Abridged) void {
        if (self.read_buf.len > 0) {
            self.allocator.free(self.read_buf);
        }
        if (self.netSendCallback) |func| {
            func(null, self.net_user_data);
        }
        self.read_status = .Terminated;
    }

    pub fn networkProvider(s: *Abridged) NetworkDataProvider {
        const vtable = struct {
            fn netRecv(ptr: *anyopaque, src: []const u8) !void {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                if (src.len == 0) {
                    return;
                }
                switch (self.read_status) {
                    .ReadingLength => {
                        if (src[0] == 0) {
                            return;
                        }
                        if (src[0] >= 0x7F) {
                            self.read_status = .ReadingLengthExtended;
                            self.extended_len_buf[3] = 0;
                            self.extended_len_read = 0;

                            const remaining = src[1..];

                            if (remaining.len > 0) {
                                try @This().netRecv(ptr, remaining);
                            }
                        } else {
                            self.read_buf = try self.allocator.alloc(u8, @as(usize, src[0]) * 4);
                            self.read_status = .ReadingBody;

                            const remaining = src[1..];

                            if (remaining.len > 0) {
                                try @This().netRecv(ptr, remaining);
                            }
                        }
                    },
                    .ReadingLengthExtended => {
                        if (self.extended_len_read < 3) {
                            self.extended_len_buf[self.extended_len_read] = src[0];
                            self.extended_len_read += 1;

                            if (src.len > 1) {
                                try @This().netRecv(ptr, src[1..]);
                            }
                        } else {
                            self.read_buf = try self.allocator.alloc(u8, std.mem.readInt(u32, &self.extended_len_buf, .little) * 4);
                            self.read_status = .ReadingBody;
                            self.extended_len_read = 0;

                            try @This().netRecv(ptr, src);
                        }
                    },
                    .ReadingBody => {
                        const incoming = src[0..@min(src.len, self.read_buf.len - self.read_len_net)];
                        const dest = self.read_buf[self.read_len_net..@min(self.read_len_net + incoming.len, self.read_buf.len)];

                        @memcpy(dest, incoming);

                        self.read_len_net += incoming.len;

                        if (self.read_len_net == self.read_buf.len) {
                            if (self.recvDataCallback) |func| {
                                func(self.read_buf, self.transport_user_data);
                            }
                            self.read_status = .ReadingLength;
                            self.read_len_net = 0;
                            self.allocator.free(self.read_buf);
                            self.read_buf = &[_]u8{};
                        }

                        if (src[incoming.len..].len > 0) {
                            try @This().netRecv(ptr, src[incoming.len..]);
                        }
                    },
                    .Terminated => @panic("Transport has been terminated"),
                }
            }

            fn netSuggestedRecvSize(ptr: *anyopaque) usize {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                switch (self.read_status) {
                    .ReadingLength => return 1,
                    .ReadingLengthExtended => return 4 - (self.extended_len_read),
                    .ReadingBody => return self.read_buf.len - self.read_len_net,
                    .Terminated => @panic("Transport has been terminated"),
                }
            }

            fn netSetUserData(ptr: *anyopaque, user_data: ?*const anyopaque) void {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                self.net_user_data = user_data;
            }

            fn netSetSendCallback(ptr: *anyopaque, send_callback: *const SendCallbackFn) void {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                self.netSendCallback = send_callback;
            }

            fn sendEvent(ptr: *anyopaque, event: ConnectionEvent) void {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                defer {
                    if (self.recvEventCallback) |recv| {
                        recv(event, self.transport_user_data);
                    }
                }
                switch (event) {
                    .Connected => {
                        if (self.netSendCallback == null or self.connection_open) {
                            return;
                        }
                        self.connection_open = true;
                        if (self.netSendCallback) |send| {
                            send(&[1]u8{0xef}, self.net_user_data);
                        }
                    },
                    .Disconnected => {
                        self.connection_open = false;
                    },
                }
            }

            fn setRecvEventCallback(ptr: *anyopaque, func: *const TransportRecvEventCallback) void {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                self.transportEventCallback = func;
            }

            fn getConnectionDetails(ptr: *anyopaque) ConnectionInfo {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                return self.connecton_info;
            }
        };

        return NetworkDataProvider{ .ptr = @ptrCast(s), .vtable = .{
            .recvFn = &vtable.netRecv,
            .suggestedRecvSizeFn = &vtable.netSuggestedRecvSize,
            .setUserDataFn = &vtable.netSetUserData,
            .setSendCallbackFn = &vtable.netSetSendCallback,
            .sendEventFn = &vtable.sendEvent,
            .getConnectionDetails = &vtable.getConnectionDetails,
            .setRecvEventCallback = &vtable.setRecvEventCallback,
        } };
    }

    pub fn transportProvider(s: *Abridged) TransportProvider {
        const vtable = struct {
            pub fn sendData(ptr: *anyopaque, data: []const u8) void {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                if (self.netSendCallback) |send| {
                    const len = @as(u8, @intCast(data.len / 4));

                    // If the length divided by 4 is less than 0x7F, we send it as a single byte,
                    // otherwise, we send 0x7F followed by the length as a 3-byte little-endian integer.

                    if (len < 0x7F) {
                        send(&[1]u8{len}, self.transport_user_data);
                        send(data, self.transport_user_data);
                    } else {
                        var buf: [5]u8 = undefined;
                        buf[0] = 0x7F;
                        std.mem.writeInt(u32, buf[1..], @as(u32, len), .little);
                        send(&buf, self.transport_user_data);
                        send(data, self.transport_user_data);
                    }
                }
            }

            pub fn setRecvDataCallback(ptr: *anyopaque, func: *const RecvDataCallback) void {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                self.recvDataCallback = func;
            }

            pub fn setRecvEventCallback(ptr: *anyopaque, func: *const RecvEventCallback) void {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                self.recvEventCallback = func;
            }

            pub fn setUserData(ptr: *anyopaque, user_data: ?*const anyopaque) void {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                self.transport_user_data = user_data;
            }

            pub fn setConnectionInfo(ptr: *anyopaque, info: ConnectionInfo) void {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                self.connecton_info = info;
            }

            pub fn getConnectionDetails(ptr: *anyopaque) ConnectionInfo {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                return self.connecton_info;
            }

            pub fn sendEvent(ptr: *anyopaque, event: TransportEvent) void {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                if (self.transportEventCallback) |send| {
                    send(event, self.transport_user_data);
                }
            }
        };

        return TransportProvider{ .ptr = @ptrCast(s), .vtable = .{
            .sendData = &vtable.sendData,
            .setRecvDataCallback = &vtable.setRecvDataCallback,
            .setRecvEventCallback = &vtable.setRecvEventCallback,
            .setUserData = &vtable.setUserData,
            .setConnectionInfo = &vtable.setConnectionInfo,
            .sendEvent = &vtable.sendEvent,
        } };
    }
};

pub fn incomingData(data: []u8, user_data: *const anyopaque) void {
    _ = user_data;
    std.debug.print("{d}\n", .{data});
    std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4, 5, 6, 7, 8 }, data) catch |x| {
        std.debug.panic("{}", .{x});
    };
}

pub fn toSendData(data: ?[]const u8, user_data: ?*const anyopaque) void {
    _ = user_data;
    if (data == null) {
        return;
    }
}

pub fn TrransportRecvData(data: []const u8, user_data: ?*const anyopaque) void {
    _ = user_data;
    _ = data;
}

test "test read" {
    const allocator = std.testing.allocator;

    var tcp_abriged = Abridged{
        .allocator = allocator,
    };
    defer tcp_abriged.deinit();

    const transport = tcp_abriged.transportProvider();
    transport.setRecvDataCallback(TrransportRecvData);

    const net_provider = tcp_abriged.networkProvider();
    net_provider.setSendCallback(toSendData);
    net_provider.sendEvent(.Connected);

    try net_provider.recv(&[_]u8{ 2, 1 });

    try net_provider.recv(&[_]u8{ 2, 3, 4, 5, 6, 7, 8, 2, 1, 2 });

    try net_provider.recv(&[_]u8{ 3, 4, 5, 6, 7, 8 });

    try net_provider.recv(&[_]u8{ 0x7F, 0x02, 0x00, 0x00, 1, 2, 3, 4, 5, 6, 7, 8 });

    //tcp_abriged.
}
