const std = @import("std");
const Client = @This();
const ClientManager = @import("./client_manager.zig");
const Dispatcher = @import("./proto/dispatcher.zig");
const Storage = @import("./storage.zig").Storage;
const CompileOptions = @import("mzproto_options");
const Transport = @import("./transport.zig").Transport;
const AuthKey = @import("./proto/auth_key.zig");
const Session = @import("./proto/session.zig");
const utils = @import("./utils.zig");
const TransportConnector = @import("./transport_connector.zig");

const log = std.log.scoped(.mzproto_client);

pub const Config = struct {
    api_id: u32,
    api_hash: []const u8,

    app_version: []const u8 = "unknown",
    device_model: []const u8 = "unknown",
    system_version: []const u8 = "0.0.0",

    lang_code: ?[]const u8 = null,

    testmode: bool = false,

    add_branding: bool = true,

    storage_backend: Storage.Enum = .MemoryDcBinStorage,
    storage_dst: []const u8,
};

client_manager: ClientManager,

pub fn init(allocator: std.mem.Allocator, io: std.Io, config: *const Config) !*Client {
    log.info("mzproto version {s}", .{CompileOptions.VERSION});

    // TODO: implement support for other transports (websockets, http)
    var connector = try TransportConnector.init(allocator, .tcp, .Abridged);
    errdefer connector.deinit(allocator, io);

    var storage = try Storage.init(allocator, io, config.storage_backend, config.storage_dst);
    errdefer storage.deinit(allocator, io);

    const dc_id, const dc_switch_when_ready: ?utils.DcId = dc: {
        if (try storage.getPreferredDC(io)) |preferred_dc| {
            if (connector.isAvailable(io, preferred_dc)) {
                break :dc .{ preferred_dc, null };
            }

            break :dc .{ connector.pickFirstDc(io, preferred_dc.testmode), preferred_dc };
        }

        break :dc .{ connector.pickFirstDc(io, config.testmode), null };
    };

    const self = try allocator.create(Client);
    errdefer allocator.destroy(self);

    const api_hash = try allocator.dupe(u8, config.api_hash);
    errdefer allocator.free(api_hash);

    const app_version = if (config.add_branding) try std.fmt.allocPrint(allocator, "{s} (mzproto {s})", .{ config.app_version, CompileOptions.VERSION }) else try allocator.dupe(u8, config.app_version);
    errdefer allocator.free(app_version);

    const device_model = try allocator.dupe(u8, config.device_model);
    errdefer allocator.free(device_model);

    const system_version = try allocator.dupe(u8, config.system_version);
    errdefer allocator.free(system_version);

    const lang_code = if (config.lang_code) |lang_code|
        try allocator.dupe(u8, lang_code)
    else
        // TODO: get language from system automatically
        try allocator.dupe(u8, "en");
    errdefer allocator.free(lang_code);

    const system_lang_code = try allocator.dupe(u8, lang_code);
    errdefer allocator.free(system_lang_code);

    //TODO: figure out language packs
    const lang_pack = try allocator.dupe(u8, "");
    errdefer allocator.free(lang_pack);

    self.* = .{
        .client_manager = .{
            .session_info = .{
                .api_id = config.api_id,
                .api_hash = api_hash,
                .app_version = app_version,
                .device_model = device_model,
                .system_version = system_version,
                .lang_code = lang_code,
                .system_lang_code = system_lang_code,
                .lang_pack = lang_pack,
            },
            .internal = .{
                .current_dc = dc_id,
                .target_dc = dc_switch_when_ready,
            },
            .dispatcher = undefined,

            .storage = storage,
            .transport_connector = connector,
        },
    };

    self.client_manager.dispatcher = .{
        .client_manager = &self.client_manager,
        .connector = &self.client_manager.transport_connector,
        .main_dc = dc_id,
        .storage = &self.client_manager.storage,
    };

    const r = try self.client_manager.probeLoggedIn(allocator, io);
    std.debug.print("aaar: {}", .{r});
    return self;
}

pub fn deinit(self: *Client, allocator: std.mem.Allocator, io: std.Io) void {
    log.info("Shutting down", .{});
    self.client_manager.deinit(allocator, io);
    allocator.destroy(self);
}
