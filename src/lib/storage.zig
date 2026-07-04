const std = @import("std");
const MzprotoOptions = @import("mzproto_options");
pub const Error = error{
    OpenError,
    ReadError,
    WriteError,
    InvalidDc,
} || std.mem.Allocator.Error || std.Io.Cancelable;

const utils = @import("./utils.zig");
const MemoryDcBinStorage = @import("storage/memory_dcbin.zig");

const CommonUpdateState = @import("update_ordering.zig").CommonState;

const Peers = @import("./peers.zig");

pub const Storage = union(enum) {
    pub const Enum = std.meta.Tag(Storage);

    MemoryDcBinStorage: MemoryDcBinStorage,
    SqliteStorage: if (MzprotoOptions.ENABLE_SQLITE) @import("./storage/sqlite.zig") else void,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, mode: Enum, dst: []const u8) Error!Storage {
        switch (mode) {
            .MemoryDcBinStorage => {
                return .{ .MemoryDcBinStorage = try MemoryDcBinStorage.init(allocator, io, dst) };
            },
            .SqliteStorage => {
                if (!MzprotoOptions.ENABLE_SQLITE) {
                    @panic("sqlite not enabled in this build");
                }
                return .{ .SqliteStorage = try @import("./storage/sqlite.zig").init(allocator, io, dst) };
            },
        }
    }

    pub fn putDC(self: *Storage, allocator: std.mem.Allocator, io: std.Io, id: utils.DcId, key: [256]u8) Error!void {
        if (!id.valid) {
            return Error.InvalidDc;
        }

        if (!MzprotoOptions.ENABLE_SQLITE and self.* == .SqliteStorage) {
            unreachable;
        }

        switch (self.*) {
            inline else => |*x| {
                return x.putDC(allocator, io, id.int(), key);
            },
        }
    }

    pub fn getDC(self: *Storage, io: std.Io, id: utils.DcId) Error!?[256]u8 {
        if (!id.valid) {
            return Error.InvalidDc;
        }

        if (!MzprotoOptions.ENABLE_SQLITE and self.* == .SqliteStorage) {
            unreachable;
        }

        switch (self.*) {
            inline else => |*x| {
                return x.getDC(io, id.int());
            },
        }
    }

    pub fn getPreferredDC(self: *Storage, io: std.Io) !?utils.DcId {
        if (!MzprotoOptions.ENABLE_SQLITE and self.* == .SqliteStorage) {
            unreachable;
        }

        const dc_id_int = switch (self.*) {
            inline else => |*x| x.getPreferredDC(io),
        };

        const dc_id: utils.DcId = @bitCast(try dc_id_int);

        if (!dc_id.valid) {
            return null;
        }
        return dc_id;
    }

    pub fn setPreferredDC(self: *Storage, io: std.Io, dc_id: utils.DcId) Error!void {
        if (!MzprotoOptions.ENABLE_SQLITE and self.* == .SqliteStorage) {
            unreachable;
        }

        const dc_id_int: i32 = if (!dc_id.valid) 0 else dc_id.int();

        switch (self.*) {
            inline else => |*x| {
                return x.setPreferredDC(io, dc_id_int);
            },
        }
    }

    pub fn getCommonUpdateState(self: *Storage, allocator: std.mem.Allocator, io: std.Io) Error!?CommonUpdateState {
        return switch (self.*) {
            .SqliteStorage => |*x| if (MzprotoOptions.ENABLE_SQLITE) x.getCommonUpdateState(allocator, io) else unreachable,
            .MemoryDcBinStorage => null,
        };
    }

    pub fn putCommonUpdateState(self: *Storage, io: std.Io, state: CommonUpdateState) Error!void {
        switch (self.*) {
            .SqliteStorage => |*x| if (MzprotoOptions.ENABLE_SQLITE) try x.putCommonUpdateState(io, state) else unreachable,
            .MemoryDcBinStorage => {},
        }
    }

    pub fn getChannelUpdateState(self: *Storage, io: std.Io, channel_id: u64) Error!?Peers.ChannelUpdateState {
        return switch (self.*) {
            .SqliteStorage => |*x| if (MzprotoOptions.ENABLE_SQLITE) x.getChannelUpdateState(io, channel_id) else unreachable,
            .MemoryDcBinStorage => null,
        };
    }

    pub fn putChannelUpdateState(self: *Storage, io: std.Io, state: Peers.ChannelUpdateState) Error!void {
        switch (self.*) {
            .SqliteStorage => |*x| if (MzprotoOptions.ENABLE_SQLITE) try x.putChannelUpdateState(io, state) else unreachable,
            .MemoryDcBinStorage => {},
        }
    }

    pub fn putPeer(self: *Storage, io: std.Io, peer: Peers.PeerRecord) Error!void {
        switch (self.*) {
            .SqliteStorage => |*x| if (MzprotoOptions.ENABLE_SQLITE) try x.putPeer(io, peer) else unreachable,
            .MemoryDcBinStorage => {},
        }
    }

    pub fn deinit(self: *Storage, allocator: std.mem.Allocator, io: std.Io) void {
        if (!MzprotoOptions.ENABLE_SQLITE and self.* == .SqliteStorage) {
            unreachable;
        }

        switch (self.*) {
            inline else => |*x| {
                x.deinit(allocator, io);
            },
        }
    }
};

test {
    _ = MemoryDcBinStorage;
    if (MzprotoOptions.ENABLE_SQLITE) _ = @import("storage/sqlite.zig");
}
