const std = @import("std");
const api = @import("api.zig");

test "basic constructor serialize & deserialize" {
    const allocator = std.testing.allocator;
    defer _ = std.testing.allocator_instance.detectLeaks();

    {
        const constructor = api.IInputUser{ .InputUserSelf = &api.InputUserSelf{} };

        var dest = try allocator.alloc(u8, constructor.serializedSize());
        defer allocator.free(dest);

        const serialized = constructor.serialize(dest);

        dest = dest[0..serialized];

        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();

        const deserialized = try api.IInputUser.deserialize(arena.allocator(), dest);

        switch (deserialized[1]) {
            .InputUserSelf => {},
            else => unreachable,
        }
    }

    _ = std.testing.allocator_instance.detectLeaks();
}

test "basic constructor with some fields serialize & deserialize" {
    const allocator = std.testing.allocator;
    defer _ = std.testing.allocator_instance.detectLeaks();

    {
        const constructor = api.IInputFile{ .InputFile = &api.InputFile{ .id = 123, .parts = 59535612, .name = "namefieldhere", .md5_checksum = "itworks!!!!0AA" } };

        var dest = try allocator.alloc(u8, constructor.serializedSize());
        defer allocator.free(dest);

        const serialized = constructor.serialize(dest);

        dest = dest[0..serialized];

        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();

        const deserialized = try api.IInputFile.deserialize(arena.allocator(), dest);

        switch (deserialized[1]) {
            .InputFile => {
                const input_file = deserialized[1].InputFile;
                try std.testing.expectEqual(123, input_file.id);
                try std.testing.expectEqual(59535612, input_file.parts);
                try std.testing.expectEqualStrings("namefieldhere", input_file.name);
                try std.testing.expectEqualStrings("itworks!!!!0AA", input_file.md5_checksum);
            },
            else => unreachable,
        }
    }
}

test "deserialize constructor with int vector" {
    const data = [_]u8{ 60, 65, 92, 248, 191, 237, 60, 25, 0, 0, 0, 0, 21, 196, 181, 28, 3, 0, 0, 0, 128, 0, 0, 0, 128, 0, 0, 0, 0, 1, 0, 0 };

    defer _ = std.testing.allocator_instance.detectLeaks();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const deserialized = try api.IVideoSize.deserialize(arena.allocator(), &data);

    try std.testing.expectEqual(data.len, deserialized[0]);

    switch (deserialized[1]) {
        .VideoSizeEmojiMarkup => {
            const video_size = deserialized[1].VideoSizeEmojiMarkup;
            try std.testing.expectEqual(423423423, video_size.emoji_id);
            try std.testing.expectEqualSlices(i32, &[_]i32{ 128, 128, 256 }, video_size.background_colors);
        },
        else => unreachable,
    }
}

test "big constructor serialize & deserialize" {
    const allocator = std.testing.allocator;
    defer _ = std.testing.allocator_instance.detectLeaks();

    const constructor = api.IMessage{ .Message = &api.Message{
        .id = 32,
        .message = "asdasd",
        .restriction_reason = &[_]api.IRestrictionReason{api.IRestrictionReason{ .RestrictionReason = &api.RestrictionReason{ .platform = "test", .text = "test", .reason = "reason" } }},
        .peer_id = api.IPeer{
            .PeerChannel = &api.PeerChannel{
                .channel_id = 3543543,
            },
        },
        .date = 342432432,
    } };

    const size = constructor.serializedSize();
    var dest = try allocator.alloc(u8, size);
    defer allocator.free(dest);

    const serialized = constructor.serialize(dest);

    dest = dest[0..serialized];

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const deserialize = try api.IMessage.deserialize(arena.allocator(), dest);

    switch (deserialize[1]) {
        .Message => {
            const message = deserialize[1].Message;
            try std.testing.expectEqual(32, message.id);
            try std.testing.expectEqualStrings("asdasd", message.message);
            try std.testing.expectEqual(342432432, message.date);

            try std.testing.expectEqual(1, message.restriction_reason.?.len);
            switch (message.restriction_reason.?[0]) {
                .RestrictionReason => {
                    const restriction_reason = message.restriction_reason.?[0].RestrictionReason;
                    try std.testing.expectEqualStrings("test", restriction_reason.platform);
                    try std.testing.expectEqualStrings("test", restriction_reason.text);
                    try std.testing.expectEqualStrings("reason", restriction_reason.reason);
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
