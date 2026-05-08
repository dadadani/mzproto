const std = @import("std");
const utils = @import("./utils.zig");
const tl = @import("./tl/api.zig");

const TIMEOUT_CONNECTION = std.Io.Duration.fromSeconds(5);

pub const DcAddress = union(enum) {
    tcp: std.Io.net.IpAddress,
};

pub const TransportHolder = struct {
    transport: *Transport,
    arena: std.heap.ArenaAllocator,

    pub fn deinit(self: TransportHolder, io: std.Io) void {
        self.transport.deinit(io);
        self.arena.deinit();
    }
};

pub const TransportMode = enum {
    Abridged,
};

const Transport = @import("./transport.zig").Transport;

const TransportConnector = @This();

mutex: std.Io.Mutex = .init,
dc_address_map: std.AutoHashMapUnmanaged(utils.DcId, DcAddress) = .empty,
mode: TransportMode,

const DEFAULT_TCP_PROD_SERVER = .{
    utils.DcId{ .id = 2 },
    DcAddress{ .tcp = (std.Io.net.IpAddress.parse("149.154.167.50", 443) catch unreachable) },
};

const DEFAULT_TCP_TEST_SERVER = .{
    utils.DcId{ .id = 2, .testmode = true },
    DcAddress{ .tcp = (std.Io.net.IpAddress.parse("149.154.167.40", 443) catch unreachable) },
};

pub fn init(allocator: std.mem.Allocator, protocol: std.meta.Tag(DcAddress), mode: TransportMode) !TransportConnector {
    var self: TransportConnector = .{ .mode = mode };
    if (protocol == .tcp) {
        try self.dc_address_map.ensureUnusedCapacity(allocator, 2);
        self.dc_address_map.putAssumeCapacity(DEFAULT_TCP_PROD_SERVER[0], DEFAULT_TCP_PROD_SERVER[1]);
        self.dc_address_map.putAssumeCapacity(DEFAULT_TCP_TEST_SERVER[0], DEFAULT_TCP_TEST_SERVER[1]);
    }
    return self;
}

pub fn pickFirstDc(self: *TransportConnector, io: std.Io, test_mode: bool) utils.DcId {
    self.mutex.lockUncancelable(io);
    defer self.mutex.unlock(io);

    var it = self.dc_address_map.iterator();
    while (it.next()) |dc| {
        if (dc.key_ptr.testmode == test_mode and dc.key_ptr.media == false) {
            return dc.key_ptr.*;
        }
    }

    unreachable;
}

pub inline fn isAvailable(self: *TransportConnector, io: std.Io, dc_id: utils.DcId) bool {
    self.mutex.lockUncancelable(io);
    defer self.mutex.unlock(io);
    return self.dc_address_map.contains(dc_id);
}

pub fn importConfig(self: *TransportConnector, allocator: std.mem.Allocator, io: std.Io, config: *const tl.Config) !void {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    for (config.dc_options) |idc_option| {
        const dc_option = idc_option.DcOption;

        // TODO: add support for obfuscated connections
        if (dc_option.tcpo_only) {
            continue;
        }

        // TODO: add support for ipv6
        if (dc_option.ipv6) {
            continue;
        }

        try self.dc_address_map.put(allocator, .{
            .id = @intCast(dc_option.id),
            .cdn = dc_option.cdn,
            .media = dc_option.media_only,
            .testmode = config.test_mode,
        }, .{ .tcp = try .parse(dc_option.ip_address, @intCast(dc_option.port)) });
    }
}

pub fn connectTo(self: *TransportConnector, allocator: std.mem.Allocator, io: std.Io, dc_id: utils.DcId) !?TransportHolder {
    // TODO: add ipv6 support with fallback to ipv4. I don't have an internet connection with an assigned ipv6 address right now

    const address, const mode = blk: {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);
        const address = self.dc_address_map.get(dc_id) orelse return null;
        const mode = self.mode;
        break :blk .{ address, mode };
    };

    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();

    const transport = blk: {
        switch (address) {
            .tcp => |address_tcp| {
                const writeBuf = try arena.allocator().alloc(u8, 512);
                const readBuf = try arena.allocator().alloc(u8, 512);

                const stream = try address_tcp.connect(io, .{
                    .mode = .stream,
                    // timeout is not implemented yet :(
                    //.timeout = .{ .duration = .{ .raw = TIMEOUT_CONNECTION, .clock = .boot } },
                });
                errdefer stream.close(io);

                switch (mode) {
                    .Abridged => {
                        const transport = try arena.allocator().create(Transport);
                        transport.* = .{ .transport = .{ .Streamridged = try Transport.StreamAbridged.init(io, stream, readBuf, writeBuf) } };
                        break :blk transport;
                    },
                }
            },
        }
    };
    errdefer transport.deinit(io);
    return .{ .arena = arena, .transport = transport };
}

pub fn deinit(self: *TransportConnector, allocator: std.mem.Allocator, io: std.Io) void {
    self.mutex.lockUncancelable(io);
    self.dc_address_map.deinit(allocator);
}
