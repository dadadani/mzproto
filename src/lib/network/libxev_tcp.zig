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

//! TCP transport backed by libxev.

const std = @import("std");
const xev = @import("xev").Dynamic;
const transport = @import("transport.zig");

const Libxev = struct {
    allocator: std.mem.Allocator,
    loop: *xev.Loop,
    tcp: xev.TCP = undefined,
    status: enum { Connected, Disconnected, Connecting, Uninitialized, Terminating } = .Uninitialized,
    read_connect_completion: xev.Completion = undefined,

    write_queue: xev.WriteQueue = .{},

    reader: ?transport.TransportReader = null,

    read_buf: []u8 = &[_]u8{},

    fn onData(
        selff: ?*Libxev,
        l: *xev.Loop,
        c: *xev.Completion,
        s: xev.TCP,
        b: xev.ReadBuffer,
        r: xev.ReadError!usize,
    ) xev.CallbackAction {
        _ = l;
        _ = c;
        _ = s;
        const self = selff.?;
        if (self.status == .Terminating) return .disarm;
        const size = r catch |err| {
            if (err == xev.ReadError.EOF) {
                std.debug.print("libxev EOF\n", .{});

                if (self.status == .Disconnected) return .disarm;
                self.status = .Disconnected;
                if (self.reader) |reader| {
                    reader.control(.{ .Disconnect = .{} });
                }
                return .disarm;
            }
            @panic("TODO: Handle read error");
        };
        if (self.reader) |reader| {
            reader.send(b.slice[0..size]);
        }
        self.read();
        return .disarm;
    }

    fn read(self: *Libxev) void {
        if (self.status != .Connected) {
            return;
        }
        if (self.reader) |reader| {
            if (self.read_buf.len == 0) {
                self.read_buf = self.allocator.alloc(u8, reader.sendSuggested()) catch {
                    @panic("TODO: handle allocation failure");
                };
            } else {
                self.read_buf = self.allocator.realloc(self.read_buf, reader.sendSuggested()) catch {
                    @panic("TODO: handle allocation failure");
                };
            }

            self.tcp.read(self.loop, &self.read_connect_completion, xev.ReadBuffer{ .slice = self.read_buf }, Libxev, self, onData);
        }
    }

    fn connectedCb(selff: ?*Libxev, l: *xev.Loop, c: *xev.Completion, s: xev.TCP, r: xev.ConnectError!void) xev.CallbackAction {
        _ = l;
        _ = c;
        _ = s;

        const self = selff.?;
        r catch {
            self.status = .Disconnected;
            if (self.reader) |reader| {
                reader.control(.{ .ConnectError = .{} });
            }
            return .disarm;
        };

        self.status = .Connected;
        if (self.reader) |reader| {
            reader.control(.{ .Connect = .{} });
        }
        self.read();

        return .disarm;
    }

    fn tcpInitialize(self: *Libxev) void {
        if (self.status == .Connected or self.status == .Connecting) {
            return;
        }
        if (self.reader) |reader| {
            self.tcp = xev.TCP.init(reader.connectionInfo().address) catch {
                @panic("TODO: handle TCP init failure");
            };
            self.status = .Connecting;

            self.tcp.connect(self.loop, &self.read_connect_completion, reader.connectionInfo().address, Libxev, self, connectedCb);
        }
    }

    pub fn closeCallback(
        selff: ?*Libxev,
        _: *xev.Loop,
        c: *xev.Completion,
        _: xev.TCP,
        _: xev.CloseError!void,
    ) xev.CallbackAction {
        const self = selff.?;

        if (self.status == .Terminating) {
            self.allocator.destroy(c);

            if (self.read_buf.len > 0) {
                self.allocator.free(self.read_buf);
            }
            self.allocator.destroy(self);
            return .disarm;
        }

        defer self.allocator.destroy(c);

        if (self.status == .Disconnected) return .disarm;
        self.status = .Disconnected;

        if (self.reader) |reader| {
            reader.control(.{ .Disconnect = .{} });
            return .disarm;
        }

        return .disarm;
    }

    fn closeTcp(self: *Libxev) void {
        if (self.status == .Connected or self.status == .Connecting or self.status == .Terminating) {
            const completion = self.allocator.create(xev.Completion) catch {
                @panic("TODO: handle memory oom");
            };
            self.tcp.close(self.loop, completion, Libxev, self, closeCallback);
        }
    }

    /// Control surface: wire upper reader/writer and manage teardown.
    pub fn transportControl(self_local: *Libxev) transport.TransportControl {
        const control = struct {
            fn setWriter(self_ptr: *anyopaque, writer: transport.TransportWriter) void {
                _ = self_ptr;
                _ = writer;
            }

            fn setReader(self_ptr: *anyopaque, reader: transport.TransportReader) void {
                const self: *Libxev = @ptrCast(@alignCast(self_ptr));
                self.reader = reader;
                if (self.status == .Uninitialized) {
                    tcpInitialize(self);
                }
            }

            fn deinit(self_ptr: *anyopaque, ctx: ?*anyopaque, cb: *const (fn (self: ?*anyopaque) void)) void {
                const self: *Libxev = @ptrCast(@alignCast(self_ptr));
                _ = self;
                _ = ctx;
                _ = cb;
                @panic("TODO: implement deinit");
            }
        };

        return .{ .vtable = .{
            .ctx = self_local,
            .deinit = control.deinit,
            .setReader = control.setReader,
            .setWriter = control.setWriter,
        } };
    }

    /// Reader exposed to lower layers. This transport is usually the bottom of the stack,
    /// so most methods are placeholders/unused here.
    pub fn transportReader(self_local: *Libxev) transport.TransportReader {
        const reader = struct {
            fn control(_: *anyopaque, _: transport.Control) void {}

            fn connectionInfo(_: *anyopaque) transport.ConnectionInfo {
                return undefined;
            }

            fn send(_: *anyopaque, _: []const u8) void {}

            fn sendSuggested(_: *anyopaque) usize {
                return 0;
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

    const WriteRequest = struct {
        xev_write_request: xev.WriteRequest,
        self: *Libxev,
    };

    pub fn transportWriter(self_local: *Libxev) transport.TransportWriter {
        const writer = struct {
            fn send(self_ptr: *anyopaque, data: []const u8) transport.Error!void {
                const self: *Libxev = @ptrCast(@alignCast(self_ptr));
                if (self.status != .Connected) {
                    return transport.Error.ConnectionClosed;
                }

                const buf = try self.allocator.dupe(u8, data);
                errdefer self.allocator.free(buf);
                const req = try self.allocator.create(WriteRequest);
                req.self = self;
                self.tcp.queueWrite(self.loop, &self.write_queue, &req.xev_write_request, .{ .slice = buf }, WriteRequest, req, onDataWritten);
            }

            fn control(self_ptr: *anyopaque, ctrl: transport.Control) void {
                const self: *Libxev = @ptrCast(@alignCast(self_ptr));
                if (ctrl == .Connect and self.status == .Disconnected) {
                    self.tcpInitialize();
                }
                if (ctrl == .Disconnect) {
                    self.closeTcp();
                }
            }
        };

        return .{ .vtable = .{
            .control = writer.control,
            .ctx = self_local,
            .send = writer.send,
        } };
    }

    fn onDataWritten(
        selff: ?*WriteRequest,
        _: *xev.Loop,
        _: *xev.Completion,
        _: xev.TCP,
        b: xev.WriteBuffer,
        r: xev.WriteError!usize,
    ) xev.CallbackAction {
        const write_request = selff.?;
        defer {
            write_request.self.allocator.free(b.slice);
            write_request.self.allocator.destroy(write_request);
        }

        const size = r catch {
            @panic("TODO: handle write failure");
        };

        _ = size;

        return .disarm;
    }
};

/// Factory for the libxev TCP transport.
pub const LibxevTransportInitializer = struct {
    allocator: std.mem.Allocator,
    loop: *xev.Loop,

    /// Allocate the initializer. Call deinit() when done with the initializer itself.
    pub fn init(allocator: std.mem.Allocator, loop: *xev.Loop) !*LibxevTransportInitializer {
        const self = try allocator.create(LibxevTransportInitializer);
        self.allocator = allocator;
        self.loop = loop;
        return self;
    }

    pub fn initializer(self: *LibxevTransportInitializer) transport.TransportInitializer {
        return .{
            .vtable = .{
                .ctx = self,
                .init = initInternal,
            },
        };
    }

    fn initInternal(self_ptr: *anyopaque) transport.Error!transport.TransportReturn {
        const self: *LibxevTransportInitializer = @ptrCast(@alignCast(self_ptr));
        const libxev = try self.allocator.create(Libxev);
        libxev.* = Libxev{
            .allocator = self.allocator,
            .loop = self.loop,
        };
        return transport.TransportReturn{
            .control = libxev.transportControl(),
            .reader = libxev.transportReader(),
            .writer = libxev.transportWriter(),
        };
    }

    /// Free the initializer object. Does not tear down created transports.
    pub fn deinit(self: *LibxevTransportInitializer) void {
        self.allocator.destroy(self);
    }
};
