const std = @import("std");
const ige = @import("../crypto/ige.zig").ige;

pub const Layout = struct {
    pub const AUTH_KEY_ID = 0;
    pub const MSG_KEY = AUTH_KEY_ID + 8;
    pub const SALT = MSG_KEY + 16;
    pub const SESSION_ID = SALT + 8;
    pub const MESSAGE_ID = SESSION_ID + 8;
    pub const SEQNO = MESSAGE_ID + 8;
    pub const BODY_LEN = SEQNO + 4;
    pub const BODY = BODY_LEN + 4;

    pub const ENCRYPTED_PAYLOAD = SALT;

    pub inline fn paddingOffset(body_len: usize) usize {
        return BODY + body_len;
    }

    pub inline fn encryptedPayloadLen(body_len: usize) usize {
        return paddingOffset(body_len) - ENCRYPTED_PAYLOAD;
    }

    pub inline fn paddingLen(body_len: usize) usize {
        return determinePadding(encryptedPayloadLen(body_len));
    }

    pub inline fn totalLen(body_len: usize) usize {
        return paddingOffset(body_len) + paddingLen(body_len);
    }
};

pub const Direction = enum {
    client_to_server,
    server_to_client,

    /// Returns the MTProto 2.0 KDF offset for this message direction.
    inline fn keyOffset(self: Direction) usize {
        return switch (self) {
            .client_to_server => 0,
            .server_to_client => 8,
        };
    }
};

pub const Header = struct {
    salt: u64,
    session_id: u64,
    message_id: u64,
    seqno: u32,
    body_len: usize,
};

pub const Error = error{
    AuthKeyMismatch,
    MsgKeyMismatch,
    PaddingMismatch,
    InvalidMsgLength,
};

/// Returns the MTProto 2.0 padding length for an encrypted payload length.
pub inline fn determinePadding(len: usize) usize {
    // Padding must be 12-1024 bytes, total length divisible by 16.
    const remainder = (len + 12) % 16;
    return if (remainder == 0) 12 else 12 + (16 - remainder);
}

/// Derives the AES key and IV from the auth key, message key, and direction.
fn kdf(auth_key: *const [256]u8, msg_key: []const u8, comptime direction: Direction) struct { key: [32]u8, iv: [32]u8 } {
    std.debug.assert(msg_key.len == 16);

    const x = direction.keyOffset();

    var digest = std.crypto.hash.sha2.Sha256.init(.{});
    var a: [32]u8 = undefined;
    digest.update(msg_key);
    digest.update(auth_key[x .. x + 36]);
    digest.final(&a);

    var b: [32]u8 = undefined;
    digest = .init(.{});
    digest.update(auth_key[40 + x .. 76 + x]);
    digest.update(msg_key);
    digest.final(&b);

    var key: [32]u8 = undefined;
    @memcpy(key[0..8], a[0..8]);
    @memcpy(key[8 .. 8 + 16], b[8..24]);
    @memcpy(key[8 + 16 .. 8 + 16 + 8], a[24..32]);

    var iv: [32]u8 = undefined;
    @memcpy(iv[0..8], b[0..8]);
    @memcpy(iv[8 .. 8 + 16], a[8..24]);
    @memcpy(iv[8 + 16 .. 8 + 16 + 8], b[24..32]);

    return .{ .key = key, .iv = iv };
}

/// Computes the 128-bit MTProto 2.0 message key for the encrypted payload.
fn msgKey(auth_key: *const [256]u8, encrypted_payload: []const u8, comptime direction: Direction) [16]u8 {
    const x = direction.keyOffset();
    var digest = std.crypto.hash.sha2.Sha256.init(.{});
    digest.update(auth_key[88 + x .. 120 + x]);
    digest.update(encrypted_payload);

    var result: [16]u8 = undefined;
    @memcpy(&result, digest.finalResult()[8..24]);
    return result;
}

/// Writes the encrypted-message header, pads, calculates msg_key, and encrypts the payload in place.
pub fn encrypt(
    io: std.Io,
    data: []u8,
    auth_key_id: *const [8]u8,
    auth_key: *const [256]u8,
    salt: u64,
    session_id: u64,
    message_id: u64,
    seqno: u32,
    body_len: usize,
    comptime direction: Direction,
) !void {
    const offset_padding = Layout.paddingOffset(body_len);
    const padding = Layout.paddingLen(body_len);
    if (data.len < offset_padding + padding) {
        return Error.InvalidMsgLength;
    }

    std.mem.writeInt(u64, data[Layout.SALT..Layout.SESSION_ID], salt, .little);
    std.mem.writeInt(u64, data[Layout.SESSION_ID..Layout.MESSAGE_ID], session_id, .little);
    std.mem.writeInt(u64, data[Layout.MESSAGE_ID..Layout.SEQNO], message_id, .little);
    std.mem.writeInt(u32, data[Layout.SEQNO..Layout.BODY_LEN], seqno, .little);
    std.mem.writeInt(u32, data[Layout.BODY_LEN..Layout.BODY], @intCast(body_len), .little);
    try std.Io.randomSecure(io, data[offset_padding .. offset_padding + padding]);

    @memcpy(data[Layout.AUTH_KEY_ID..Layout.MSG_KEY], auth_key_id);

    const message_key = msgKey(auth_key, data[Layout.SALT .. offset_padding + padding], direction);
    @memcpy(data[Layout.MSG_KEY..Layout.SALT], &message_key);

    const derived = kdf(auth_key, data[Layout.MSG_KEY..Layout.SALT], direction);
    ige(data[Layout.SALT .. offset_padding + padding], data[Layout.SALT .. offset_padding + padding], &derived.key, &derived.iv, true);
}

