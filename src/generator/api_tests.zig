const std = @import("std");
const api = @import("api.zig");

test "basic constructor serialize & deserialize" {
    const allocator = std.testing.allocator;
    //defer _ = std.testing.allocator_instance.detectLeaks();

    {
        const constructor = api.TL{ .InputUserSelf = &api.InputUserSelf{} };

        var dest = try allocator.alloc(u8, constructor.serializedSize());
        defer allocator.free(dest);

        const serialized = constructor.serialize(dest);

        dest = dest[0..serialized];

        var cursor: usize = 0;
        var written: usize = 0;
        api.IInputUser.deserializedSize(dest, &cursor, &written);

        const deserializeBuffer = try allocator.alloc(u8, written);
        defer allocator.free(deserializeBuffer);

        cursor = 0;
        written = 0;

        const deserialized = api.IInputUser.deserialize(dest, deserializeBuffer, &cursor, &written);

        switch (deserialized) {
            .InputUserSelf => {},
            else => unreachable,
        }
    }

    //_ = std.testing.allocator_instance.detectLeaks();
}

test "basic constructor with some fields serialize & deserialize" {
    const allocator = std.testing.allocator;

    {
        var constructor = api.IInputFile{ .InputFile = &api.InputFile{ .id = 123, .parts = 59535612, .name = "namefieldhere", .md5_checksum = "itworks!!!!0AA" } };

        var dest = try allocator.alloc(u8, constructor.serializedSize());
        defer allocator.free(dest);

        const serialized = constructor.serialize(dest);

        dest = dest[0..serialized];

        var cursor: usize = 0;
        var written: usize = 0;

        api.IInputFile.deserializedSize(dest, &cursor, &written);

        const deserializeBuffer = try allocator.alloc(u8, written);
        defer allocator.free(deserializeBuffer);

        cursor = 0;
        written = 0;
        const deserialized = api.IInputFile.deserialize(dest, deserializeBuffer, &cursor, &written);

        switch (deserialized) {
            .InputFile => {
                const input_file = deserialized.InputFile;
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

    var cursor: usize = 0;
    var written: usize = 0;

    api.IVideoSize.deserializedSize(&data, &cursor, &written);

    const deserializeBuffer = try std.testing.allocator.alloc(u8, written);
    defer std.testing.allocator.free(deserializeBuffer);

    cursor = 0;
    written = 0;

    const deserialized = api.IVideoSize.deserialize(&data, deserializeBuffer, &cursor, &written);

    try std.testing.expectEqual(data.len, cursor);

    switch (deserialized) {
        .VideoSizeEmojiMarkup => {
            const video_size = deserialized.VideoSizeEmojiMarkup;
            try std.testing.expectEqual(423423423, video_size.emoji_id);
            try std.testing.expectEqualSlices(i32, &[_]i32{ 128, 128, 256 }, video_size.background_colors);
        },
        else => unreachable,
    }
}

test "big constructor serialize & deserialize" {
    const allocator = std.testing.allocator;

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

    const deserializeBuffer = try std.testing.allocator.alloc(u8, written);
    defer std.testing.allocator.free(deserializeBuffer);

    cursor = 0;
    written = 0;

    const deserialized = api.TL.deserialize(dest, deserializeBuffer, &cursor, &written);

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
}

test "MessageContainer serialization & deserialization" {
    const container = api.MessageContainer{ .messages = &[_]api.ProtoMessage{api.ProtoMessage{ .body = api.TL{ .InputPeerSelf = &api.InputPeerSelf{} }, .msg_id = 342423423543534, .seqno = 23 }} };

    var sbuf = try std.testing.allocator.alloc(u8, container.serializedSize());
    defer std.testing.allocator.free(sbuf);

    var written = container.serialize(sbuf);

    sbuf = sbuf[0..written];

    var cursor: usize = 0;
    written = 0;

    api.TL.deserializedSize(sbuf, &cursor, &written);

    const dbuf = try std.testing.allocator.alloc(u8, written);
    defer std.testing.allocator.free(dbuf);

    cursor = 0;
    written = 0;

    const deserialized = api.TL.deserialize(sbuf, dbuf, &cursor, &written);

    switch (deserialized) {
        .MessageContainer => |x| {
            try std.testing.expectEqual(342423423543534, x.messages[0].msg_id);
            try std.testing.expectEqual(23, x.messages[0].seqno);

            switch (x.messages[0].body) {
                .InputPeerSelf => {},
                else => unreachable,
            }
        },
        else => unreachable,
    }
}

test "RPCResult serialization & deserialization" {
    const constructor = api.RPCResult{ .body = api.TL{ .ImportedContact = &api.ImportedContact{ .user_id = 432423423, .client_id = 342432432 } }, .req_msg_id = 929437432873425453 };

    var sbuf = try std.testing.allocator.alloc(u8, constructor.serializedSize());
    defer std.testing.allocator.free(sbuf);

    var written = constructor.serialize(sbuf);

    sbuf = sbuf[0..written];

    var cursor: usize = 0;
    written = 0;

    api.TL.deserializedSize(sbuf, &cursor, &written);

    const dbuf = try std.testing.allocator.alloc(u8, written);
    defer std.testing.allocator.free(dbuf);

    cursor = 0;
    written = 0;

    const deserialized = api.TL.deserialize(sbuf, dbuf, &cursor, &written);

    switch (deserialized) {
        .RPCResult => |x| {
            try std.testing.expectEqual(929437432873425453, x.req_msg_id);

            switch (x.body) {
                .ImportedContact => |xx| {
                    try std.testing.expectEqual(342432432, xx.client_id);
                    try std.testing.expectEqual(432423423, xx.user_id);
                },
                else => unreachable,
            }
        },
        else => unreachable,
    }
}

test "Vector long deserialization" {

    // I haven't implement a "serialize" function for the vector type, so we do the worst hack possible

    const baseob = api.ProtoResPQ{ .nonce = 0, .pq = "", .server_nonce = 0, .server_public_key_fingerprints = &[_]i64{ 432423342, 45346, 897225, 4543 } };

    var sbuf = try std.testing.allocator.alloc(u8, baseob.serializedSize());
    defer std.testing.allocator.free(sbuf);

    var written = baseob.serialize(sbuf);

    const xsbuf = sbuf[4 + 36 .. written];

    written = 0;
    var cursor: usize = 0;

    api.TL.deserializedSize(xsbuf, &cursor, &written);

    const dbuf = try std.testing.allocator.alloc(u8, written);
    defer std.testing.allocator.free(dbuf);

    written = 0;
    cursor = 0;

    const deserialized = api.TL.deserialize(xsbuf, dbuf, &cursor, &written);

    switch (deserialized) {
        .Vector => {},
        else => unreachable,
    }
}

test "Dynamic constructor" {
    const constructor = api.InvokeWithLayer{ .layer = 149, .query = api.TL{ .InvokeWithTakeout = &api.InvokeWithTakeout{ .takeout_id = 45, .query = .{ .InputUserSelf = &api.InputUserSelf{} } } } };

    var sbuf = try std.testing.allocator.alloc(u8, constructor.serializedSize());
    defer std.testing.allocator.free(sbuf);

    var written = constructor.serialize(sbuf);

    sbuf = sbuf[0..written];

    var cursor: usize = 0;
    written = 0;

    api.TL.deserializedSize(sbuf, &cursor, &written);

    const dbuf = try std.testing.allocator.alloc(u8, written);
    defer std.testing.allocator.free(dbuf);

    cursor = 0;
    written = 0;

    const deserialized = api.TL.deserialize(sbuf, dbuf, &cursor, &written);

    switch (deserialized) {
        .InvokeWithLayer => |x| {
            try std.testing.expectEqual(149, x.layer);

            switch (x.query) {
                .InvokeWithTakeout => |xx| {
                    try std.testing.expectEqual(45, xx.takeout_id);
                    switch (xx.query) {
                        .InputUserSelf => {},
                        else => unreachable,
                    }
                },
                else => unreachable,
            }
        },
        else => unreachable,
    }
}
