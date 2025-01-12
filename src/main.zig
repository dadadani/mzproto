const std = @import("std");
const api = @import("generator/api.zig");
pub fn main() !void {
    var allocatorg = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = allocatorg.deinit();
    }
    const allocator = &allocatorg.allocator();

    const constructor = api.IMessage{ .Message = &api.Message{
        .id = 32,
        .message = "asdasd",
        .restriction_reason = &[_]api.IRestrictionReason{api.IRestrictionReason{ .RestrictionReason = &api.RestrictionReason{ .platform = "platform", .text = "text", .reason = "reason" } }},
        .peer_id = api.IPeer{ .PeerChannel = &api.PeerChannel{
            .channel_id = 3543543,
        } },
        .date = 342432432,
    } };

    const size = constructor.serializedSize();
    var dest = try allocator.alloc(u8, size);
    defer allocator.free(dest);

    const serialized = constructor.serialize(dest);

    dest = dest[0..serialized];

    var cursor: usize = 0;
    var written: usize = 0;

    api.TL.deserializedSize(dest, &cursor, &written);

    const deserializeBuffer = try allocator.alloc(u8, written);
    defer allocator.free(deserializeBuffer);

    cursor = 0;
    written = 0;

    const deserialized = api.TL.deserialize(dest, deserializeBuffer, &cursor, &written);

    var writtenAgain: usize = 0;

    deserialized.cloneSize(&writtenAgain);

    try std.testing.expectEqual(written, writtenAgain);

    switch (deserialized) {
        .Message => {
            const message = deserialized.Message;

            try std.testing.expectEqual(32, message.id);
            try std.testing.expectEqualStrings("asdasd", message.message);
            try std.testing.expectEqual(342432432, message.date);

            try std.testing.expectEqual(1, message.restriction_reason.?.len);
            switch (message.restriction_reason.?[0]) {
                .RestrictionReason => {
                    const restriction_reason = message.restriction_reason.?[0].RestrictionReason;
                    try std.testing.expectEqualStrings("platform", restriction_reason.platform);
                    try std.testing.expectEqualStrings("reason", restriction_reason.reason);
                    try std.testing.expectEqualStrings("text", restriction_reason.text);
                },
            }

            switch (message.peer_id) {
                .PeerChannel => {
                    const peer_channel = message.peer_id.PeerChannel;
                    try std.testing.expectEqual(3543543, peer_channel.channel_id);
                },
                else => unreachable,
            }
        },
        else => unreachable,
    }

    const clonebuf = try allocator.alloc(u8, writtenAgain);
    defer allocator.free(clonebuf);

    writtenAgain = 0;

    const clone = deserialized.clone(clonebuf, &writtenAgain);

    try std.testing.expectEqual(written, writtenAgain);

    switch (clone) {
        .Message => {
            const message = clone.Message;

            try std.testing.expectEqual(32, message.id);
            try std.testing.expectEqualStrings("asdasd", message.message);
            try std.testing.expectEqual(342432432, message.date);

            try std.testing.expectEqual(1, message.restriction_reason.?.len);
            switch (message.restriction_reason.?[0]) {
                .RestrictionReason => {
                    const restriction_reason = message.restriction_reason.?[0].RestrictionReason;
                    try std.testing.expectEqualStrings("platform", restriction_reason.platform);
                    try std.testing.expectEqualStrings("reason", restriction_reason.reason);
                    try std.testing.expectEqualStrings("text", restriction_reason.text);
                },
            }

            switch (message.peer_id) {
                .PeerChannel => {
                    const peer_channel = message.peer_id.PeerChannel;
                    try std.testing.expectEqual(3543543, peer_channel.channel_id);
                },
                else => unreachable,
            }
        },
        else => unreachable,
    }
}