/// Verifies auth_key_id/msg_key, decrypts the payload in place, and returns the decoded header.
pub fn decrypt(data: []u8, expected_auth_key_id: *const [8]u8, auth_key: *const [256]u8, comptime direction: Direction) Error!Header {
    if (data.len < Layout.BODY or (data.len - Layout.SALT) % 16 != 0) {
        return Error.InvalidMsgLength;
    }

    const auth_key_id = data[Layout.AUTH_KEY_ID..Layout.MSG_KEY];
    if (!std.mem.eql(u8, expected_auth_key_id, auth_key_id)) {
        return Error.AuthKeyMismatch;
    }

    const message_key = data[Layout.MSG_KEY..Layout.SALT];
    const derived = kdf(auth_key, message_key, direction);
    ige(data[Layout.SALT..], data[Layout.SALT..], &derived.key, &derived.iv, false);

    const plaintext = data[Layout.SALT..];
    const expected_msg_key = msgKey(auth_key, plaintext, direction);
    if (!std.mem.eql(u8, message_key, &expected_msg_key)) {
        return Error.MsgKeyMismatch;
    }

    const body_len = std.mem.readInt(u32, data[Layout.BODY_LEN..Layout.BODY], .little);
    if (body_len % 4 != 0 or body_len > plaintext.len) {
        return Error.InvalidMsgLength;
    }

    const padding_len = plaintext.len - Layout.encryptedPayloadLen(body_len);
    if (padding_len < 12) {
        return Error.PaddingMismatch;
    }

    return .{
        .salt = std.mem.readInt(u64, data[Layout.SALT..Layout.SESSION_ID], .little),
        .session_id = std.mem.readInt(u64, data[Layout.SESSION_ID..Layout.MESSAGE_ID], .little),
        .message_id = std.mem.readInt(u64, data[Layout.MESSAGE_ID..Layout.SEQNO], .little),
        .seqno = std.mem.readInt(u32, data[Layout.SEQNO..Layout.BODY_LEN], .little),
        .body_len = body_len,
    };
}

test "encrypted message layout offsets and padding" {
    try std.testing.expectEqual(@as(usize, 0), Layout.AUTH_KEY_ID);
    try std.testing.expectEqual(@as(usize, 8), Layout.MSG_KEY);
    try std.testing.expectEqual(@as(usize, 24), Layout.SALT);
    try std.testing.expectEqual(@as(usize, 32), Layout.SESSION_ID);
    try std.testing.expectEqual(@as(usize, 40), Layout.MESSAGE_ID);
    try std.testing.expectEqual(@as(usize, 48), Layout.SEQNO);
    try std.testing.expectEqual(@as(usize, 52), Layout.BODY_LEN);
    try std.testing.expectEqual(@as(usize, 56), Layout.BODY);

    try std.testing.expectEqual(@as(usize, 32), Layout.encryptedPayloadLen(0));
    try std.testing.expectEqual(@as(usize, 16), Layout.paddingLen(0));
    try std.testing.expectEqual(@as(usize, 72), Layout.totalLen(0));

    try std.testing.expectEqual(@as(usize, 36), Layout.encryptedPayloadLen(4));
    try std.testing.expectEqual(@as(usize, 12), Layout.paddingLen(4));
    try std.testing.expectEqual(@as(usize, 72), Layout.totalLen(4));

    try std.testing.expectEqual(@as(usize, 52), Layout.encryptedPayloadLen(20));
    try std.testing.expectEqual(@as(usize, 12), Layout.paddingLen(20));
    try std.testing.expectEqual(@as(usize, 88), Layout.totalLen(20));
}

test "encrypt and decrypt roundtrip preserves header and body" {
    const io = std.testing.io;

    var auth_key: [256]u8 = undefined;
    for (&auth_key, 0..) |*byte, i| {
        byte.* = @intCast((i * 29 + 7) % 251);
    }

    var auth_key_sha1: [20]u8 = undefined;
    std.crypto.hash.Sha1.hash(&auth_key, &auth_key_sha1, .{});
    var auth_key_id: [8]u8 = undefined;
    @memcpy(&auth_key_id, auth_key_sha1[12..20]);

    const body = [_]u8{ 0x04, 0x03, 0x02, 0x01 };
    var packet: [Layout.totalLen(body.len)]u8 = undefined;
    @memcpy(packet[Layout.BODY..][0..body.len], &body);

    const salt = 0x1122334455667788;
    const session_id = 0x8877665544332211;
    const message_id = 0x0000000100000000;
    const seqno = 4;

    try encrypt(io, &packet, &auth_key_id, &auth_key, salt, session_id, message_id, seqno, body.len, .client_to_server);
    const header = try decrypt(&packet, &auth_key_id, &auth_key, .client_to_server);

    try std.testing.expectEqual(salt, header.salt);
    try std.testing.expectEqual(session_id, header.session_id);
    try std.testing.expectEqual(message_id, header.message_id);
    try std.testing.expectEqual(seqno, header.seqno);
    try std.testing.expectEqual(body.len, header.body_len);
    try std.testing.expectEqualSlices(u8, &body, packet[Layout.BODY..][0..body.len]);
}
