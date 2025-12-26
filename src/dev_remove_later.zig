const std = @import("std");
const generate = @import("./lib/proto/auth_key.zig");
const Transport = @import("./lib/transport.zig").Transport;

pub fn main() !void {
    var allocator = std.heap.DebugAllocator(.{}){};
    defer {
        _ = allocator.deinit();
    }

    var io = std.Io.Threaded.init(allocator.allocator());
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


    const gen_key = try generate.generate(allocator.allocator(), io.io(), &transport, 2, false, true);

    std.debug.print("generated key: {any}", .{gen_key});
}
