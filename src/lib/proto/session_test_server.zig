const std = @import("std");
const Transport = @import("../transport.zig").Transport;
const MT2Crypto = @import("../crypto/mt2.zig");

const SessionTestServer = @This();

dummy: *Transport.Dummy,
auth_key_id: *const [8]u8,
auth_key: *const [256]u8,
session_id: u64,
salt: u64,
next_message_id: u64 = 0x0000000100000001,
next_seqno: u32 = 0,

pub const ClientPacket = struct {
    allocator: std.mem.Allocator,
    bytes: []u8,
    header: MT2Crypto.Header,
    body: []u8,

    pub fn deinit(self: ClientPacket) void {
        self.allocator.free(self.bytes);
    }
};

pub fn init(dummy: *Transport.Dummy, auth_key_id: *const [8]u8, auth_key: *const [256]u8, session_id: u64, salt: u64) SessionTestServer {
    return .{
        .dummy = dummy,
        .auth_key_id = auth_key_id,
        .auth_key = auth_key,
        .session_id = session_id,
        .salt = salt,
    };
}

pub fn recvClientPacket(self: *SessionTestServer, io: std.Io) !ClientPacket {
    const bytes = try self.dummy.serverRecv(io);
    errdefer self.dummy.allocator.free(bytes);

    const header = try MT2Crypto.decrypt(bytes, self.auth_key_id, self.auth_key, .client_to_server);
    const body = bytes[MT2Crypto.Layout.BODY..][0..header.body_len];

    return .{
        .allocator = self.dummy.allocator,
        .bytes = bytes,
        .header = header,
        .body = body,
    };
}

pub fn sendServerBody(self: *SessionTestServer, allocator: std.mem.Allocator, io: std.Io, body: []const u8) !void {
    const message_id = self.next_message_id;
    self.next_message_id +%= 4;

    var bytes = try allocator.alloc(u8, MT2Crypto.Layout.totalLen(body.len));
    defer allocator.free(bytes);

    @memcpy(bytes[MT2Crypto.Layout.BODY..][0..body.len], body);
    try MT2Crypto.encrypt(
        io,
        bytes,
        self.auth_key_id,
        self.auth_key,
        self.salt,
        self.session_id,
        message_id,
        self.next_seqno,
        body.len,
        .server_to_client,
    );

    try self.dummy.serverWrite(io, bytes);
}

test "receives client packet and sends server packet" {
    const dummyTransport = @import("../transport_connector.zig").dummyTransport;
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var auth_key: [256]u8 = undefined;
    for (&auth_key, 0..) |*byte, i| {
        byte.* = @intCast((i * 19 + 5) % 251);
    }

    var auth_key_sha1: [20]u8 = undefined;
    std.crypto.hash.Sha1.hash(&auth_key, &auth_key_sha1, .{});
    var auth_key_id: [8]u8 = undefined;
    @memcpy(&auth_key_id, auth_key_sha1[12..20]);

    const holder, const dummy = try dummyTransport(allocator);
    defer holder.deinit(io);

    var server = SessionTestServer.init(dummy, &auth_key_id, &auth_key, 0x1122334455667788, 0x8877665544332211);

    const client_body = [_]u8{ 0x10, 0x20, 0x30, 0x40 };
    var client_packet = try allocator.alloc(u8, MT2Crypto.Layout.totalLen(client_body.len));
    defer allocator.free(client_packet);
    @memcpy(client_packet[MT2Crypto.Layout.BODY..][0..client_body.len], &client_body);
    try MT2Crypto.encrypt(io, client_packet, &auth_key_id, &auth_key, server.salt, server.session_id, 0x0000000100000000, 0, client_body.len, .client_to_server);
    try holder.transport.write(io, client_packet);

    const received = try server.recvClientPacket(io);
    defer received.deinit();
    try std.testing.expectEqual(server.salt, received.header.salt);
    try std.testing.expectEqual(server.session_id, received.header.session_id);
    try std.testing.expectEqualSlices(u8, &client_body, received.body);

    const server_body = [_]u8{ 0x44, 0x33, 0x22, 0x11 };
    try server.sendServerBody(allocator, io, &server_body);

    const server_packet_len = try holder.transport.recvLen(io);
    try std.testing.expectEqual(MT2Crypto.Layout.totalLen(server_body.len), server_packet_len);

    var server_packet = try allocator.alloc(u8, server_packet_len);
    defer allocator.free(server_packet);
    const read = try holder.transport.recv(io, server_packet);
    try std.testing.expectEqual(server_packet_len, read);

    const server_header = try MT2Crypto.decrypt(server_packet, &auth_key_id, &auth_key, .server_to_client);
    try std.testing.expectEqual(server.salt, server_header.salt);
    try std.testing.expectEqual(server.session_id, server_header.session_id);
    try std.testing.expectEqualSlices(u8, &server_body, server_packet[MT2Crypto.Layout.BODY..][0..server_header.body_len]);
}
