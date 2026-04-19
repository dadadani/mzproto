const std = @import("std");
const tl_tests = @import("lib/tl/api_tests.zig");
const tl = @import("./lib/tl/api.zig");
const generate = @import("./lib/proto/auth_key.zig");
const Transport = @import("./lib/transport.zig").Transport;
const utils = @import("./lib/proto/utils.zig");
const CompileOptions = @import("mzproto_options");
const AuthKey = @import("./lib/proto/auth_key.zig");
const ClientInfo = @import("./lib/client_info.zig");
const Session = @import("./lib/proto/session.zig");

const Storage = @import("./lib/storage.zig");

const TransportConnector = @import("./lib/transport_connector.zig");

test {
    _ = tl_tests;
    _ = Storage;
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

    var connector = try TransportConnector.init(allocator, .tcp, .Abridged);
    defer connector.deinit(allocator);

    const dc = connector.pickFirstDc(true);

    var client_info = ClientInfo{
        .api_id = 3,
        .api_hash = "a",
        .device_model = "Samsung Galaxy J5",
        .app_version = "mzproto dev",
        .lang_code = "en",
        .lang_pack = "",
        .system_lang_code = "en",
        .system_version = "Android 15",
    };

    const auth_key = blk: {
        std.debug.print("generating perm_key\n", .{});
        const conn = (try connector.connectTo(allocator, io.io(), dc)).?;
        defer conn.deinit(io.io());

        const auth_key = try AuthKey.generate(allocator, io.io(), conn.transport, @intCast(dc.id), dc.media, dc.testmode, false);
        std.debug.print("perm_key ok\n", .{});

        break :blk auth_key;
    };

    var session: Session = undefined;

    try session.init(io.io(), &connector, &client_info, auth_key.auth_key, dc);

    var supervisor = try io.io().concurrent(Session.sessionSupervisor, .{ &session, allocator, io.io() });

    var msg_config_fut = try io.io().concurrent(Session.send, .{ &session, io.io(), allocator, tl.TL{ .HelpGetConfig = &.{} }, null, false });
    const msg_config_maybe = msg_config_fut.await(io.io());
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

    var timeout: std.Io.Timeout = .{ .deadline = std.Io.Clock.Timestamp.now(io.io(), .boot).addDuration(.{ .raw = std.Io.Duration.fromSeconds(300), .clock = .boot }) };

    try timeout.sleep(io.io());

    try supervisor.cancel(io.io());

    session.destroyRequests(allocator, io.io());

    session.deinit(io.io(), allocator);
}
