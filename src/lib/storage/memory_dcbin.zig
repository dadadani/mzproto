/// A Storage backend that saves peers in ram, while retaining datacenter keys in a binary file
const std = @import("std");
const Error = @import("../storage.zig").Error;
const HEADER = "mzprotodc1";

const MemoryDcBinStorage = @This();

file: std.Io.File,
datacenters: std.AutoHashMapUnmanaged(i32, [256]u8),
preferred_dc: i32,
mutex: std.Io.Mutex,

// mutex assumed to be acquired
fn write(self: *MemoryDcBinStorage, io: std.Io) Error!void {
    var writer = self.file.writer(io, &.{});

    writer.interface.writeAll(HEADER) catch {
        return Error.WriteError;
    };

    writer.interface.writeInt(i32, self.preferred_dc, .little) catch {
        return Error.WriteError;
    };

    writer.interface.writeInt(u16, @intCast(self.datacenters.size), .little) catch {
        return Error.WriteError;
    };

    var it = self.datacenters.iterator();

    while (it.next()) |dc| {
        writer.interface.writeInt(i32, dc.key_ptr.*, .little) catch {
            return Error.WriteError;
        };
        writer.interface.writeAll(dc.value_ptr) catch {
            return Error.WriteError;
        };
    }

    writer.interface.flush() catch {
        return Error.WriteError;
    };
}

pub fn init(allocator: std.mem.Allocator, io: std.Io, dst: []const u8) Error!MemoryDcBinStorage {
    var file = std.Io.Dir.cwd().createFile(io, dst, .{ .lock = .exclusive, .truncate = false, .read = true }) catch {
        return Error.OpenError;
    };
    errdefer file.close(io);

    const len = file.length(io) catch {
        return Error.OpenError;
    };

    if (len == 0) {
        return .{
            .file = file,
            .preferred_dc = 0,
            .datacenters = .{},
            .mutex = .init,
        };
    }

    var reader = file.reader(io, &.{});

    var header: [HEADER.len]u8 = undefined;
    reader.interface.readSliceAll(&header) catch {
        return Error.ReadError;
    };

    if (!std.mem.eql(u8, &header, HEADER)) {
        return Error.ReadError;
    }

    var preferred_dc_bytes: [@sizeOf(i32)]u8 = undefined;
    reader.interface.readSliceAll(&preferred_dc_bytes) catch {
        return Error.ReadError;
    };

    const preferred_dc = std.mem.readInt(i32, &preferred_dc_bytes, .little);

    var dc_len_bytes: [@sizeOf(u16)]u8 = undefined;
    reader.interface.readSliceAll(&dc_len_bytes) catch {
        return Error.ReadError;
    };

    const dc_len = std.mem.readInt(u16, &dc_len_bytes, .little);

    var hashmap = std.AutoHashMapUnmanaged(i32, [256]u8){};
    try hashmap.ensureUnusedCapacity(allocator, dc_len);
    errdefer hashmap.deinit(allocator);

    for (0..dc_len) |_| {
        var dc_id_bytes: [@sizeOf(i32)]u8 = undefined;
        reader.interface.readSliceAll(&dc_id_bytes) catch {
            return Error.ReadError;
        };
        const dc_id = std.mem.readInt(i32, &dc_id_bytes, .little);

        const dc = try hashmap.getOrPut(allocator, dc_id);

        reader.interface.readSliceAll(dc.value_ptr) catch {
            return Error.ReadError;
        };
    }

    return .{
        .file = file,
        .preferred_dc = preferred_dc,
        .datacenters = hashmap,
        .mutex = .init,
    };
}

pub fn getPreferredDC(self: *MemoryDcBinStorage, io: std.Io) !i32 {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    return self.preferred_dc;
}

pub fn setPreferredDC(self: *const MemoryDcBinStorage, io: std.Io, dc_id: i32) void {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    self.preferred_dc = dc_id;

    try self.write(io);
}

pub fn putDC(self: *MemoryDcBinStorage, allocator: std.mem.Allocator, io: std.Io, id: i32, key: [256]u8) Error!void {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    try self.datacenters.put(allocator, id, key);

    try self.write(io);
}

pub fn getDC(self: *MemoryDcBinStorage, io: std.Io, id: i32) Error!?[256]u8 {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    return self.datacenters.get(id);
}

pub fn deinit(self: *MemoryDcBinStorage, allocator: std.mem.Allocator, io: std.Io) void {
    self.file.close(io);
    self.datacenters.deinit(allocator);
}

