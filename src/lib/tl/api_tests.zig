//   Copyright (c) 2025 Daniele Cortesi <https://github.com/dadadani>
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

const std = @import("std");
const api = @import("api.zig");

test "basic constructor serialize & deserialize" {
    const allocator = std.testing.allocator;
    {
        const constructor = api.TL{ .InputUserSelf = &api.InputUserSelf{} };

        const dest = try allocator.alloc(u8, constructor.serializeSize());
        defer allocator.free(dest);

        const serialized = constructor.serialize(dest);

        try std.testing.expectEqual(constructor.serializeSize(), serialized);

        var size: usize = 0;
        const deserialized_read_bytes = api.IInputUser.deserializeSize(dest, &size);
        try std.testing.expectEqual(constructor.serializeSize(), deserialized_read_bytes);

        const deserializeBuffer = try allocator.alloc(u8, size);
        defer allocator.free(deserializeBuffer);

        size = 0;

        const deserializedx = api.IInputUser.deserialize(dest, deserializeBuffer);
        const deserialized = deserializedx[0];

        var writtenAgain: usize = 0;

        deserialized.cloneSize(&writtenAgain);

        try std.testing.expectEqual(size, writtenAgain);

        const clone_dest = try allocator.alloc(u8, writtenAgain);
        defer allocator.free(clone_dest);

        const clone = deserialized.clone(clone_dest);

        switch (deserialized) {
            .InputUserSelf => {},
            else => unreachable,
        }

        switch (clone[0]) {
            .InputUserSelf => {},
            else => unreachable,
        }
    }
}

