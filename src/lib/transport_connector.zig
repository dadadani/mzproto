const std = @import("std");
const utils = @import("./utils.zig");

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
        if (dc.key_ptr.testmode == test_mode) {
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

        const base_transport = blk: {
            switch (address) {
                .tcp => |address_tcp| {
                    const writeBuf = try arena.allocator().alloc(u8, 1024);
                    const readBuf = try arena.allocator().alloc(u8, 1024);

                    const stream = try arena.allocator().create(Transport);

                    stream.* = try Transport.initStream(
                        io,
                        .{ .ip = .{ .address = address_tcp, .options = .{ .mode = .stream } } },
                        readBuf, // TODO: add buffers
                        writeBuf,
                    );
                    break :blk stream;
                },
            }
        };
        errdefer base_transport.deinit(io);

        switch (self.mode) {
            .Abridged => {
                const transport = try arena.allocator().create(Transport);

                transport.* = try Transport.init(io, .Abridged, base_transport);

                return .{ .arena = arena, .transport = transport };
            },
        }
    }

    return null;
}

pub fn deinit(self: *TransportConnector, allocator: std.mem.Allocator) void {
    self.dc_address_map.deinit(allocator);
}