test "test the MemoryDcBinStorage storage backend" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var storage = try MemoryDcBinStorage.init(std.testing.allocator, std.testing.io, "/tmp/mzproto_session");

    const key: [256]u8 = .{ 64, 110, 80, 233, 80, 79, 123, 23, 94, 253, 25, 30, 226, 142, 26, 241, 151, 56, 219, 124, 160, 81, 72, 72, 155, 141, 142, 211, 15, 231, 173, 26, 233, 8, 254, 234, 142, 63, 22, 119, 222, 59, 129, 172, 171, 84, 180, 202, 78, 11, 127, 36, 248, 79, 160, 253, 52, 211, 56, 108, 195, 104, 213, 178, 48, 9, 83, 41, 87, 84, 151, 246, 187, 10, 81, 78, 186, 239, 78, 133, 20, 25, 80, 59, 146, 2, 174, 229, 83, 74, 142, 221, 218, 34, 107, 234, 216, 158, 31, 197, 145, 97, 7, 160, 25, 131, 244, 94, 186, 181, 113, 253, 96, 235, 108, 155, 51, 214, 171, 188, 243, 40, 218, 71, 116, 20, 222, 97, 62, 149, 134, 143, 12, 89, 228, 102, 144, 234, 240, 80, 39, 56, 0, 30, 223, 87, 231, 137, 60, 133, 106, 100, 166, 151, 64, 40, 202, 86, 13, 156, 23, 120, 130, 56, 148, 79, 145, 96, 11, 174, 125, 255, 5, 170, 6, 255, 234, 223, 16, 45, 154, 221, 175, 201, 76, 91, 202, 148, 167, 152, 102, 118, 75, 165, 130, 224, 31, 77, 149, 127, 12, 36, 154, 73, 212, 84, 31, 35, 137, 117, 31, 203, 182, 140, 39, 209, 87, 56, 230, 59, 131, 238, 203, 237, 222, 55, 85, 196, 44, 76, 117, 126, 122, 54, 47, 71, 40, 91, 111, 113, 37, 243, 39, 54, 16, 131, 1, 25, 188, 220, 243, 101, 199, 236, 225, 2 };
    const key2: [256]u8 = .{ 200, 200, 80, 233, 200, 200, 200, 23, 94, 253, 25, 200, 226, 142, 26, 241, 151, 56, 219, 124, 160, 81, 72, 72, 155, 141, 142, 211, 15, 231, 173, 26, 233, 8, 254, 234, 142, 63, 22, 119, 222, 59, 129, 172, 171, 84, 180, 202, 78, 11, 127, 36, 248, 79, 160, 253, 52, 211, 56, 108, 195, 104, 213, 178, 48, 9, 83, 41, 87, 84, 151, 246, 187, 10, 81, 78, 186, 239, 78, 133, 20, 25, 80, 59, 146, 2, 174, 229, 83, 74, 142, 221, 218, 34, 107, 234, 216, 158, 31, 197, 145, 97, 7, 160, 25, 131, 244, 94, 186, 181, 113, 253, 96, 235, 108, 155, 51, 214, 171, 188, 243, 40, 218, 71, 116, 20, 222, 97, 62, 149, 134, 143, 12, 89, 228, 102, 144, 234, 240, 80, 39, 56, 0, 30, 223, 87, 231, 137, 60, 133, 106, 100, 166, 151, 64, 40, 202, 86, 13, 156, 23, 120, 130, 56, 148, 79, 145, 96, 11, 174, 125, 255, 5, 170, 6, 255, 234, 223, 16, 45, 154, 221, 175, 201, 76, 91, 202, 148, 167, 152, 102, 118, 75, 165, 130, 224, 31, 77, 149, 127, 12, 36, 154, 73, 212, 84, 31, 35, 137, 117, 31, 203, 182, 140, 39, 209, 87, 56, 230, 59, 131, 210, 203, 237, 222, 55, 85, 196, 44, 76, 117, 126, 122, 54, 47, 71, 40, 91, 111, 113, 37, 243, 39, 54, 16, 131, 1, 25, 188, 220, 243, 101, 199, 236, 225, 193 };

    try storage.putDC(allocator, io, 1004, key);
    try storage.putDC(allocator, io, 10, key2);

    try std.testing.expectEqualSlices(u8, &key, &(try storage.getDC(io, 1004)).?);
    try std.testing.expectEqualSlices(u8, &key2, &(try storage.getDC(io, 10)).?);

    storage.deinit(allocator, io);

    storage = try MemoryDcBinStorage.init(std.testing.allocator, std.testing.io, "/tmp/mzproto_session");
    try std.testing.expectEqualSlices(u8, &key, &(try storage.getDC(io, 1004)).?);
    try std.testing.expectEqualSlices(u8, &key2, &(try storage.getDC(io, 10)).?);

    storage.deinit(allocator, io);
}