test "basic constructor with some fields serialize & deserialize" {
    const allocator = std.testing.allocator;

    {
        var constructor = api.IInputFile{ .InputFile = &api.InputFile{ .id = 123, .parts = 59535612, .name = "namefieldhere", .md5_checksum = "itworks!!!!0AA" } };

        const dest = try allocator.alloc(u8, constructor.serializeSize());
        defer allocator.free(dest);

        const serialized = constructor.serialize(dest);

        try std.testing.expectEqual(constructor.serializeSize(), serialized);

        var size: usize = 0;

        const deserialized_read = api.IInputFile.deserializeSize(dest, &size);

        try std.testing.expectEqual(constructor.serializeSize(), deserialized_read);

        const deserializeBuffer = try allocator.alloc(u8, size);
        defer allocator.free(deserializeBuffer);

        const deserializedx = api.IInputFile.deserialize(dest, deserializeBuffer);
        const deserialized = deserializedx[0];

        try std.testing.expectEqual(size, deserializedx[1]);
        try std.testing.expectEqual(constructor.serializeSize(), deserializedx[2]);

        var sizeAgain: usize = 0;

        deserialized.cloneSize(&sizeAgain);

        try std.testing.expectEqual(size, sizeAgain);

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

        const clonebuf = try allocator.alloc(u8, sizeAgain);
        defer allocator.free(clonebuf);

        const clone = deserialized.clone(clonebuf);

        try std.testing.expectEqual(size, clone[1]);

        switch (clone[0]) {
            .InputFile => {
                const input_file = clone[0].InputFile;
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
    const allocator = std.testing.allocator;

    const data = [_]u8{ 60, 65, 92, 248, 191, 237, 60, 25, 0, 0, 0, 0, 21, 196, 181, 28, 3, 0, 0, 0, 128, 0, 0, 0, 128, 0, 0, 0, 0, 1, 0, 0 };

    var size: usize = 0;

    const deserialize_read = api.IVideoSize.deserializeSize(&data, &size);

    try std.testing.expectEqual(data.len, deserialize_read);

    const deserializeBuffer = try std.testing.allocator.alloc(u8, size);
    defer std.testing.allocator.free(deserializeBuffer);

    const deserializedx = api.IVideoSize.deserialize(&data, deserializeBuffer);

    try std.testing.expectEqual(size, deserializedx[1]);
    try std.testing.expectEqual(data.len, deserializedx[2]);

    const deserialized = deserializedx[0];

    const serialize_size = deserialized.serializeSize();
    try std.testing.expectEqual(serialize_size, data.len);

    var writtenAgain: usize = 0;

    deserialized.cloneSize(&writtenAgain);

    try std.testing.expectEqual(size, writtenAgain);

    switch (deserialized) {
        .VideoSizeEmojiMarkup => {
            const video_size = deserialized.VideoSizeEmojiMarkup;
            try std.testing.expectEqual(423423423, video_size.emoji_id);
            try std.testing.expectEqualSlices(u32, &[_]u32{ 128, 128, 256 }, video_size.background_colors);
        },
        else => unreachable,
    }

    const clone_bytes = try allocator.alloc(u8, writtenAgain);
    defer allocator.free(clone_bytes);

    const clone = deserialized.clone(clone_bytes);

    try std.testing.expectEqual(size, clone[1]);

    switch (clone[0]) {
        .VideoSizeEmojiMarkup => {
            const video_size = deserialized.VideoSizeEmojiMarkup;
            try std.testing.expectEqual(423423423, video_size.emoji_id);
            try std.testing.expectEqualSlices(u32, &[_]u32{ 128, 128, 256 }, video_size.background_colors);
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

    var size = constructor.serializeSize();
    const dest = try allocator.alloc(u8, size);
    defer allocator.free(dest);

    const serialized = constructor.serialize(dest);

    try std.testing.expectEqual(serialized, size);

    size = 0;

    const deserialize_size = api.TL.deserializeSize(dest, &size);
    try std.testing.expectEqual(constructor.serializeSize(), deserialize_size);

    const deserializeBuffer = try std.testing.allocator.alloc(u8, size);
    defer std.testing.allocator.free(deserializeBuffer);

    const deserializedx = api.TL.deserialize(dest, deserializeBuffer);
    const deserialized = deserializedx[0];

    try std.testing.expectEqual(size, deserializedx[1]);
    try std.testing.expectEqual(constructor.serializeSize(), deserializedx[2]);

    var size_again: usize = 0;

    deserialized.cloneSize(&size_again);

    try std.testing.expectEqual(size, size_again);

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

    const clonebuf = try std.testing.allocator.alloc(u8, size_again);
    defer std.testing.allocator.free(clonebuf);

    const clone = deserialized.clone(clonebuf);

    try std.testing.expectEqual(size, clone[1]);

    switch (clone[0]) {
        .Message => {
            const message = clone[0].Message;

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
    const container = api.TL{ .MessageContainer = &.{ .messages = &[_]api.ProtoMessage{api.ProtoMessage{ .body = api.TL{ .InputPeerSelf = &api.InputPeerSelf{} }, .msg_id = 342423423543534, .seqno = 23 }} } };

    const sbuf = try std.testing.allocator.alloc(u8, container.serializeSize());
    defer std.testing.allocator.free(sbuf);

    const written = container.serialize(sbuf);

    try std.testing.expectEqual(written, sbuf.len);

    var size: usize = 0;

    const deserialized_read = api.TL.deserializeSize(sbuf, &size);

    try std.testing.expectEqual(sbuf.len, deserialized_read);

    const dbuf = try std.testing.allocator.alloc(u8, size);
    defer std.testing.allocator.free(dbuf);

    const deserializedx = api.TL.deserialize(sbuf, dbuf);
    const deserialized = deserializedx[0];

    try std.testing.expectEqual(size, deserializedx[1]);
    try std.testing.expectEqual(sbuf.len, deserializedx[2]);

    var size_again: usize = 0;

    deserialized.cloneSize(&size_again);

    try std.testing.expectEqual(size, size_again);

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

    const clonebuf = try std.testing.allocator.alloc(u8, size_again);
    defer std.testing.allocator.free(clonebuf);

    const clone = deserialized.clone(clonebuf);

    try std.testing.expectEqual(clone[1], size_again);

    switch (clone[0]) {
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
    const constructor = api.TL{ .RPCResult = &.{ .body = api.TL{ .ImportedContact = &api.ImportedContact{ .user_id = 432423423, .client_id = 342432432 } }, .req_msg_id = 929437432873425453 } };

    const sbuf = try std.testing.allocator.alloc(u8, constructor.serializeSize());
    defer std.testing.allocator.free(sbuf);

    const written = constructor.serialize(sbuf);

    try std.testing.expectEqual(sbuf.len, written);

    var size: usize = 0;

    const deserialized_read = api.TL.deserializeSize(sbuf, &size);

    try std.testing.expectEqual(sbuf.len, deserialized_read);

    const dbuf = try std.testing.allocator.alloc(u8, size);
    defer std.testing.allocator.free(dbuf);

    const deserializedx = api.TL.deserialize(sbuf, dbuf);
    const deserialized = deserializedx[0];

    try std.testing.expectEqual(size, deserializedx[1]);
    try std.testing.expectEqual(sbuf.len, deserializedx[2]);

    var size_again: usize = 0;

    deserialized.cloneSize(&size_again);

    try std.testing.expectEqual(size, size_again);

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

    const clonebuf = try std.testing.allocator.alloc(u8, size_again);
    defer std.testing.allocator.free(clonebuf);

    size_again = 0;

    const clone = deserialized.clone(clonebuf);

    try std.testing.expectEqual(size, clone[1]);

    switch (clone[0]) {
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

    const baseob = api.ProtoResPQ{ .nonce = 0, .pq = "", .server_nonce = 0, .server_public_key_fingerprints = &[_]u64{ 999900000000, 45346, 897225, 4543 } };

    var sbuf = try std.testing.allocator.alloc(u8, baseob.serializeSize());
    defer std.testing.allocator.free(sbuf);

    const ser_size = baseob.serialize(sbuf);

    const xsbuf = sbuf[36..ser_size];

    var size: usize = 0;

    const deser_read = api.TL.deserializeSize(xsbuf, &size);

    try std.testing.expectEqual(xsbuf.len, deser_read);

    const dbuf = try std.testing.allocator.alloc(u8, size);
    defer std.testing.allocator.free(dbuf);

    const deserializedx = api.TL.deserialize(xsbuf, dbuf);
    const deserialized = deserializedx[0];

    try std.testing.expectEqual(size, deserializedx[1]);
    try std.testing.expectEqual(ser_size - 36, deserializedx[2]);
    var size_again: usize = 0;

    deserialized.cloneSize(&size_again);

    try std.testing.expectEqual(size, size_again);

    switch (deserialized) {
        .Vector => {
            const vector = deserialized.Vector;
            try std.testing.expectEqual(4, vector.elements.len);
            try std.testing.expectEqual(999900000000, vector.elements[0].Long);
            try std.testing.expectEqual(45346, vector.elements[1].Long);
            try std.testing.expectEqual(897225, vector.elements[2].Long);
            try std.testing.expectEqual(4543, vector.elements[3].Long);
        },
        else => unreachable,
    }

    const clonebuf = try std.testing.allocator.alloc(u8, size_again);
    defer std.testing.allocator.free(clonebuf);

    size_again = 0;
    const cloned = deserialized.clone(clonebuf);

    try std.testing.expectEqual(size, cloned[1]);

    switch (cloned[0]) {
        .Vector => {
            const vector = cloned[0].Vector;
            try std.testing.expectEqual(4, vector.elements.len);
            try std.testing.expectEqual(999900000000, vector.elements[0].Long);
            try std.testing.expectEqual(45346, vector.elements[1].Long);
            try std.testing.expectEqual(897225, vector.elements[2].Long);
            try std.testing.expectEqual(4543, vector.elements[3].Long);
        },
        else => unreachable,
    }
}

test "Dynamic constructor" {
    const constructor = api.TL{ .InvokeWithLayer = &api.InvokeWithLayer{ .layer = 149, .query = api.TL{ .InvokeWithTakeout = &api.InvokeWithTakeout{ .takeout_id = 45, .query = .{ .InputUserSelf = &api.InputUserSelf{} } } } } };

    const sbuf = try std.testing.allocator.alloc(u8, constructor.serializeSize());
    defer std.testing.allocator.free(sbuf);

    const ser_size = constructor.serialize(sbuf);

    try std.testing.expectEqual(sbuf.len, ser_size);

    var size: usize = 0;

    const deser_size = api.TL.deserializeSize(sbuf, &size);
    try std.testing.expectEqual(ser_size, deser_size);

    const dbuf = try std.testing.allocator.alloc(u8, size);
    defer std.testing.allocator.free(dbuf);

    const deserializedx = api.TL.deserialize(sbuf, dbuf);

    const deserialized = deserializedx[0];

    try std.testing.expectEqual(size, deserializedx[1]);
    try std.testing.expectEqual(ser_size, deserializedx[2]);

    var size_again: usize = 0;

    deserialized.cloneSize(&size_again);

    try std.testing.expectEqual(size, size_again);

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

    const clonebuf = try std.testing.allocator.alloc(u8, size_again);
    defer std.testing.allocator.free(clonebuf);

    const clone = deserialized.clone(clonebuf);

    try std.testing.expectEqual(size, clone[1]);

    switch (clone[0]) {
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

test "vectors of strings" {
    const obj = api.TL{ .ChannelAdminLogEventActionChangeUsernames = &.{ .prev_value = &[_][]const u8{"test"}, .new_value = &[_][]const u8{ "test2", "hieveryone!!!!!!!!!!" } } };

    const sbuf = try std.testing.allocator.alloc(u8, obj.serializeSize());
    defer std.testing.allocator.free(sbuf);

    const ser_size = obj.serialize(sbuf);

    try std.testing.expectEqual(sbuf.len, ser_size);

    var size: usize = 0;

    const deser_read = api.TL.deserializeSize(sbuf, &size);

    try std.testing.expectEqual(sbuf.len, deser_read);

    const dbuf = try std.testing.allocator.alloc(u8, size);
    defer std.testing.allocator.free(dbuf);

    const deserializedx = api.TL.deserialize(sbuf, dbuf);

    const deserialized = deserializedx[0];

    try std.testing.expectEqual(size, deserializedx[1]);
    try std.testing.expectEqual(ser_size, deserializedx[2]);

    switch (deserialized) {
        .ChannelAdminLogEventActionChangeUsernames => |x| {
            try std.testing.expectEqualStrings("test", x.prev_value[0]);
            try std.testing.expectEqualStrings("test2", x.new_value[0]);
            try std.testing.expectEqualStrings("hieveryone!!!!!!!!!!", x.new_value[1]);
        },
        else => unreachable,
    }

    var size_again: usize = 0;

    deserialized.cloneSize(&size_again);

    try std.testing.expectEqual(size, size_again);

    const clonebuf = try std.testing.allocator.alloc(u8, size_again);
    defer std.testing.allocator.free(clonebuf);

    const clone = deserialized.clone(clonebuf);

    try std.testing.expectEqual(size, clone[1]);

    switch (clone[0]) {
        .ChannelAdminLogEventActionChangeUsernames => |x| {
            try std.testing.expectEqualStrings("test", x.prev_value[0]);
            try std.testing.expectEqualStrings("test2", x.new_value[0]);
            try std.testing.expectEqualStrings("hieveryone!!!!!!!!!!", x.new_value[1]);
        },
        else => unreachable,
    }
}
