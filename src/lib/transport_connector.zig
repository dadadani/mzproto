const std = @import("std");
const utils = @import("./utils.zig");
const tl = @import("tl");

const TIMEOUT_CONNECTION = std.Io.Duration.fromSeconds(5);

pub const DcAddressValue = union(enum) {
    tcp: std.Io.net.IpAddress,
};

pub const DcAddress = struct {
    addr: DcAddressValue,
    enable_obfuscation: bool = false,
    obfuscation_key: ?[16]u8 = null,

    pub fn eql(self: DcAddress, cmp: DcAddress) bool {
        if (self.enable_obfuscation != cmp.enable_obfuscation) {
            return false;
        }

        switch (self.addr) {
            .tcp => |tcp| {
                if (cmp.addr != .tcp) {
                    return false;
                }
                return tcp.eql(&cmp.addr.tcp);
            },
        }
    }
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

lock: std.Io.RwLock = .init,

dc_address_map: std.AutoHashMapUnmanaged(utils.DcId, std.ArrayList(DcAddress)) = .empty,
mode: TransportMode,

enable_ipv6: bool,
enable_ipv4: bool,

const DEFAULT_TCP_PROD_SERVER = .{
    utils.DcId{ .id = 2 },
    .{ DcAddress{ .addr = .{ .tcp = (std.Io.net.IpAddress.parse("2001:67c:4e8:f002::a", 443) catch unreachable) } }, DcAddress{ .addr = .{ .tcp = (std.Io.net.IpAddress.parse("149.154.167.50", 443) catch unreachable) } } },
};

const DEFAULT_TCP_TEST_SERVER = .{
    utils.DcId{ .id = 2, .testmode = true },
    .{
        DcAddress{ .addr = .{ .tcp = (std.Io.net.IpAddress.parse("2001:67c:4e8:f002::e", 443) catch unreachable) } },
        DcAddress{
            .addr = .{ .tcp = (std.Io.net.IpAddress.parse("149.154.167.40", 443) catch unreachable) },
        },
    },
};

pub fn init(allocator: std.mem.Allocator, protocol: std.meta.Tag(DcAddressValue), mode: TransportMode, enable_ipv6: bool, enable_ipv4: bool) !TransportConnector {
    var self: TransportConnector = .{ .mode = mode, .enable_ipv6 = enable_ipv6, .enable_ipv4 = enable_ipv4 };
    if (protocol == .tcp) {
        try self.dc_address_map.ensureUnusedCapacity(allocator, 2);
        errdefer self.dc_address_map.deinit(allocator);

        var dc_prod: std.ArrayList(DcAddress) = try .initCapacity(allocator, 2);
        errdefer dc_prod.deinit(allocator);

        if (enable_ipv6) {
            dc_prod.appendAssumeCapacity(DEFAULT_TCP_PROD_SERVER[1][0]);
        }

        if (enable_ipv4) {
            dc_prod.appendAssumeCapacity(DEFAULT_TCP_PROD_SERVER[1][1]);
        }

        var dc_test: std.ArrayList(DcAddress) = try .initCapacity(allocator, 2);
        errdefer dc_test.deinit(allocator);

        if (enable_ipv6) {
            dc_test.appendAssumeCapacity(DEFAULT_TCP_TEST_SERVER[1][0]);
        }

        if (enable_ipv4) {
            dc_test.appendAssumeCapacity(DEFAULT_TCP_TEST_SERVER[1][1]);
        }

        //dc_test.appendSliceAssumeCapacity(&DEFAULT_TCP_TEST_SERVER[1]);

        self.dc_address_map.putAssumeCapacity(DEFAULT_TCP_PROD_SERVER[0], dc_prod);
        self.dc_address_map.putAssumeCapacity(DEFAULT_TCP_TEST_SERVER[0], dc_test);
    }
    return self;
}

pub fn pickFirstDc(self: *TransportConnector, io: std.Io, test_mode: bool) utils.DcId {
    self.lock.lockSharedUncancelable(io);
    defer self.lock.unlockShared(io);

    var it = self.dc_address_map.iterator();
    while (it.next()) |dc| {
        if (dc.key_ptr.testmode == test_mode and dc.key_ptr.media == false) {
            return dc.key_ptr.*;
        }
    }

    unreachable;
}

pub inline fn isAvailable(self: *TransportConnector, io: std.Io, dc_id: utils.DcId) bool {
    self.lock.lockSharedUncancelable(io);
    defer self.lock.unlockShared(io);
    return self.dc_address_map.contains(dc_id);
}

pub fn importConfig(self: *TransportConnector, allocator: std.mem.Allocator, io: std.Io, config: *const tl.Config) !void {
    try self.lock.lock(io);
    defer self.lock.unlock(io);

    check: for (config.dc_options) |idc_option| {
        const dc_option = idc_option.DcOption;

        // TODO: add support for obfuscated connections
        if (dc_option.tcpo_only) {
            continue;
        }

        if (!self.enable_ipv6 and dc_option.ipv6) {
            continue;
        }

        if (!self.enable_ipv4 and !dc_option.ipv6) {
            continue;
        }

        const dc_addr_list = try self.dc_address_map.getOrPut(allocator, .{
            .id = @intCast(dc_option.id),
            .cdn = dc_option.cdn,
            .media = dc_option.media_only,
            .testmode = config.test_mode,
        });

        if (!dc_addr_list.found_existing) {
            dc_addr_list.value_ptr.* = .empty;
        }

        // check if already contains the same IP
        for (dc_addr_list.value_ptr.items) |addr| {
            if (addr.addr.tcp.eql(&try .parse(dc_option.ip_address, @intCast(dc_option.port)))) {
                continue :check;
            }
        }

        try dc_addr_list.value_ptr.append(allocator, .{ .addr = .{ .tcp = try .parse(dc_option.ip_address, @intCast(dc_option.port)) } });

        if (dc_option.ipv6 and dc_addr_list.value_ptr.items.len > 1) {
            const first = dc_addr_list.value_ptr.items[0];
            dc_addr_list.value_ptr.items[0] = dc_addr_list.value_ptr.items[dc_addr_list.value_ptr.items.len - 1];
            dc_addr_list.value_ptr.items[dc_addr_list.value_ptr.items.len - 1] = first;
        }
    }
}

fn tcpConnectWithTimeout(addr: std.Io.net.IpAddress, io: std.Io, connect_options: std.Io.net.IpAddress.ConnectOptions, timeout: std.Io.Timeout) std.Io.net.IpAddress.ConnectError!std.Io.net.Stream {
    // very overkill function that adds timeout, because std.io.Threaded doesn't support it right now directly

    const TaskResult = union(enum) { timeout: std.Io.Cancelable!void, ok: std.Io.net.IpAddress.ConnectError!std.Io.net.Stream };

    const Select = std.Io.Select(TaskResult);
    var buffer: [2]TaskResult = undefined;

    var select = Select.init(io, &buffer);

    select.concurrent(.ok, std.Io.net.IpAddress.connect, .{ &addr, io, connect_options }) catch @panic("concurrency unavailable");

    select.concurrent(.timeout, std.Io.Timeout.sleep, .{ timeout, io }) catch @panic("concurrency unavailable");

    const res = try select.await();

    blk: {
        const res_cancel = select.cancel() orelse break :blk;

        if (res_cancel == .ok) {
            const net = res_cancel.ok catch break :blk;
            net.close(io);
        }
    }

    if (res == .timeout) {
        return std.Io.net.IpAddress.ConnectError.Timeout;
    }

    return res.ok;
}

fn connectAddress(addr: DcAddress, mode: TransportMode, allocator: std.mem.Allocator, io: std.Io) !?TransportHolder {
    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();

    const transport = blk: {
        switch (addr.addr) {
            .tcp => |address_tcp| {
                const writeBuf = try arena.allocator().alloc(u8, 512);
                const readBuf = try arena.allocator().alloc(u8, 512);

                //const stream = try address_tcp.connect(io, .{
                //  .mode = .stream,
                // timeout is not implemented yet :(
                //.timeout = .{ .duration = .{ .raw = TIMEOUT_CONNECTION, .clock = .boot } },
                //});
                const stream = try tcpConnectWithTimeout(address_tcp, io, .{ .mode = .stream }, .{ .duration = .{ .raw = TIMEOUT_CONNECTION, .clock = .boot } });
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

pub fn connectTo(self: *TransportConnector, allocator: std.mem.Allocator, io: std.Io, dc_id: utils.DcId) !?TransportHolder {
    const maybe_holder, const i, const maybe_addr = net: {
        try self.lock.lockShared(io);
        defer self.lock.unlockShared(io);
        const addresses, const mode = blk: {
            const address = self.dc_address_map.get(dc_id) orelse return null;
            const mode = self.mode;
            break :blk .{ address, mode };
        };

        for (addresses.items, 0..) |address, i| {
            const holder = connectAddress(address, mode, allocator, io) catch |err| {
                if (err == std.Io.Cancelable.Canceled) {
                    break :net .{ err, 0, null };
                }
                continue;
            };

            break :net .{ holder, i, address };
        }

        break :net .{ std.Io.net.IpAddress.ConnectError.NetworkUnreachable, 0, null };
    };

    const holder = try maybe_holder;

    if (i > 0) {
        if (maybe_addr) |addr| {
            self.lock.lock(io) catch {
                return holder;
            };
            defer self.lock.unlock(io);

            const list = self.dc_address_map.get(dc_id) orelse return holder;

            for (list.items, 0..) |item, ix| {
                if (item.eql(addr)) {
                    const swap = list.items[0];
                    list.items[0] = addr;
                    list.items[ix] = swap;

                    return holder;
                }
            }
        }
    }

    return holder;
}

pub fn deinit(self: *TransportConnector, allocator: std.mem.Allocator, io: std.Io) void {
    self.lock.lockUncancelable(io);

    var it = self.dc_address_map.iterator();

    while (it.next()) |dc| {
        dc.value_ptr.deinit(allocator);
    }

    self.dc_address_map.deinit(allocator);
}
