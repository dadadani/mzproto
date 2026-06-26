const std = @import("std");
const ige = @import("./ige.zig").ige;

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
    const offset_auth_key_id = 0;
    const offset_msg_key = offset_auth_key_id + 8;
    const offset_salt = offset_msg_key + 16;
    const offset_session_id = offset_salt + 8;
    const offset_message_id = offset_session_id + 8;
    const offset_seqno = offset_message_id + 8;
    const offset_len_data = offset_seqno + 4;
    const offset_data = offset_len_data + 4;
    const offset_padding = offset_data + message_len;

    std.debug.assert(offset_padding <= data.len);

    const padding_len = data.len - offset_padding;
    std.debug.assert((offset_padding - offset_salt + padding_len) % 16 == 0);

    std.mem.writeInt(u64, data[offset_salt..][0..8], salt, .little);
    std.mem.writeInt(u64, data[offset_session_id..][0..8], session_id, .little);
    std.mem.writeInt(u64, data[offset_message_id..][0..8], message_id, .little);
    std.mem.writeInt(u32, data[offset_seqno..][0..4], seqno, .little);
    std.mem.writeInt(u32, data[offset_len_data..][0..4], @intCast(message_len), .little);

    try std.Io.randomSecure(io, data[offset_padding..]);

    @memcpy(data[offset_auth_key_id..offset_msg_key], auth_key_id);

    var sha1: [20]u8 = undefined;
    std.crypto.hash.Sha1.hash(data[offset_salt..offset_padding], &sha1, .{});
    @memcpy(data[offset_msg_key..offset_salt], sha1[4..20]);

    const derived = kdf(auth_key, data[offset_msg_key..offset_salt], 0);
    ige(data[offset_salt..], data[offset_salt..], &derived.key, &derived.iv, true);
}
