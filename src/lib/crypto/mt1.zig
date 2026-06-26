const std = @import("std");
const ige = @import("./ige.zig").ige;

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

/// Returns the MTProto 1.0 padding length for an encrypted payload length.
pub inline fn determinePadding(len: usize) usize {
    const remainder = len % 16;
    return if (remainder == 0) 0 else 16 - remainder;
}

/// Derives the AES key and IV from the auth key and message key.
fn kdf(auth_key: *const [256]u8, msg_key: []const u8, comptime x: usize) struct {
    key: [32]u8,
    iv: [32]u8,
} {
    std.debug.assert(msg_key.len == 16);

    var buf: [48]u8 = undefined;

    var sha1_a: [20]u8 = undefined;
    @memcpy(buf[0..16], msg_key);
    @memcpy(buf[16..48], auth_key[x .. x + 32]);
    std.crypto.hash.Sha1.hash(&buf, &sha1_a, .{});

    var sha1_b: [20]u8 = undefined;
    @memcpy(buf[0..16], auth_key[x + 32 .. x + 48]);
    @memcpy(buf[16..32], msg_key);
    @memcpy(buf[32..48], auth_key[x + 48 .. x + 64]);
    std.crypto.hash.Sha1.hash(&buf, &sha1_b, .{});

    var sha1_c: [20]u8 = undefined;
    @memcpy(buf[0..32], auth_key[x + 64 .. x + 96]);
    @memcpy(buf[32..48], msg_key);
    std.crypto.hash.Sha1.hash(&buf, &sha1_c, .{});

    var sha1_d: [20]u8 = undefined;
    @memcpy(buf[0..16], msg_key);
    @memcpy(buf[16..48], auth_key[x + 96 .. x + 128]);
    std.crypto.hash.Sha1.hash(&buf, &sha1_d, .{});

    var key: [32]u8 = undefined;
    @memcpy(key[0..8], sha1_a[0..8]);
    @memcpy(key[8..20], sha1_b[8..20]);
    @memcpy(key[20..32], sha1_c[4..16]);

    var iv: [32]u8 = undefined;
    @memcpy(iv[0..12], sha1_a[8..20]);
    @memcpy(iv[12..20], sha1_b[0..8]);
    @memcpy(iv[20..24], sha1_c[16..20]);
    @memcpy(iv[24..32], sha1_d[0..8]);

    return .{ .key = key, .iv = iv };
}

/// Writes an MTProto 1.0 encrypted-message header, pads, calculates msg_key, and encrypts in place.
pub fn encrypt(
    io: std.Io,
    data: []u8,
    auth_key_id: *const [8]u8,
    auth_key: *const [256]u8,
    salt: u64,
    session_id: u64,
    message_id: u64,
    seqno: u32,
    message_len: usize,
) !void {
    const offset_padding = Layout.paddingOffset(message_len);
    std.debug.assert(offset_padding <= data.len);

    const padding_len = data.len - offset_padding;
    std.debug.assert((Layout.encryptedPayloadLen(message_len) + padding_len) % 16 == 0);

    std.mem.writeInt(u64, data[Layout.SALT..Layout.SESSION_ID], salt, .little);
    std.mem.writeInt(u64, data[Layout.SESSION_ID..Layout.MESSAGE_ID], session_id, .little);
    std.mem.writeInt(u64, data[Layout.MESSAGE_ID..Layout.SEQNO], message_id, .little);
    std.mem.writeInt(u32, data[Layout.SEQNO..Layout.BODY_LEN], seqno, .little);
    std.mem.writeInt(u32, data[Layout.BODY_LEN..Layout.BODY], @intCast(message_len), .little);

    try std.Io.randomSecure(io, data[offset_padding..]);

    @memcpy(data[Layout.AUTH_KEY_ID..Layout.MSG_KEY], auth_key_id);

    var sha1: [20]u8 = undefined;
    std.crypto.hash.Sha1.hash(data[Layout.SALT..offset_padding], &sha1, .{});
    @memcpy(data[Layout.MSG_KEY..Layout.SALT], sha1[4..20]);

    const derived = kdf(auth_key, data[Layout.MSG_KEY..Layout.SALT], 0);
    ige(data[Layout.SALT..], data[Layout.SALT..], &derived.key, &derived.iv, true);
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
    try std.testing.expectEqual(@as(usize, 0), Layout.paddingLen(0));
    try std.testing.expectEqual(@as(usize, 56), Layout.totalLen(0));

    try std.testing.expectEqual(@as(usize, 36), Layout.encryptedPayloadLen(4));
    try std.testing.expectEqual(@as(usize, 12), Layout.paddingLen(4));
    try std.testing.expectEqual(@as(usize, 72), Layout.totalLen(4));

    try std.testing.expectEqual(@as(usize, 52), Layout.encryptedPayloadLen(20));
    try std.testing.expectEqual(@as(usize, 12), Layout.paddingLen(20));
    try std.testing.expectEqual(@as(usize, 88), Layout.totalLen(20));
}
