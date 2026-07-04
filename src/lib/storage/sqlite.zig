const std = @import("std");
const sqlite = @import("sqlite");
const storage = @import("../storage.zig");
const Error = storage.Error;

const SqliteStorage = @This();

db: sqlite.Db,
mutex: std.Io.Mutex = .init,

const schema =
    \\PRAGMA foreign_keys = ON;
    \\CREATE TABLE IF NOT EXISTS metadata(key TEXT PRIMARY KEY, value INTEGER NOT NULL);
    \\CREATE TABLE IF NOT EXISTS datacenters(id INTEGER PRIMARY KEY, auth_key BLOB NOT NULL CHECK(length(auth_key)=256));
    \\CREATE TABLE IF NOT EXISTS common_update_state(singleton INTEGER PRIMARY KEY CHECK(singleton=1), pts INTEGER NOT NULL, qts INTEGER NOT NULL, date INTEGER NOT NULL, seq INTEGER NOT NULL);
    \\CREATE TABLE IF NOT EXISTS channel_update_state(channel_id INTEGER PRIMARY KEY, pts INTEGER NOT NULL);
    \\CREATE TABLE IF NOT EXISTS peers(kind INTEGER NOT NULL, id INTEGER NOT NULL, access_hash INTEGER, hash_is_min INTEGER NOT NULL, layer INTEGER NOT NULL, constructor BLOB NOT NULL, PRIMARY KEY(kind,id));
    \\INSERT INTO metadata(key,value) VALUES('schema_version',1) ON CONFLICT(key) DO UPDATE SET value=excluded.value;
;

pub fn init(allocator: std.mem.Allocator, io: std.Io, dst: []const u8) Error!SqliteStorage {
    std.Io.Dir.cwd().createDirPath(io, dst) catch return Error.OpenError;
    const path = std.fs.path.joinZ(allocator, &.{ dst, "mzproto.sqlite" }) catch return Error.OutOfMemory;
    defer allocator.free(path);

    var db = sqlite.Db.init(.{
        .mode = .{ .File = path },
        .open_flags = .{ .write = true, .create = true },
        .threading_mode = .MultiThread,
    }) catch return Error.OpenError;
    errdefer db.deinit();
    _ = db.one([16:0]u8, "PRAGMA journal_mode = WAL", .{}, .{}) catch return Error.WriteError;
    db.execMulti(schema, .{}) catch return Error.WriteError;
    return .{ .db = db };
}

pub fn deinit(self: *SqliteStorage, allocator: std.mem.Allocator, io: std.Io) void {
    _ = allocator;
    _ = io;
    self.db.deinit();
}

pub fn putDC(self: *SqliteStorage, allocator: std.mem.Allocator, io: std.Io, id: i32, key: [256]u8) Error!void {
    _ = allocator;
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);
    self.db.exec("INSERT INTO datacenters(id,auth_key) VALUES(?,?) ON CONFLICT(id) DO UPDATE SET auth_key=excluded.auth_key", .{}, .{ id, sqlite.Blob{ .data = &key } }) catch return Error.WriteError;
}

pub fn getDC(self: *SqliteStorage, io: std.Io, id: i32) Error!?[256]u8 {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);
    return self.db.one([256]u8, "SELECT auth_key FROM datacenters WHERE id=?", .{}, .{id}) catch return Error.ReadError;
}

pub fn getPreferredDC(self: *SqliteStorage, io: std.Io) Error!i32 {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);
    return (self.db.one(i32, "SELECT value FROM metadata WHERE key='preferred_dc'", .{}, .{}) catch return Error.ReadError) orelse 0;
}

pub fn setPreferredDC(self: *SqliteStorage, io: std.Io, dc_id: i32) Error!void {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);
    self.db.exec("INSERT INTO metadata(key,value) VALUES('preferred_dc',?) ON CONFLICT(key) DO UPDATE SET value=excluded.value", .{}, .{dc_id}) catch return Error.WriteError;
}

pub fn getCommonUpdateState(self: *SqliteStorage, allocator: std.mem.Allocator, io: std.Io) Error!?storage.CommonUpdateState {
    _ = allocator;
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);
    return self.db.one(storage.CommonUpdateState, "SELECT pts,qts,date,seq FROM common_update_state WHERE singleton=1", .{}, .{}) catch return Error.ReadError;
}

