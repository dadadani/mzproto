const std = @import("std");
const Client = @This();
const Storage = @import("./storage.zig").Storage;
const CompileOptions = @import("mzproto_options");
const Transport = @import("./transport.zig").Transport;
const AuthKey = @import("./proto/auth_key.zig");
const Session = @import("./proto/session.zig");
const utils = @import("./utils.zig");
const TransportConnector = @import("./transport_connector.zig");

const log = std.log.scoped(.mzproto_client);

pub const Config = struct {
    testmode: bool = false,
    storage_backend: Storage.Enum = .MemoryDcBinStorage,
    storage_dst: []const u8,
};

current_dc: i32,
use_testmode: bool,
allocator: std.mem.Allocator,
storage: Storage,
io: std.Io,
ready: std.Io.Event = .unset,
init_future: std.Io.Future(@typeInfo(initBackground).@"fn".return_type.?),
transport_mode: Transport.Enum = .Abridged,
sessions_map: std.AutoHashMapUnmanaged(i32, *Session),
connector: TransportConnector,

/// prepares a session to be used. if there isn't a permanent key registered, a new one will be created
fn initDcSession(self: *Client, dc: utils.DcId) !void {
    const dc_to_use = dc.tcp;

    log.debug("initializing session - dc{d}, testmode: {}, media: {}", .{ dc_to_use.id, dc_to_use.testmode, dc_to_use.media });

    const perm_key, const salt = key: {
        if (try self.storage.getDC(self.io, dc)) |perm_key| {
            break :key .{ perm_key, 0 };
        }

        log.debug("generating new perm_key - dc{d}, testmode: {}, media: {}", .{ dc_to_use.id, dc_to_use.testmode, dc_to_use.media });
        const transport = (try self.connector.connectTo(self.allocator, self.io, dc)).?;
        defer transport.deinit(self.io);

        const gen_key = try AuthKey.generate(self.allocator, self.io, &transport, dc_to_use.id, dc.tcp.media, dc.tcp.testmode, false);

        try self.storage.putDC(self.allocator, self.io, dc, gen_key.auth_key);

        break :key .{ gen_key.auth_key, .gen_key.salt };
    };


    // const session = try self.allocator.create();
}

pub fn initBackground(self: *Config) !void {}

pub fn init(allocator: std.mem.Allocator, io: std.Io, config: *const Config) !*Client {
    log.info("mzproto version {s}", .{CompileOptions.version});

    // TODO: implement support for other transports (websockets, http)
    var connector = TransportConnector.init(allocator, .tcp);
    errdefer connector.deinit(allocator);

    var storage = try Storage.init(allocator, io, config.storage_backend, config.storage_dst);
    errdefer storage.deinit(allocator, io);

    const dc_id = dc: {
        if (storage.getPreferredDC()) |preferred_dc| {
            if (connector.isAvailable(preferred_dc)) {
                break :dc preferred_dc;
            }

            break :dc connector.pickFirstDc(preferred_dc.testmode);
        }

        break :dc connector.pickFirstDc(config.testmode);
    };

    const self = try allocator.create(Client);
    errdefer allocator.destroy(self);

    self.* = .{
        .allocator = allocator,
        .io = io,
        .current_dc = dc_id,
        .use_testmode = config.testmode,
        .storage = storage,
    };

    self.init_future = try std.Io.concurrent(io, initBackground, .{self});

    return self;
}
