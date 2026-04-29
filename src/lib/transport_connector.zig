const std = @import("std");
const utils = @import("./utils.zig");

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

pub fn pickFirstDc(self: *const TransportConnector, test_mode: bool) utils.DcId {
    var it = self.dc_address_map.iterator();
    while (it.next()) |dc| {
        if (dc.key_ptr.testmode == test_mode and dc.key_ptr.media == false) {
            return dc.key_ptr.*;
        }
    }

    unreachable;
}

pub inline fn isAvailable(self: *const TransportConnector, dc_id: utils.DcId) bool {
    return self.dc_address_map.contains(dc_id);
}

pub fn connectTo(self: *const TransportConnector, allocator: std.mem.Allocator, io: std.Io, dc_id: utils.DcId) !?TransportHolder {
    if (self.dc_address_map.get(dc_id)) |address| {
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

                    switch (self.mode) {
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

    return null;
}

pub fn deinit(self: *TransportConnector, allocator: std.mem.Allocator) void {
    self.dc_address_map.deinit(allocator);
}
