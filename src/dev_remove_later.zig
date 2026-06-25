const std = @import("std");
const mzproto = @import("mzproto");
const info = @import("./dev.zon");

fn unwrapTypeRes(comptime T: type) type {
    switch (@typeInfo(T)) {
        .@"union" => |x| {
            if (x.field_names.len != 2) {
                @compileError("Type is not a Result");
            }
            if (!std.mem.eql(u8, x.field_names[0], "ok")) {
                @compileError("Type is not a Result");
            }
            return x.field_types[0];
        },
        else => @compileError("Type is not a result"),
    }
}

// andrew, please make compile-time traits!!!!!!!!!!!!!!!!!!!
fn unwrapResult(result: anytype) unwrapTypeRes(@TypeOf(result)) {
    switch (result) {
        .ok => |ok| return ok,
        .err => |err| std.process.fatal("{s} ({d})", .{ err.message, err.code }),
    }
}

fn updatesLoop(allocator: std.mem.Allocator, client: *mzproto.Client) !void {
    while (unwrapResult(client.nextUpdate(true))) |update| {
        var update_var = update;
        defer update_var.deinit(allocator);

        switch (update_var) {
            .UpdateClientStatus => |cstat| {
                if (cstat.status == .waiting_authorization) {
                    std.log.debug("need to login\n", .{});
                    unwrapResult(client.authenticateBot(info.bot_token));
                }
            },
        }
        std.log.info("{any}", .{update});
    }
}
pub fn main(init: std.process.Init) !void {
    //  var allocator = std.heap.DebugAllocator(.{}){};
    //  defer {
    //    const ok = allocator.deinit();
    //  std.debug.print("dealloc: {any}", .{ok});
    //  }

    const allocator = init.gpa;
    var io = std.Io.Threaded.init(allocator, .{ .environ = init.minimal.environ });
    defer io.deinit();

    const config = mzproto.Config{
        .api_hash = info.api_hash,
        .api_id = info.api_id,
        .app_version = "0.0.0",
        .device_model = "test",
        .storage_backend = .memory_dc_bin_storage,
        .system_version = "0.0.0",
        .system_language = "en",
        .storage_path = "/tmp/mzproto.bin",
        .add_branding = null,
        .enable_ipv4 = null,
        .enable_ipv6 = null,
        .testmode = false,
    };

    var client = mzproto.Client.init(allocator, io.io(), &config) catch |err| {
        std.process.fatal("error client: {s}", .{@errorName(err)});
    };
    //defer client.deinit();
    const RETRY_IN = std.Io.Duration.fromMilliseconds(1000);
    const timeout: std.Io.Timeout = .{ .duration = .{ .raw = RETRY_IN, .clock = .boot } };

    try timeout.sleep(io.io());

    try updatesLoop(allocator, &client);
}
