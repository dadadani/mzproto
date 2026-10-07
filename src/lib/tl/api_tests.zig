const std = @import("std");
const api = @import("tl");
const base = @import("tl_base");
const utils = @import("../proto/utils.zig");

// Return a deep clone after freeing both the wire and the first decode workspace.
fn roundTrip(comptime T: type, value: base.Ref(T, .boxed).Write) !utils.Owned(T) {
    const allocator = std.testing.allocator;
    const wire = try allocator.alloc(u8, try T.serializedSize(value));
    defer allocator.free(wire);
    const encoded = try T.serialize(value, wire);
    try std.testing.expectEqual(wire.len, encoded.len);
    const decoded = try utils.Owned(T).decode(allocator, encoded);
    defer decoded.deinit(allocator);
    const workspace = try allocator.alignedAlloc(u8, .fromByteUnits(T.out_alignment), try T.cloneSize(decoded.data));
    errdefer allocator.free(workspace);
    const clone = try T.cloneInto(decoded.data, workspace);
    try std.testing.expectEqual(workspace.len, clone.object_bytes);
    return .{ .ptr = workspace, .data = clone.value };
}

test "basic constructor serialize decode and clone" {
    const value = try roundTrip(api.InputUser, .{ .inputUserSelf = &.{} });
    defer value.deinit(std.testing.allocator);
    try std.testing.expect(value.data == .inputUserSelf);
}

test "constructor strings survive decode and clone workspace release" {
    const value = try roundTrip(api.InputFile, .{ .inputFile = &.{ .id = 123, .parts = 59535612, .name = "namefieldhere", .md5_checksum = "itworks!!!!0AA" } });
    defer value.deinit(std.testing.allocator);
    try std.testing.expectEqual(123, value.data.inputFile.id);
    try std.testing.expectEqual(59535612, value.data.inputFile.parts);
    try std.testing.expectEqualStrings("namefieldhere", value.data.inputFile.name);
    try std.testing.expectEqualStrings("itworks!!!!0AA", value.data.inputFile.md5_checksum);
}

test "decode existing constructor with int vector" {
    const data = [_]u8{ 60, 65, 92, 248, 191, 237, 60, 25, 0, 0, 0, 0, 21, 196, 181, 28, 3, 0, 0, 0, 128, 0, 0, 0, 128, 0, 0, 0, 0, 1, 0, 0 };
    const decoded = try utils.Owned(api.VideoSize).decode(std.testing.allocator, &data);
    defer decoded.deinit(std.testing.allocator);
    const value = decoded.data.videoSizeEmojiMarkup;
    try std.testing.expectEqual(423423423, value.emoji_id);
    try std.testing.expectEqualSlices(u32, &.{ 128, 128, 256 }, value.background_colors);
    var encoded: [data.len]u8 = undefined;
    const write: api.videoSizeEmojiMarkup = .{ .emoji_id = value.emoji_id, .background_colors = value.background_colors };
    try std.testing.expectEqualSlices(u8, &data, try api.videoSizeEmojiMarkup.serialize(&write, &encoded));
}

test "nested constructor flags and vectors survive cloning" {
    const value = try roundTrip(api.message, &.{
        .id = 32,
        .message = "asdasd",
        .restriction_reason = &.{.{ .restrictionReason = &.{ .platform = "platform", .text = "text", .reason = "reason" } }},
        .peer_id = .{ .peerChannel = &.{ .channel_id = 3543543 } },
        .date = 342432432,
    });
    defer value.deinit(std.testing.allocator);
    try std.testing.expectEqual(32, value.data.id);
    try std.testing.expectEqualStrings("asdasd", value.data.message);
    try std.testing.expectEqual(342432432, value.data.date);
    const reasons = value.data.restriction_reason.?;
    try std.testing.expectEqual(1, reasons.len);
    try std.testing.expectEqualStrings("platform", reasons[0].restrictionReason.platform);
    try std.testing.expectEqualStrings("reason", reasons[0].restrictionReason.reason);
    try std.testing.expectEqualStrings("text", reasons[0].restrictionReason.text);
    try std.testing.expectEqual(3543543, value.data.peer_id.peerChannel.channel_id);
}

test "dynamic nested function wrappers preserve expected result codec" {
    const request: api.AnyFunction = .{ .invokeWithLayer = &.{ .layer = api.LAYER_VERSION, .query = .{
        .invokeWithTakeout = &.{ .takeout_id = 45, .query = .{ .ping = &.{ .ping_id = 123 } } },
    } } };
    const value = try roundTrip(api.AnyFunction, request);
    defer value.deinit(std.testing.allocator);
    const wrapped = value.data.invokeWithLayer;
    try std.testing.expectEqual(api.LAYER_VERSION, wrapped.layer);
    try std.testing.expectEqual(45, wrapped.query.invokeWithTakeout.takeout_id);
    try std.testing.expectEqual(123, wrapped.query.invokeWithTakeout.query.ping.ping_id);
    var wire: [64]u8 = undefined;
    const response = try utils.Response.decode(std.testing.allocator, wrapped.resultOps(), try api.pong.serialize(&.{ .msg_id = 1, .ping_id = 123 }, &wire));
    defer response.deinit(std.testing.allocator);
    try std.testing.expectEqual(123, (try response.from(api.ping)).pong.ping_id);
}

test "vectors of strings survive decode and cloning" {
    const value = try roundTrip(api.channelAdminLogEventActionChangeUsernames, &.{ .prev_value = &.{"test"}, .new_value = &.{ "test2", "hieveryone!!!!!!!!!!" } });
    defer value.deinit(std.testing.allocator);
    try std.testing.expectEqualStrings("test", value.data.prev_value[0]);
    try std.testing.expectEqualStrings("test2", value.data.new_value[0]);
    try std.testing.expectEqualStrings("hieveryone!!!!!!!!!!", value.data.new_value[1]);
}
