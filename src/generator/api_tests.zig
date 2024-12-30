const std = @import("std");
const api = @import("api.zig");

test "basic constructor serialize & deserialize" {
    const allocator = std.testing.allocator;
    //defer _ = std.testing.allocator_instance.detectLeaks();

    {
        var user = api.InputUserSelf{};
        const constructor = api.TL{ .InputUserSelf = &user };

        var dest = try allocator.alloc(u8, constructor.serializedSize());
        defer allocator.free(dest);

        const serialized = constructor.serialize(dest);

        dest = dest[0..serialized];

        const deserialized = try api.IInputUser.deserialize(std.testing.allocator, dest);
        defer deserialized[1].deinit(std.testing.allocator);

        switch (deserialized[1]) {
            .InputUserSelf => {},
            else => unreachable,
        }
    }

    //_ = std.testing.allocator_instance.detectLeaks();
}

test "basic constructor with some fields serialize & deserialize" {
    const allocator = std.testing.allocator;

    {
        var file = api.InputFile{ .id = 123, .parts = 59535612, .name = "namefieldhere", .md5_checksum = "itworks!!!!0AA" };
        var constructor = api.IInputFile{ .InputFile = &file };

        var dest = try allocator.alloc(u8, constructor.serializedSize());
        defer allocator.free(dest);

        const serialized = constructor.serialize(dest);

        dest = dest[0..serialized];

        const deserialized = try api.IInputFile.deserialize(allocator, dest);
        defer deserialized[1].deinit(allocator);

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

    const deserialized = try api.IVideoSize.deserialize(std.testing.allocator, &data);

    try std.testing.expectEqual(data.len, deserialized[0]);

    switch (deserialized[1]) {
        .VideoSizeEmojiMarkup => {
            const video_size = deserialized[1].VideoSizeEmojiMarkup;
            try std.testing.expectEqual(423423423, video_size.emoji_id);
            try std.testing.expectEqualSlices(i32, &[_]i32{ 128, 128, 256 }, video_size.background_colors);
        },
        else => unreachable,
    }
    deserialized[1].deinit(std.testing.allocator);
}

test "big constructor serialize & deserialize" {
    const allocator = std.testing.allocator;

    const constructor = api.IMessage{ .Message = &api.Message{
        .id = 32,
        .message = "asdasd",
        .restriction_reason = &[_]api.IRestrictionReason{api.IRestrictionReason{ .RestrictionReason = &api.RestrictionReason{ .platform = "test", .text = "test", .reason = "reason" } }},
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

    const deserialize = try api.IMessage.deserialize(std.testing.allocator, dest);
    defer deserialize[1].deinit(std.testing.allocator);

    switch (deserialize[1]) {
        .Message => {
            const message = deserialize[1].Message;

            if (message.from_id) |mm| {
                std.debug.print("la fin {any}", .{mm});
            }
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

test "bong" {
    const allocator = std.testing.allocator;

    const constructor = api.IMessage{ .Message = &api.Message{
        .id = 32,
        .message = "asdasd",
        .restriction_reason = &[_]api.IRestrictionReason{api.IRestrictionReason{ .RestrictionReason = &api.RestrictionReason{ .platform = "test", .text = "test", .reason = "reason" } }},
        .peer_id = api.IPeer{ .PeerChannel = &api.PeerChannel{
            .channel_id = 3543543,
        } },
        .date = 342432432,
    } };

    const size = constructor.serializedSize();
    var dest = try allocator.alloc(u8, size);
    defer allocator.free(dest);

    const serialized = constructor.serialize(dest);

    var cursor: usize = 0;
    var ssize: usize = 0;
    std.debug.print("deserializedsize\n", .{});
    api.TL.deserializedSize(dest[0..serialized], &cursor, &ssize);
    std.debug.print("{d}", .{ssize});
}

test "asd" {
    const allocator = std.testing.allocator;

    const protorespq = api.ProtoResPQ{ .nonce = 342432423423432423, .pq = "porcod", .server_nonce = 34243424242432321432432, .server_public_key_fingerprints = &[_]i64{ 3, 4, 3 } };
    var buffer = try allocator.alloc(u8, protorespq.serializedSize());
    defer allocator.free(buffer);
    buffer = buffer[0..protorespq.serialize(buffer)];

    var cursor: usize = 0;
    var deserializedsize: usize = 0;

    api.ProtoResPQ.deserializedSize(buffer[4..], &cursor, &deserializedsize);
    std.debug.print("des size: {d}\n", .{deserializedsize});

    cursor = 0;

    const bufferDest = try allocator.alloc(u8, deserializedsize);
    defer allocator.free(bufferDest);
    const written = api.ProtoResPQ.deserialize2(buffer[4..], bufferDest, &cursor);
    std.debug.print("written size: {d}\n", .{written});

    const result = @as(*api.ProtoResPQ, @ptrCast(@alignCast(bufferDest)));
    std.debug.print("written size: {any}\n", .{result.server_public_key_fingerprints});
}
