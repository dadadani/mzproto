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

const Abridged = @import("lib/network/abridged.zig");
const LibxevTransport = @import("lib/network/libxev_tcp.zig");
const transport = @import("lib/network/transport.zig");

const ConnectionInfo = @import("lib/network/transport.zig").ConnectionInfo;
const AuthKey = @import("lib/proto/auth_key.zig");

const TransportUP = struct {
    authgen: AuthKey.AuthGen,
    transportWriter: transport.TransportWriter,

    fn GeneratedKey(ptr: *const anyopaque, res: AuthKey.GenError!AuthKey.GeneratedAuthKey) void {
        _ = ptr;
        _ = res catch |err| {
            std.log.err("Failed to generate key: {}", .{err});
            return;
        };
        std.log.info("Generated key", .{});
    }

    pub fn write(self_local: *anyopaque, data: []const u8) void {
        const self: *TransportUP = @ptrCast(@alignCast(self_local));
        self.transportWriter.send(data) catch {
            @panic("error in write");
        };
    }

    pub fn transportReader(self_local: *TransportUP) transport.TransportReader {
        const reader = struct {
            fn control(self_ptr: *anyopaque, ctrl: transport.Control) void {
                const self: *TransportUP = @ptrCast(@alignCast(self_ptr));
                std.debug.print("ctrl: {any}\n", .{ctrl});
                if (ctrl == .Connect) {
                    std.debug.print("starting auth gen\n", .{});
                    self.authgen.start();
                }
            }

            const address = std.net.Ip4Address.parse("149.154.167.40", 443) catch {};

            fn connectionInfo(self_ptr: *anyopaque) transport.ConnectionInfo {
                const self: *TransportUP = @ptrCast(@alignCast(self_ptr));
                _ = self;
                return .{
                    .address = std.net.Address{ .in = address },
                    .dcId = 2,
                    .media = false,
                    .testMode = false,
                };
            }

            fn send(ptr: *anyopaque, src: []const u8) void {
                const self: *TransportUP = @ptrCast(@alignCast(ptr));
                self.authgen.onData(src);
            }

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
};

pub fn main() !void {
    var loop = try xev.Loop.init(.{});
    var allocator = std.heap.smp_allocator;

    const abridged = try Abridged.AbridgedTransportInitializer.init(allocator);
    const transportupper = try abridged.initializer().init();

    const libxev = try LibxevTransport.LibxevTransportInitializer.init(allocator, &loop);
    const transportlower = try libxev.initializer().init();

    var up = try allocator.create(TransportUP);
    up.* = TransportUP{ .authgen = AuthKey.AuthGen{
        .allocator = allocator,
        .callback = TransportUP.GeneratedKey,
        .user_data = up,
        .dcId = 2,
        .testMode = true,
        .media = false,
        .writeDataCtx = up,
        .writeData = TransportUP.write,
    }, .transportWriter = transportupper.writer };

    //transportupper[2].setReader(up.transportReader());
    //transportlower[2].setReader(transportupper[0]);
    //transportupper[2].setWriter(transportlower[1]);

    transportupper.control.setReader(up.transportReader());
    transportlower.control.setReader(transportupper.reader);
    transportupper.control.setWriter(transportlower.writer);
    try loop.run(.until_done);
}
