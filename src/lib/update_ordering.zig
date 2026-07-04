const std = @import("std");

/// Durable synchronization cursor.  Mutation is intentionally kept separate
/// from update conversion so callers can commit the cursor and emitted events
/// in the same storage transaction.
pub const CommonState = struct {
    pts: u32 = 0,
    qts: u32 = 0,
    date: u32 = 0,
    seq: u32 = 0,
};

pub const Decision = enum { apply, duplicate, gap };

pub const RecoveryReason = enum {
    gap,
    updates_too_long,
    new_session,
    incomplete_short_update,
    idle,
    missing_channel_peer,
};

pub const GAP_DELAY_NS: u64 = 500 * std.time.ns_per_ms;
pub const IDLE_RECOVERY_NS: u64 = 15 * std.time.ns_per_min;

pub const DifferenceCursor = union(enum) {
    empty: struct { date: u32, seq: u32 },
    complete: CommonState,
    slice: CommonState,
    too_long: u32,
};

/// Applies only the synchronization cursor from a difference result. Actual
/// peers, updates, and public events must be staged before this is committed.
/// The return value tells the worker whether it must request another page.
pub fn applyDifferenceCursor(state: *CommonState, result: DifferenceCursor) bool {
    switch (result) {
        .empty => |x| commitEnvelope(state, x.date, x.seq),
        .complete => |x| state.* = x,
        .slice => |x| {
            state.* = x;
            return true;
        },
        .too_long => |pts| state.pts = pts,
    }
    return false;
}

pub fn classifyCounter(local: u32, remote: u32, count: u32) Decision {
    if (remote <= local) return .duplicate;
    const expected = std.math.add(u32, local, count) catch return .gap;
    return if (expected == remote) .apply else .gap;
}

pub fn classifyPts(state: CommonState, pts: u32, pts_count: u32) Decision {
    return classifyCounter(state.pts, pts, pts_count);
}

pub fn classifyQts(state: CommonState, qts: u32) Decision {
    return classifyCounter(state.qts, qts, 1);
}

/// seq_start is zero for envelopes which are explicitly outside seq ordering.
pub fn classifySeq(state: CommonState, seq_start: u32, seq: u32) Decision {
    if (seq_start == 0) return .apply;
    if (seq <= state.seq) return .duplicate;
    const expected = std.math.add(u32, state.seq, 1) catch return .gap;
    return if (expected == seq_start) .apply else .gap;
}

pub fn commitPts(state: *CommonState, pts: u32) void {
    state.pts = pts;
}

pub fn commitQts(state: *CommonState, qts: u32) void {
    state.qts = qts;
}

/// Must only be called after every update in an envelope was applied.
pub fn commitEnvelope(state: *CommonState, date: u32, seq: u32) void {
    state.date = date;
    state.seq = seq;
}

test "pts accepts contiguous values, drops duplicates, and detects gaps" {
    const state: CommonState = .{ .pts = 10 };
    try std.testing.expectEqual(Decision.apply, classifyPts(state, 12, 2));
    try std.testing.expectEqual(Decision.duplicate, classifyPts(state, 10, 1));
    try std.testing.expectEqual(Decision.gap, classifyPts(state, 13, 2));
    try std.testing.expectEqual(Decision.gap, classifyPts(state, 11, 2));
}

test "qts has an implicit count of one" {
    const state: CommonState = .{ .qts = 7 };
    try std.testing.expectEqual(Decision.apply, classifyQts(state, 8));
    try std.testing.expectEqual(Decision.duplicate, classifyQts(state, 7));
    try std.testing.expectEqual(Decision.gap, classifyQts(state, 9));
}

test "seq ordering and zero seq_start" {
    const state: CommonState = .{ .seq = 4 };
    try std.testing.expectEqual(Decision.apply, classifySeq(state, 5, 7));
    try std.testing.expectEqual(Decision.apply, classifySeq(state, 0, 0));
    try std.testing.expectEqual(Decision.duplicate, classifySeq(state, 4, 4));
    try std.testing.expectEqual(Decision.gap, classifySeq(state, 6, 6));
}

test "envelope state advances only on explicit commit" {
    var state: CommonState = .{ .date = 1, .seq = 2 };
    _ = classifySeq(state, 3, 3);
    try std.testing.expectEqual(@as(u32, 1), state.date);
    try std.testing.expectEqual(@as(u32, 2), state.seq);
    commitEnvelope(&state, 9, 3);
    try std.testing.expectEqual(@as(u32, 9), state.date);
    try std.testing.expectEqual(@as(u32, 3), state.seq);
}

test "all common difference cursors have defined transitions" {
    var state: CommonState = .{ .pts = 1, .qts = 2, .date = 3, .seq = 4 };
    try std.testing.expect(!applyDifferenceCursor(&state, .{ .empty = .{ .date = 8, .seq = 9 } }));
    try std.testing.expectEqual(@as(u32, 1), state.pts);
    try std.testing.expectEqual(@as(u32, 8), state.date);

    const intermediate: CommonState = .{ .pts = 10, .qts = 11, .date = 12, .seq = 13 };
    try std.testing.expect(applyDifferenceCursor(&state, .{ .slice = intermediate }));
    try std.testing.expectEqual(intermediate, state);

    const final: CommonState = .{ .pts = 20, .qts = 21, .date = 22, .seq = 23 };
    try std.testing.expect(!applyDifferenceCursor(&state, .{ .complete = final }));
    try std.testing.expectEqual(final, state);

    try std.testing.expect(!applyDifferenceCursor(&state, .{ .too_long = 30 }));
    try std.testing.expectEqual(@as(u32, 30), state.pts);
    try std.testing.expectEqual(@as(u32, 21), state.qts);
}
