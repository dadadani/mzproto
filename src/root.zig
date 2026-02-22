const std = @import("std");
const tl_tests = @import("lib/tl/api_tests.zig");
const tl = @import("./lib/tl/api.zig");
const generate = @import("./lib/proto/auth_key.zig");
const Transport = @import("./lib/transport.zig").Transport;
const utils = @import("./lib/proto/utils.zig");

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

    const allocator = init.gpa;
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

    std.debug.print("sending some messages\n", .{});

    var msg_config_fut = try io.io().concurrent(Session.send, .{ &session, io.io(), allocator, tl.TL{ .InvokeWithLayer = &tl.InvokeWithLayer{ .layer = tl.LAYER_VERSION, .query = .{ .InitConnection = &tl.InitConnection{ .api_id = 525926, .app_version = "1.0.0-dev", .device_model = "Samsung J5", .lang_code = "en", .lang_pack = "", .system_lang_code = "en", .system_version = "Android 15", .query = tl.TL{ .HelpGetConfig = &.{} } } } } } });
    var msg_ping_fut = try io.io().concurrent(Session.send, .{ &session, io.io(), allocator, tl.TL{ .ProtoPing = &.{ .ping_id = 134243 } } });

    std.debug.print("starting workers\n", .{});
    var worker_ping = try io.io().concurrent(Session.pingWorker, .{ &session, io.io(), allocator });
    var worker = try io.io().concurrent(Session.writerWorker, .{ &session, io.io(), allocator, &transport });
    var worker_reader = try io.io().concurrent(Session.readerWorker, .{ &session, io.io(), allocator, &transport });
    //  std.debug.print("recv message: {any}\n", .{msg.data});

    const msg_maybe = msg_ping_fut.await(io.io());
    std.debug.print("msg ping awaited\n", .{});

    const msg_config_maybe = msg_config_fut.await(io.io());
    std.debug.print("msg config awaited\n", .{});

    ok: {
        const msg = msg_maybe catch |err| {
            std.debug.print("msg failed: {any}", .{err});
            break :ok;
        };

        defer msg.deinit(allocator);

        std.debug.print("recv message: {any}\n", .{
            msg.data,
        });
    }

    ok: {
        const msg_config = msg_config_maybe catch |err| {
            std.debug.print("msg failed: {any}", .{err});
            break :ok;
        };

        defer msg_config.deinit(allocator);

        std.debug.print("recv message: {any}\n", .{
            msg_config.data,
        });
    }

    var timeout: std.Io.Timeout = .{ .deadline = std.Io.Clock.Timestamp.now(io.io(), .boot).addDuration(.{ .raw = std.Io.Duration.fromSeconds(40), .clock = .boot }) };

    try timeout.sleep(io.io());

    msg_config_fut = try io.io().concurrent(Session.send, .{ &session, io.io(), allocator, tl.TL{ .HelpGetCdnConfig = &.{} } });
    const msg_config = try msg_config_fut.await(io.io());
    defer msg_config.deinit(allocator);

    std.debug.print("recv message cdnconfig: {any}\n", .{
        msg_config.data,
    });

    if (msg_config.data == .ProtoRpcError) {
        std.debug.print("RPCERROR: {s}\n", .{
            msg_config.data.ProtoRpcError.error_message,
        });
    }

    timeout = .{ .deadline = std.Io.Clock.Timestamp.now(io.io(), .boot).addDuration(.{ .raw = std.Io.Duration.fromSeconds(40), .clock = .boot }) };
    try timeout.sleep(io.io());
    //try session.sendMessageTransport(&transport, io.io(), allocator.allocator(), tl.TL{ .ProtoPing = &tl.ProtoPing{ .ping_id = 43242 } });
    //  std.debug.print("sent ping\n", .{});

    // const message = try session.recvMessageTransport(&transport, allocator.allocator());
    // defer allocator.allocator().free(message.ptr);
    worker.cancel(io.io()) catch {};
    worker_reader.cancel(io.io()) catch {};
    worker_ping.cancel(io.io()) catch {};
    std.debug.print("main: end 1\n", .{});

    //_ = test_test.cancel(io.io()) catch {};
    session.destroyRequests(io.io());
    std.debug.print("main: end 3\n", .{});

    session.deinit(io.io(), allocator);
    std.debug.print("main: end 4\n", .{});
}