pub fn putCommonUpdateState(self: *SqliteStorage, io: std.Io, state: storage.CommonUpdateState) Error!void {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);
    self.db.exec("INSERT INTO common_update_state(singleton,pts,qts,date,seq) VALUES(1,?,?,?,?) ON CONFLICT(singleton) DO UPDATE SET pts=excluded.pts,qts=excluded.qts,date=excluded.date,seq=excluded.seq", .{}, state) catch return Error.WriteError;
}

pub fn getChannelUpdateState(self: *SqliteStorage, io: std.Io, channel_id: u64) Error!?storage.ChannelUpdateState {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);
    return self.db.one(storage.ChannelUpdateState, "SELECT channel_id,pts FROM channel_update_state WHERE channel_id=?", .{}, .{@as(i64, @intCast(channel_id))}) catch return Error.ReadError;
}

pub fn putChannelUpdateState(self: *SqliteStorage, io: std.Io, state: storage.ChannelUpdateState) Error!void {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);
    self.db.exec("INSERT INTO channel_update_state(channel_id,pts) VALUES(?,?) ON CONFLICT(channel_id) DO UPDATE SET pts=excluded.pts", .{}, .{ @as(i64, @intCast(state.channel_id)), state.pts }) catch return Error.WriteError;
}

pub fn putPeer(self: *SqliteStorage, io: std.Io, peer: storage.PeerRecord) Error!void {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);
    self.db.exec(
        "INSERT INTO peers(kind,id,access_hash,hash_is_min,layer,constructor) VALUES(?,?,?,?,?,?) ON CONFLICT(kind,id) DO UPDATE SET access_hash=CASE WHEN peers.access_hash IS NULL OR peers.hash_is_min=1 OR excluded.hash_is_min=0 THEN excluded.access_hash ELSE peers.access_hash END, hash_is_min=CASE WHEN peers.access_hash IS NULL OR peers.hash_is_min=1 OR excluded.hash_is_min=0 THEN excluded.hash_is_min ELSE peers.hash_is_min END, layer=excluded.layer, constructor=excluded.constructor",
        .{},
        .{ @intFromEnum(peer.kind), @as(i64, @intCast(peer.id)), peer.access_hash, peer.access_hash_is_min, peer.layer, sqlite.Blob{ .data = peer.constructor } },
    ) catch return Error.WriteError;
}

test "sqlite storage persists protocol state across restarts" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    tmp = tmp;
    //defer tmp.cleanup();

    var path_buf: [1024]u8 = undefined;

    const path_len = try std.Io.Dir.realPath(tmp.dir, io, &path_buf);

    const dir = path_buf[0..path_len];
    std.log.err("dir: {s}", .{dir});

    var backend = try init(allocator, io, dir);
    var key: [256]u8 = undefined;
    for (&key, 0..) |*byte, i| byte.* = @truncate(i);
    try backend.putDC(allocator, io, 2, key);
    try backend.setPreferredDC(io, 2);
    try backend.putCommonUpdateState(io, .{ .pts = 10, .qts = 11, .date = 12, .seq = 13 });
    try backend.putChannelUpdateState(io, .{ .channel_id = 99, .pts = 20 });
    backend.deinit(allocator, io);

    backend = try init(allocator, io, dir);
    defer backend.deinit(allocator, io);
    try std.testing.expectEqualSlices(u8, &key, &(try backend.getDC(io, 2)).?);
    try std.testing.expectEqual(@as(i32, 2), try backend.getPreferredDC(io));
    try std.testing.expectEqual(storage.CommonUpdateState{ .pts = 10, .qts = 11, .date = 12, .seq = 13 }, (try backend.getCommonUpdateState(allocator, io)).?);
    try std.testing.expectEqual(storage.ChannelUpdateState{ .channel_id = 99, .pts = 20 }, (try backend.getChannelUpdateState(io, 99)).?);
    try std.testing.expectEqual(@as(i32, 1), (try backend.db.one(i32, "SELECT value FROM metadata WHERE key='schema_version'", .{}, .{})).?);
    try std.testing.expectEqual(@as(i32, 0), (try backend.db.one(i32, "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='pending_updates'", .{}, .{})).?);
}
