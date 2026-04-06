const std = @import("std");
const tl_tests = @import("lib/tl/api_tests.zig");
const tl = @import("./lib/tl/api.zig");
const generate = @import("./lib/proto/auth_key.zig");
const Transport = @import("./lib/transport.zig").Transport;
const utils = @import("./lib/proto/utils.zig");
const CompileOptions = @import("mzproto_options");

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

    var session: Session = undefined;

    try session.init(io.io(), &connector, .{@as(u8, 0)} ** 256, dc);

    var supervisor = try io.io().concurrent(Session.sessionSupervisor, .{ &session, allocator, io.io() });

    var msg_config_fut = try io.io().concurrent(Session.send, .{ &session, io.io(), allocator, tl.TL{ .InvokeWithLayer = &tl.InvokeWithLayer{ .layer = tl.LAYER_VERSION, .query = .{ .InitConnection = &tl.InitConnection{ .api_id = 525926, .app_version = "1.0.0-dev", .device_model = "Samsung J5", .lang_code = "en", .lang_pack = "", .system_lang_code = "en", .system_version = "Android 15", .query = tl.TL{ .HelpGetConfig = &.{} } } } } } });
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

    var timeout: std.Io.Timeout = .{ .deadline = std.Io.Clock.Timestamp.now(io.io(), .boot).addDuration(.{ .raw = std.Io.Duration.fromSeconds(40), .clock = .boot }) };

    try timeout.sleep(io.io());

    try supervisor.cancel(io.io());

    session.destroyRequests(io.io());

    session.deinit(io.io(), allocator);
}
