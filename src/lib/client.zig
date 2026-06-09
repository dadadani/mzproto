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
const bapi = @import("mzproto_bridge");

const log = std.log.scoped(.mzproto_client);

pub const Config = struct {
    api_id: u32,
    api_hash: []const u8,

    app_version: []const u8 = "unknown",
    device_model: []const u8 = "unknown",
    system_version: []const u8 = "0.0.0",

    lang_code: ?[]const u8 = null,

    testmode: bool = false,
    enable_ipv6: bool = true,
    enable_ipv4: bool = true,

    add_branding: bool = true,

    storage_backend: Storage.Enum = .MemoryDcBinStorage,
    storage_dst: []const u8,
};

fn storageBackend(orig: bapi.StorageBackend) Storage.Enum {
    return switch (orig) {
        .memory_dc_bin_storage => Storage.Enum.MemoryDcBinStorage,
    };
}

allocator: std.mem.Allocator,
io: std.Io,
client_manager: ClientManager,
group: std.Io.Group = .init,
terminated: std.atomic.Value(bool) = .init(false),

pub fn checkWorker(self: *Client, allocator: std.mem.Allocator, io: std.Io) std.Io.Cancelable!void {
    while (true) {
        const timeout: std.Io.Timeout = .{ .duration = .{ .raw = .fromSeconds(30), .clock = .boot } };
        try timeout.sleep(io);

        self.client_manager.dispatcher.check(allocator, io) catch |err| {
            if (err == std.Io.Cancelable.Canceled) {
                return;
            }
            log.warn("dispatcher.check failed: {s}", .{@errorName(err)});
            continue;
        };
    }
}

pub fn backgroundInit(self: *Client, allocator: std.mem.Allocator, io: std.Io, stored_auth_key: bool) std.Io.Cancelable!void {
    self.client_manager.pushClientStatus(allocator, io, .starting);
    const retry: std.Io.Timeout = .{ .duration = .{ .raw = .fromSeconds(1), .clock = .boot } };
    {
        const status: ?bapi.ClientStatus = status: {
            if (stored_auth_key) {
                const logged_in = brk: while (true) {
                    // this is required because otherwise `probeLoggedIn` would get stuck waiting for the dispatcher to switch to the dc it needs
                    self.client_manager.dispatcher.ignite(allocator, io) catch |err| {
                        if (err == std.Io.Cancelable.Canceled) {
                            return std.Io.Cancelable.Canceled;
                        }
                        log.warn("Failed to ignite dispatcher: {s} - Retrying in 1 sec", .{@errorName(err)});
                        try retry.sleep(io);
                        continue;
                    };
                    const logged_in = self.client_manager.probeLoggedIn(allocator, io) catch |err| {
                        if (err == std.Io.Cancelable.Canceled) {
                            return std.Io.Cancelable.Canceled;
                        }
                        log.warn("Failed to ignite dispatcher: {s} - Retrying in 1 sec", .{@errorName(err)});
                        try retry.sleep(io);
                        continue;
                    };
                    break :brk logged_in;
                };
                if (logged_in) {
                    break :status .ready;
                } else {
                    break :status .waiting_authorization;
                }
            } else {
                break :status .waiting_authorization;
            }
        };

        if (status) |stat| {
            self.client_manager.pushClientStatus(allocator, io, stat);
        }
    }

    //
}

