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

const std = @import("std");
const tl_tests = @import("lib/tl/api_tests.zig");
const tl = @import("./lib/tl/api.zig");
const generate = @import("./lib/proto/auth_key.zig");
const Transport = @import("./lib/transport.zig").Transport;

const Session = @import("./lib/proto/session.zig");

test {
    _ = tl_tests;
}

pub fn generate_dev(init: std.process.Init) !void {
    //  var allocator = std.heap.DebugAllocator(.{}){};
    //  defer {
    //    const ok = allocator.deinit();
    //  std.debug.print("dealloc: {any}", .{ok});
    //  }

    const allocator = init.arena.allocator();

    var io = std.Io.Threaded.init(allocator, .{ .environ = init.minimal.environ });
    defer io.deinit();

    const ip = try std.Io.net.IpAddress.parse("149.154.167.40", 443);
    //const ip = try std.Io.net.IpAddress.parse("127.0.0.1", 5403);

    var stream = try ip.connect(io.io(), .{ .mode = .stream, .protocol = .tcp });
    stream = stream;

    var bufWrite: [1024]u8 = undefined;
    var bufRead: [1024]u8 = undefined;

    var writer = stream.writer(io.io(), &bufWrite);
    var reader = stream.reader(io.io(), &bufRead);

    var transport: Transport = try Transport.init(.Abridged, &writer.interface, &reader.interface);
    //
    std.debug.print("starting gen\n", .{});
    const gen_key = try generate.generate(allocator, io.io(), &transport, 2, false, true);
    std.debug.print("generated key: {any}\n", .{gen_key});

    stream.close(io.io());

    stream = try ip.connect(io.io(), .{ .mode = .stream, .protocol = .tcp });
    writer = stream.writer(io.io(), &bufWrite);
    reader = stream.reader(io.io(), &bufRead);

    transport = try .init(.Abridged, &writer.interface, &reader.interface);

    var session = try Session.init(io.io(), allocator, gen_key.authKey, tl.ProtoFutureSalt{
        .salt = gen_key.first_salt,
        .valid_since = 0,
        .valid_until = 0,
    }, 2, true, false, false);

    std.debug.print("starting worker\n", .{});
    var worker = try io.io().concurrent(Session.worker, .{ &session, io.io(), &transport });
    var worker_reader = try io.io().concurrent(Session.recvMessageTransport, .{ &session, io.io(), &transport });

    std.debug.print("sending ping\n", .{});
    const msg = try session.send(io.io(), tl.TL{ .ProtoPing = &tl.ProtoPing{ .ping_id = 43242 } });
    defer allocator.free(msg.ptr);
    std.debug.print("recv message: {any}\n", .{msg.data});

    //try session.sendMessageTransport(&transport, io.io(), allocator.allocator(), tl.TL{ .ProtoPing = &tl.ProtoPing{ .ping_id = 43242 } });
    //  std.debug.print("sent ping\n", .{});

    // const message = try session.recvMessageTransport(&transport, allocator.allocator());
    // defer allocator.allocator().free(message.ptr);
    // std.debug.print("recv message: {any}\n", .{message.data});
    try worker.await(io.io());
    try worker_reader.await(io.io());
}
