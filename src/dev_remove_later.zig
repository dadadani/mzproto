const std = @import("std");
const mzproto = @import("mzproto");

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
        .api_hash = "test123",
        .api_id = 3,
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
    defer client.deinit();

    switch (client.sendMessage("testing123")) {
        .err => |err| {
            std.process.fatal("error message: {d} - {s}", .{ err.code, err.message });
        },
        .ok => {},
    }
}