pub fn init(allocator: std.mem.Allocator, io: std.Io, config: bapi.ConstRefConfig) !*Client {
    log.info("mzproto version {s}", .{CompileOptions.VERSION});

    const enable_ipv6 = (try config.getEnableIpv6()) orelse true;
    const enable_ipv4 = (try config.getEnableIpv4()) orelse true;

    const storage_backend = storageBackend(try config.getStorageBackend());

    // TODO: implement support for other transports (websockets, http)
    var connector = try TransportConnector.init(allocator, .tcp, .Abridged, enable_ipv6, enable_ipv4);
    errdefer connector.deinit(allocator, io);

    const storage_dst = try (try config.getStoragePath()).getUTF8(allocator);
    defer {
        if (bapi.PREFERRED_STRING_ENCODING != .utf8 or !bapi.STRINGS_ARE_NO_COPY) {
            allocator.free(storage_dst);
        }
    }
    log.debug("init storage", .{});

    var storage = try Storage.init(allocator, io, storage_backend, storage_dst);
    errdefer storage.deinit(allocator, io);

    const dc_id, const dc_switch_when_ready: ?utils.DcId, const stored_auth_key = dc: {
        if (try storage.getPreferredDC(io)) |preferred_dc| {
            if (connector.isAvailable(io, preferred_dc)) {
                break :dc .{ preferred_dc, null, true };
            }

            break :dc .{ connector.pickFirstDc(io, preferred_dc.testmode), preferred_dc, true };
        }

        break :dc .{ connector.pickFirstDc(io, (try config.getTestmode()) orelse false), null, false };
    };

    const self = try allocator.create(Client);
    errdefer allocator.destroy(self);

    const api_hash = try (try config.getApiHash()).getUTF8Copy(allocator);
    errdefer allocator.free(api_hash);

    const app_version = blk: {
        const add_branding = try config.getAddBranding();
        if (add_branding orelse true) {
            const version = try (try config.getAppVersion()).getUTF8Copy(allocator);
            defer allocator.free(version);
            break :blk try std.fmt.allocPrint(allocator, "{s} (mzproto {s})", .{ version, CompileOptions.VERSION });
        }
        const version = try (try config.getAppVersion()).getUTF8Copy(allocator);
        break :blk version;
    };
    errdefer allocator.free(app_version);

    //const app_version = if (config.add_branding) try std.fmt.allocPrint(allocator, "{s} (mzproto {s})", .{ config.app_version, CompileOptions.VERSION }) else try allocator.dupe(u8, config.app_version);
    //errdefer allocator.free(app_version);

    const device_model = try (try config.getDeviceModel()).getUTF8Copy(allocator);
    errdefer allocator.free(device_model);

    const system_version = try (try config.getSystemVersion()).getUTF8Copy(allocator);
    errdefer allocator.free(system_version);

    const lang_code = blk: {
        if (try config.getSystemLanguage()) |lang_code| {
            break :blk try lang_code.getUTF8Copy(allocator);
        }
        // TODO: get language from system automatically
        break :blk try allocator.dupe(u8, "en");
    };
    errdefer allocator.free(lang_code);

    const system_lang_code = try allocator.dupe(u8, lang_code);
    errdefer allocator.free(system_lang_code);

    //TODO: figure out language packs
    const lang_pack = try allocator.dupe(u8, "");
    errdefer allocator.free(lang_pack);
    log.debug("self define", .{});

    self.* = .{
        .allocator = allocator,
        .io = io,
        .client_manager = .{ .session_info = .{
            .api_id = try config.getApiId(),
            .api_hash = api_hash,
            .app_version = app_version,
            .device_model = device_model,
            .system_version = system_version,
            .lang_code = lang_code,
            .system_lang_code = system_lang_code,
            .lang_pack = lang_pack,
        }, .internal = .{
            .current_dc = dc_id,
            .target_dc = dc_switch_when_ready,
            .switch_dc_event = if (dc_switch_when_ready == null) .is_set else .unset,
            .client_status = .starting,
        }, .dispatcher = undefined, .storage = storage, .transport_connector = connector, .updates_manager = undefined },
    };

    self.client_manager.dispatcher = .{
        .client_manager = &self.client_manager,
        .connector = &self.client_manager.transport_connector,
        .main_dc = dc_id,
        .storage = &self.client_manager.storage,
    };

    self.client_manager.updates_manager.init();

    log.debug("initalizing worker group", .{});

    try self.group.concurrent(io, backgroundInit, .{ self, allocator, io, stored_auth_key });
    try self.group.concurrent(io, checkWorker, .{ self, allocator, io });
    return self;
}

pub fn terminate(self: *Client, comptime is_deinit: bool) void {
    if (self.terminated.load(.acquire)) return;

    log.info("Terminating", .{});
    self.terminated.store(true, .release);
    if (!is_deinit) {
        self.client_manager.pushClientStatus(self.allocator, self.io, .terminating);
    }
    log.debug("canceling worker group", .{});
    self.group.cancel(self.io);
    log.debug("deinit client manager", .{});
    self.client_manager.deinit(self.allocator, self.io, if (is_deinit) true else false);
}

pub fn deinit(self: *Client) void {
    log.info("Shutting down", .{});

    self.terminate(true);
    log.debug("deinit self", .{});
    self.allocator.destroy(self);
    log.debug("done", .{});
}
