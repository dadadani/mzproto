const std = @import("std");

pub const PeerKind = enum(u8) { user, chat, channel };

pub const PeerRecord = struct {
    kind: PeerKind,
    id: u64,
    access_hash: ?i64 = null,
    /// A `min` hash must never replace a full hash.
    access_hash_is_min: bool = false,
    layer: u32,
    constructor: []const u8,

    pub fn shouldReplaceAccessHash(old: PeerRecord, new: PeerRecord) bool {
        if (old.kind != new.kind or old.id != new.id or new.access_hash == null) return false;
        return old.access_hash == null or old.access_hash_is_min or !new.access_hash_is_min;
    }
};

pub const ChannelUpdateState = struct { channel_id: u64, pts: u32 };

test "authoritative peer hashes take precedence over min hashes" {
    const min: PeerRecord = .{ .kind = .channel, .id = 1, .access_hash = 10, .access_hash_is_min = true, .layer = 1, .constructor = "min" };
    const full: PeerRecord = .{ .kind = .channel, .id = 1, .access_hash = 20, .layer = 1, .constructor = "full" };
    try std.testing.expect(min.shouldReplaceAccessHash(full));
    try std.testing.expect(!full.shouldReplaceAccessHash(min));
}
