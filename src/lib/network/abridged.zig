//! MTProto "abridged" framing transport.
//! - Outbound framing: send 0xEF once on first Connect; then for each message:
//!   - if (len/4) < 0x7F: emit 1 byte length (len/4), followed by body
//!   - else: emit 0x7F + 3-byte little-endian (len/4), followed by body
//! - Inbound parsing: state machine reading length (short or extended) then body.
//! This layer sits above a byte-stream transport (e.g. TCP) and exposes its own
//! TransportReader/Writer. It requires a lower-level writer to send frames.

const transport = @import("transport.zig");
const std = @import("std");

/// Implements abridged framing with a small receive state machine.
const Abridged = struct {
    allocator: std.mem.Allocator,

    read_status: enum { ReadingLength, ReadingLengthExtended, ReadingBody, Terminated } = .ReadingLength,
    connection_status: enum { Uninitialized, Connected, Connecting, Terminating } = .Connecting,

    read_buf: []u8 = &[_]u8{},
    read_len_net: usize = 0,

    extended_len_buf: [4]u8 = undefined,
    extended_len_read: u4 = 0,

    reader: ?transport.TransportReader = null,
    writer: ?transport.TransportWriter = null,

    terminate_ctx: ?*anyopaque = null,
    terminate_cb: ?*const (fn (self: ?*anyopaque) void) = null,

    pub fn transportControl(self_local: *Abridged) transport.TransportControl {
        const control = struct {
            fn setWriter(self_ptr: *anyopaque, writer: transport.TransportWriter) void {
                const self: *Abridged = @ptrCast(@alignCast(self_ptr));
                self.writer = writer;
            }

            fn setReader(self_ptr: *anyopaque, reader: transport.TransportReader) void {
                const self: *Abridged = @ptrCast(@alignCast(self_ptr));
                self.reader = reader;
            }

            /// Begin graceful teardown. If already torn down, no-ops.
            fn deinit(self_ptr: *anyopaque, ctx: ?*anyopaque, cb: *const (fn (self: ?*anyopaque) void)) void {
                const self: *Abridged = @ptrCast(@alignCast(self_ptr));
                if (self.connection_status == .Uninitialized or (self.connection_status == .Terminating and self.read_status == .Terminated)) {
                    return;
                }

                if (self.writer) |writer| {
                    writer.control(.{ .Disconnect = .{} });
                } else {
                    self.allocator.destroy(self);
                    cb(ctx);
                    return;
                }

                if (self.read_buf.len > 0) {
                    self.allocator.free(self.read_buf);
                }

                self.terminate_ctx = ctx;
                self.terminate_cb = cb;
            }
        };

        return .{ .vtable = .{
            .ctx = self_local,
            .deinit = control.deinit,
            .setReader = control.setReader,
            .setWriter = control.setWriter,
        } };
    }

    /// Writer exposed to upper layers; frames data per abridged rules and
    /// forwards it to the lower layer writer.
    pub fn transportWriter(self_local: *Abridged) transport.TransportWriter {
        const writer = struct {
            fn send(self_ptr: *anyopaque, data: []const u8) transport.Error!void {
                const self: *Abridged = @ptrCast(@alignCast(self_ptr));
                if (self.connection_status != .Connected) {
                    return transport.Error.ConnectionClosed;
                }

                if (self.writer) |writer| {
                    const len = @as(u8, @intCast(data.len / 4));

                    // If the length divided by 4 is less than 0x7F, we send it as a single byte,
                    // otherwise, we send 0x7F followed by the length as a 3-byte little-endian integer.
                    if (len < 0x7F) {
                        try writer.send(&[1]u8{len});
                        try writer.send(data);
                    } else {
                        var buf: [5]u8 = undefined;
                        buf[0] = 0x7F;
                        std.mem.writeInt(u32, buf[1..], @as(u32, len), .little);
                        try writer.send(&buf);
                        try writer.send(data);
                    }
                } else {
                    return transport.Error.ConnectionClosed;
                }
            }

            fn control(self_ptr: *anyopaque, ctrl: transport.Control) void {
                const self: *Abridged = @ptrCast(@alignCast(self_ptr));
                _ = ctrl;
                _ = self;
            }
        };

        return .{ .vtable = .{
            .control = writer.control,
            .ctx = self_local,
            .send = writer.send,
        } };
    }

    /// Reader exposed to lower layers; parses stream into framed messages.
    pub fn transportReader(self_local: *Abridged) transport.TransportReader {
        const reader = struct {
            /// Handle connection lifecycle signals from the lower layer.
            fn control(self_ptr: *anyopaque, ctrl: transport.Control) void {
                const self: *Abridged = @ptrCast(@alignCast(self_ptr));
                if (ctrl == .Connect) {
                    if (self.connection_status == .Terminating or self.read_status == .Terminated) {
                        return;
                    }
                    if (self.connection_status == .Connected) {
                        return;
                    }

                    // Send abridged magic byte once on connect.
                    if (self.writer) |writer| {
                        writer.send(&[1]u8{0xef}) catch {
                            @panic("TODO: implement failure writer");
                        };
                    }

                    self.connection_status = .Connected;
                    if (self.reader) |reader| {
                        reader.control(.{ .Connect = .{} });
                    }
                }
                if (ctrl == .ConnectError or ctrl == .Disconnect) {
                    if (self.connection_status == .Terminating or self.read_status == .Terminated) {
                        return;
                    }

                    if (self.connection_status == .Terminating and self.read_status != .Terminated) {
                        const cbb = self.terminate_cb;
                        const ctx = self.terminate_ctx;
                        self.allocator.destroy(self);
                        if (cbb) |cb| {
                            cb(ctx);
                        }
                    }

                    self.connection_status = .Connecting;
                    if (self.reader) |reader| {
                        reader.control(.{ .Disconnect = .{} });
                    }
                    // TODO: handle reconnection
                }
            }

            const addr = std.net.Address.parseIp4("149.154.167.40", 443) catch {
                unreachable;
            };

            /// Provide default connection info if not delegated from upper layer.
            fn connectionInfo(self_ptr: *anyopaque) transport.ConnectionInfo {
                const self: *Abridged = @ptrCast(@alignCast(self_ptr));

                if (self.reader) |reader| {
                    return reader.connectionInfo();
                } else {
                    return transport.ConnectionInfo{
                        .address = addr,
                        .dcId = 2,
                        .media = false,
                        .testMode = true,
                    };
                }
            }

            /// Consume bytes from lower layer and drive the framing state machine.
            fn send(ptr: *anyopaque, src: []const u8) void {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                if (src.len == 0) {
                    return;
                }
                if (self.connection_status == .Terminating) {
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
                                send(ptr, remaining);
                            }
                        } else {
                            self.read_buf = self.allocator.alloc(u8, @as(usize, src[0]) * 4) catch {
                                @panic("TODO: handle allocation failure on send");
                            };
                            self.read_status = .ReadingBody;

                            const remaining = src[1..];

                            if (remaining.len > 0) {
                                send(ptr, remaining);
                            }
                        }
                    },
                    .ReadingLengthExtended => {
                        if (self.extended_len_read < 3) {
                            self.extended_len_buf[self.extended_len_read] = src[0];
                            self.extended_len_read += 1;

                            if (src.len > 1) {
                                send(ptr, src[1..]);
                            }
                        } else {
                            self.read_buf = self.allocator.alloc(u8, std.mem.readInt(u32, &self.extended_len_buf, .little) * 4) catch {
                                @panic("TODO: handle allocation failure on send");
                            };
                            self.read_status = .ReadingBody;
                            self.extended_len_read = 0;

                            send(ptr, src);
                        }
                    },
                    .ReadingBody => {
                        const incoming = src[0..@min(src.len, self.read_buf.len - self.read_len_net)];
                        const dest = self.read_buf[self.read_len_net..@min(self.read_len_net + incoming.len, self.read_buf.len)];

                        @memcpy(dest, incoming);

                        self.read_len_net += incoming.len;

                        if (self.read_len_net == self.read_buf.len) {
                            if (self.reader) |reader| {
                                reader.send(self.read_buf);
                            }
                            self.read_status = .ReadingLength;
                            self.read_len_net = 0;
                            self.allocator.free(self.read_buf);
                            self.read_buf = &[_]u8{};
                        }

                        if (src[incoming.len..].len > 0) {
                            send(ptr, src[incoming.len..]);
                        }
                    },
                    .Terminated => @panic("Transport has been terminated"),
                }
            }

            /// Hint for optimal next read size from the lower layer.
            fn sendSuggested(ptr: *anyopaque) usize {
                const self: *Abridged = @ptrCast(@alignCast(ptr));
                switch (self.read_status) {
                    .ReadingLength => return 1,
                    .ReadingLengthExtended => return 4 - (self.extended_len_read),
                    .ReadingBody => return self.read_buf.len - self.read_len_net,
                    .Terminated => @panic("Transport has been terminated"),
                }
            }
        };

        return .{ .vtable = .{
            .ctx = self_local,
            .control = reader.control,
            .connectionInfo = reader.connectionInfo,
            .send = reader.send,
            .sendSuggested = reader.sendSuggested,
        } };
    }
};

pub const AbridgedTransportInitializer = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !*AbridgedTransportInitializer {
        const self = try allocator.create(AbridgedTransportInitializer);
        self.allocator = allocator;
        return self;
    }

    pub fn initializer(self: *AbridgedTransportInitializer) transport.TransportInitializer {
        return .{
            .vtable = .{
                .ctx = self,
                .init = @ptrCast(&initInternal),
            },
        };
    }

    fn initInternal(self_ptr: *anyopaque) transport.Error!transport.TransportReturn {
        const self: *AbridgedTransportInitializer = @ptrCast(@alignCast(self_ptr));
        const ab = try self.allocator.create(Abridged);
        ab.* = Abridged{ .allocator = self.allocator };
        return transport.TransportReturn{
            .reader = ab.transportReader(),
            .control = ab.transportControl(),
            .writer = ab.transportWriter(),
        };
    }

    /// Free the initializer object. Does not tear down created transports.
    pub fn deinit(self: *AbridgedTransportInitializer) void {
        self.allocator.destroy(self);
    }
};
