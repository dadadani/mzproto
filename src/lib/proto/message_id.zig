const std = @import("std");
const MessageID = @This();

server_time: u64 = 0,
reference_monotime: std.Io.Timestamp = .{ .nanoseconds = 0 },
last_time: u64 = 0,
time_offset: u64 = 0,


/// Syncs the message ID generator with the server's time.
pub fn updateTime(self: *MessageID, io: std.Io, server_time: u64) void {
    self.reference_monotime = std.Io.Clock.now(.awake, io);

    self.server_time = server_time;
}

/// Returns the current unix timestamp adjusted to server time.
pub fn getUnix(self: *MessageID, io: std.Io) u64 {
    const now = @as(u64, @intCast((std.Io.Clock.now(.awake, io)).toSeconds()));
    return now - @as(u64, @intCast(self.reference_monotime.toSeconds())) + self.server_time;
}

/// Generates a unique message ID for MTProto.
///
/// Format: (unixtime << 32) + offset
/// - Must be divisible by 4 (client requirement)
/// - Must increase monotonically within a session
/// - Must be within 300s past or 30s future of server time
pub fn get(self: *MessageID, io: std.Io) u64 {
    const time = self.getUnix(io);

    // Ensure monotonically increasing within same second
    if (time == self.last_time) {
        self.time_offset += 4;
    } else {
        self.time_offset = 0;
        self.last_time = time;
    }

    // msg_id = unixtime * 2^32 + offset
    // Client message IDs must be divisible by 4
    return (time << 32) + self.time_offset;
}
