const std = @import("std");

pub const Error = error{
    OpenError,
    ReadError,
    WriteError,
    InvalidDc,
} || std.mem.Allocator.Error || std.Io.Cancelable;

const utils = @import("./utils.zig");
const MemoryDcBinStorage = @import("storage/memory_dcbin.zig");

pub const Storage = union(enum) {
    pub const Enum = std.meta.Tag(Storage);

    MemoryDcBinStorage: MemoryDcBinStorage,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, mode: Enum, dst: []const u8) Error!Storage {
        switch (mode) {
            .MemoryDcBinStorage => {
                return .{ .MemoryDcBinStorage = try MemoryDcBinStorage.init(allocator, io, dst) };
            },
        }
    }

    pub fn putDC(self: *Storage, allocator: std.mem.Allocator, io: std.Io, id: utils.DcId, key: [256]u8) Error!void {
        if (!id.valid) {
            return Error.InvalidDc;
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

        switch (self.*) {
            inline else => |*x| {
                return x.getDC(io, id.int());
            },
        }
    }

    pub fn getPreferredDC(self: *Storage, io: std.Io) !?utils.DcId {
        const dc_id_int = switch (self.*) {
            inline else => |*x| x.getPreferredDC(io),
        };

        const dc_id: utils.DcId = @bitCast(try dc_id_int);

        if (!dc_id.valid) {
            return null;
        }
        return dc_id;
    }

    pub fn setPreferredDC(self: *const Storage, io: std.Io, dc_id: utils.DcId) void {
        const dc_id_int: i32 = if (!dc_id.valid) 0 else dc_id.int();

        switch (self.*) {
            inline else => |x| {
                return x.setPreferredDC(io, dc_id_int);
            },
        }
    }

    pub fn deinit(self: *Storage, allocator: std.mem.Allocator, io: std.Io) void {
        switch (self.*) {
            inline else => |*x| {
                x.deinit(allocator, io);
            },
        }
    }
};

test {
    _ = MemoryDcBinStorage;
}
