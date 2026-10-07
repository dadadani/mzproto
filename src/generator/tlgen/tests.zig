const std = @import("std");
const base = @import("tl_base");
const storage = @import("storage");
const old = @import("storage_v1");
const telegram = @import("telegram");
const api = @import("tl");

test "basic constructor serialize & deserialize" {
    {
        const allocator = std.testing.allocator;

        const iself = api.InputUser{ .inputUserSelf = &api.inputUserSelf{} };

        const size = try iself.serializedSize();

        const dest = try allocator.alloc(u8, try iself.serializedSize());
        defer allocator.free(dest);

        const serialized = try iself.serialize(dest);

        try std.testing.expectEqual(size, serialized.len);

        const des = try api.InputUser.measure(dest);

        const b = try allocator.alignedAlloc(u8, .fromByteUnits(api.InputUser.out_alignment), des.object_bytes);
        defer allocator.free(b);

        const dec = try api.InputUser.decodeExact(serialized, b);

        const c = try allocator.alignedAlloc(u8, .fromByteUnits(api.InputUser.out_alignment), try api.InputUser.cloneSize(dec));

        const clon = try api.InputUser.cloneInto(dec, c);

        try std.testing.expectEqual(try api.InputUser.cloneSize(dec), clon.object_bytes);

        switch (dec) {
            .inputUserSelf => {},
            else => unreachable,
        }

        switch (clon.value) {
            .inputUserSelf => {},
            else => unreachable,
        }
    }
}

test "basic constructor with some fields serialize & deserialize" {
    const allocator = std.testing.allocator;

    {
        const constructor = api.InputFile{ .inputFile = &.{ .id = 123, .parts = 59535612, .name = "namefieldhere", .md5_checksum = "itworks!!!!0AA" } };

        const dest = try allocator.alloc(u8, try constructor.serializedSize());
        defer allocator.free(dest);

        const serialized = try constructor.serialize(dest);

        try std.testing.expectEqual(try constructor.serializedSize(), serialized.len);

        const deserialized_read = try api.InputFile.measure(dest);

        try std.testing.expectEqual(try constructor.serializedSize(), deserialized_read.tl_bytes);

        const b = try allocator.alignedAlloc(u8, .fromByteUnits(api.InputUser.out_alignment), deserialized_read.object_bytes);
        defer allocator.free(b);

        const dec = try api.InputFile.decodeExact(serialized, b);

        switch (dec) {
            .inputFile => {
                const input_file = dec.inputFile;
                try std.testing.expectEqual(123, input_file.id);
                try std.testing.expectEqual(59535612, input_file.parts);
                try std.testing.expectEqualStrings("namefieldhere", input_file.name);
                try std.testing.expectEqualStrings("itworks!!!!0AA", input_file.md5_checksum);
            },
            else => unreachable,
        }
    }
}

test "generated storage round trip, borrowed strings, lazy nested vectors and materialization" {
    const entity: storage.entity = .{ .offset = 2, .text = "hello" };
    const entities = [_]storage.Entity{.{ .entity = &entity }};
    const row = [_]u32{ 3, 4 };
    const nested = [_][]const u32{&row};
    const value: storage.metadata = .{ .active = true, .note = "note", .entities = &entities, .nested = &nested, .count = 7, .edited_at = 42 };
    var encoded: [4096]u8 = undefined;
    const bytes = try storage.metadata.serialize(2, &value, &encoded);
    try std.testing.expectEqual(bytes.len, try storage.metadata.serializedSize(2, &value));
    const view = try storage.metadata.view(2, bytes);
    try std.testing.expectEqual(@as(?u64, 42), try view.edited_at());
    try std.testing.expect(try view.active());
    try std.testing.expectEqual(@as(u32, 7), try view.count());
    const note = (try view.note()).?;
    try std.testing.expect(@intFromPtr(note.ptr) >= @intFromPtr(bytes.ptr));
    try std.testing.expect(@intFromPtr(note.ptr) + note.len <= @intFromPtr(bytes.ptr) + bytes.len);
    var iterator = (try view.entities()).iterator();
    const first = try (try iterator.next()).?.as(storage.entity);
    try std.testing.expectEqualStrings("hello", try first.text());
    try std.testing.expectEqual(@as(u32, 2), try first.offset());
    try std.testing.expectEqual(null, try iterator.next());
    var rows = (try view.nested()).iterator();
    var columns = (try rows.next()).?.iterator();
    try std.testing.expectEqual(@as(?u32, 3), try columns.next());
    try std.testing.expectEqual(@as(?u32, 4), try columns.next());
    try std.testing.expectEqual(null, try columns.next());
    try view.validateAll();
    const layout = try storage.metadata.measure(2, bytes);
    var memory: [4096]u8 align(storage.out_alignment) = undefined;
    const decoded = try storage.metadata.decodeInto(2, bytes, memory[0..layout.object_bytes]);
    try std.testing.expectEqual(layout.object_bytes, decoded.object_bytes);
    try std.testing.expectEqual(bytes.len, decoded.tl_bytes);
    try std.testing.expectEqualStrings("hello", decoded.value.entities[0].entity.text);
    try std.testing.expect(@intFromPtr(decoded.value.note.?.ptr) >= @intFromPtr(&memory));
    var cloned: [4096]u8 align(storage.out_alignment) = undefined;
    const size = try storage.metadata.cloneSize(decoded.value);
    const clone = try storage.metadata.cloneInto(decoded.value, cloned[0..size]);
    try std.testing.expectEqual(size, clone.object_bytes);
    @memset(&memory, 0);
    try std.testing.expectEqualStrings("hello", clone.value.entities[0].entity.text);
}

test "older storage records report new fields absent" {
    const value: old.metadata = .{ .entities = &.{}, .nested = &.{}, .count = 9 };
    var encoded: [256]u8 = undefined;
    const bytes = try old.metadata.serialize(1, &value, &encoded);
    const view = try storage.metadata.view(1, bytes);
    try std.testing.expectEqual(@as(u32, 1), view.storedVersion());
    try std.testing.expectEqual(@as(?u64, null), try view.edited_at());
    try std.testing.expectEqual(@as(u32, 9), try view.count());
    try view.validateAll();
    var bbuf: [512]u8 align(storage.out_alignment) = undefined;
    const decoded = try storage.metadata.decodeExact(1, bytes, &bbuf);
    try std.testing.expectEqual(@as(?u64, null), decoded.edited_at);
}

test "telegram primitives and generic request wrappers" {
    const value: telegram.primitives = .{ .i = 4, .l = 5, .d = -3.5, .big = 6, .bigger = 7, .boxed = 8, .yes = true, .bytes = "bytes" };
    var encoded: [256]u8 = undefined;
    const bytes = try telegram.primitives.serialize(&value, &encoded);
    const layout = try telegram.primitives.measure(bytes);
    var bbuf: [512]u8 align(telegram.out_alignment) = undefined;
    const decoded = try telegram.primitives.decodeInto(bytes, bbuf[0..layout.object_bytes]);
    try std.testing.expectEqual(@as(f64, -3.5), decoded.value.d);
    try std.testing.expectEqualStrings("bytes", decoded.value.bytes);
    const view = try telegram.primitives.view(bytes);
    try std.testing.expectEqual(value.d, try view.d());
    try std.testing.expectEqual(value.bigger, try view.bigger());
    try std.testing.expectEqual(value.boxed, try view.boxed());
    try std.testing.expectEqual(value.yes, try view.yes());
    try std.testing.expectEqualStrings(value.bytes, try view.bytes());
    try view.validateAll();
    const query: telegram.get = .{};
    const wrapper: telegram.invoke(telegram.get) = .{ .query = &query };
    const request = try telegram.invoke(telegram.get).serialize(&wrapper, &encoded);
    try std.testing.expectEqualSlices(u8, &.{ 7, 0, 0, 16, 6, 0, 0, 16 }, request);
    _ = telegram.invoke(telegram.get).TLResult;
}

test "bundled schemas generate usable standalone types" {
    const self: api.inputPeerSelf = .{};
    var encoded: [32]u8 = undefined;
    const bytes = try api.inputPeerSelf.serialize(&self, &encoded);
    try std.testing.expectEqualSlices(u8, &.{ 0xc9, 0x7e, 0xa0, 0x7d }, bytes);
    const ping: api.ping = .{ .ping_id = 42 };
    _ = try api.ping.serialize(&ping, &encoded);
    _ = @sizeOf(api.message);
    _ = @sizeOf(api.message.Decoded);
}

test "lazy views skip malformed vector elements until accessed or validated" {
    const item: storage.entity = .{ .offset = 1, .text = "x" };
    const values = [_]storage.Entity{.{ .entity = &item }};
    const value: storage.metadata = .{ .entities = &values, .nested = &.{}, .count = 77, .edited_at = 99 };
    var encoded: [512]u8 = undefined;
    const bytes = try storage.metadata.serialize(2, &value, &encoded);
    const initial = try storage.metadata.view(2, bytes);
    const vector = try initial.entities();
    // Corrupt the first element's constructor, leaving the vector frame valid.
    @memset(@constCast(vector.payload[0..4]), 0);
    const view = try storage.metadata.view(2, bytes);
    try std.testing.expectEqual(@as(u32, 77), try view.count());
    try std.testing.expectEqual(@as(?u64, 99), try view.edited_at());
    var iterator = (try view.entities()).iterator();
    try std.testing.expectError(error.InvalidConstructor, iterator.next());
    try std.testing.expectError(error.InvalidConstructor, view.validateAll());
    try std.testing.expectError(error.InvalidConstructor, storage.metadata.measure(2, bytes));
}

test "storage framing, unknown versions, count mismatch and truncated inputs" {
    const value: storage.metadata = .{ .entities = &.{}, .nested = &.{}, .count = 7, .edited_at = 9 };
    var encoded: [256]u8 = undefined;
    const bytes = try storage.metadata.serialize(2, &value, &encoded);
    for (0..bytes.len) |n| try std.testing.expectError(error.EndOfInput, storage.metadata.view(2, bytes[0..n]));
    try std.testing.expectError(error.UnsupportedVersion, storage.metadata.view(0, bytes));
    // A higher global version is valid when this constructor has no newer fields.
    try (try storage.metadata.view(99, bytes)).validateAll();
    encoded[bytes.len] = 0;
    try std.testing.expectError(error.InvalidData, storage.metadata.view(2, encoded[0 .. bytes.len + 1]));
    // No per-constructor upper version bound, but an incompatible layout is still invalid.
    try std.testing.expectError(error.InvalidData, (try old.metadata.view(2, bytes)).validateAll());
    // A zero-element vector with nonempty payload fails when exhausted.
    const E = base.Primitive(u32, null);
    const bad: base.VectorView(E) = .{ .count = 0, .payload = &.{0}, .depth = 0 };
    var it = bad.iterator();
    try std.testing.expectError(error.InvalidData, it.next());
    try std.testing.expectError(error.InvalidData, bad.validateAll());
}

test "unaligned wire bytes are fine; decoded bbuf must be aligned and sufficient" {
    const value: storage.entity = .{ .offset = 1, .text = "abc" };
    var encoded: [256]u8 align(16) = undefined;
    const bytes = try storage.entity.serialize(1, &value, encoded[1..]);
    const view = try storage.entity.view(1, bytes);
    try std.testing.expectEqualStrings("abc", try view.text());
    try view.validateAll();
    const layout = try storage.entity.measure(1, bytes);
    var bbuf: [512]u8 align(storage.out_alignment) = undefined;
    const bbuft = @typeInfo(@TypeOf(storage.entity.decodeInto)).@"fn".param_types[2].?;
    try std.testing.expect(bbuft == []align(storage.entity.out_alignment) u8);
    try std.testing.expectError(error.BufferTooSmall, storage.entity.decodeInto(1, bytes, bbuf[0 .. layout.object_bytes - 1]));
    const exact = try storage.entity.decodeInto(1, bytes, bbuf[0..layout.object_bytes]);
    try std.testing.expectEqual(layout.object_bytes, exact.object_bytes);
    for (0..bytes.len) |n| try std.testing.expectError(error.EndOfInput, storage.entity.measure(1, bytes[0..n]));
    try std.testing.expectError(error.BufferTooSmall, storage.entity.serialize(1, &value, encoded[0 .. bytes.len - 1]));
}

test "Telegram vectors, bare objects, boxed dispatch and flags" {
    const entity: telegram.entity = .{ .offset = 5, .text = "a" };
    const entities = [_]telegram.Entity{.{ .entity = &entity }};
    const row = [_]u32{ 8, 9 };
    const nested = [_][]const u32{&row};
    const value: telegram.metadata = .{ .entities = &entities, .nested = &nested, .count = 3, .bare = &entity };
    const boxed: telegram.Metadata = .{ .metadata = &value };
    var encoded: [512]u8 = undefined;
    const bytes = try telegram.Metadata.serialize(boxed, &encoded);
    const layout = try telegram.Metadata.measure(bytes);
    var bbuf: [2048]u8 align(telegram.out_alignment) = undefined;
    const decoded = try telegram.Metadata.decodeExact(bytes, bbuf[0..layout.object_bytes]);
    try std.testing.expectEqual(@as(u32, 9), decoded.metadata.nested[0][1]);
    try std.testing.expectEqualStrings("a", decoded.metadata.bare.text);
    for (0..bytes.len) |n| {
        if (telegram.Metadata.measure(bytes[0..n])) |_| return error.AcceptedTruncatedInput else |_| {}
    }
    const shared: telegram.shared = .{ .active = true, .value = null };
    try std.testing.expectError(error.InconsistentFlags, telegram.shared.serializedSize(&shared));
    try std.testing.expectError(error.InconsistentFlags, telegram.shared.serialize(&shared, &encoded));
    const consistent: telegram.shared = .{ .active = true, .value = 8 };
    const shared_bytes = try telegram.shared.serialize(&consistent, &encoded);
    try std.testing.expectEqualSlices(u8, &.{ 5, 0, 0, 16, 2, 0, 0, 0, 8, 0, 0, 0 }, shared_bytes);
}

test "cursor primitives are checked" {

    var bad = base.cursor.Deserializer.init(&.{255});
    try std.testing.expectError(error.InvalidData, bad.bytes(.telegram));
    var wrong_bool = base.cursor.Deserializer.init(&.{ 0, 0, 0, 0 });
    try std.testing.expectError(error.InvalidConstructor, wrong_bool.boolean());
    var wrong_vector = base.cursor.Deserializer.init(&.{ 0, 0, 0, 0 });
    try std.testing.expectError(error.InvalidConstructor, wrong_vector.vectorHeader(.boxed));
    var negative_count = base.cursor.Deserializer.init(&.{ 255, 255, 255, 255 });
    try std.testing.expectError(error.InvalidData, negative_count.vectorHeader(.bare));
    var empty = base.cursor.Serializer.init(&.{});
    try std.testing.expectError(error.BufferTooSmall, empty.int(1));
    var overflow = base.cursor.Serializer.measuring();
    overflow.position = std.math.maxInt(usize);
    try std.testing.expectError(error.Overflow, overflow.int(1));
}

test "all bundled constructor layouts resolve" {
    comptime {
        @setEvalBranchQuota(1000000);
        for (api.mztl_constructors) |C| {
            _ = @sizeOf(C);
            _ = @sizeOf(C.Decoded);
            for (C.tl_fields) |F| {
                _ = @sizeOf(F.Spec.Write);
                _ = @sizeOf(F.Spec.Read);
            }
        }
    }
}

test "MTProto future salts use a bare vector of bare constructors" {
    const salt: api.future_salt = .{ .valid_since = 1, .valid_until = 2, .salt = 3 };
    const salts = [_]*const api.future_salt{&salt};
    const value: api.future_salts = .{ .req_msg_id = 4, .now = 5, .salts = &salts };
    var output: [128]u8 = undefined;
    const bytes = try api.future_salts.serialize(&value, &output);
    try std.testing.expectEqual(@as(usize, 36), bytes.len);
    const layout = try api.future_salts.measure(bytes);
    var bbuf: [1024]u8 align(api.out_alignment) = undefined;
    const decoded = try api.future_salts.decodeExact(bytes, bbuf[0..layout.object_bytes]);
    try std.testing.expectEqual(@as(u64, 3), decoded.salts[0].salt);
}

test "MTProto envelopes borrow bodies and preserve RPC result context" {
    const mt = api.proto;
    const body = [_]u8{ 1, 2, 3, 4 };
    const messages = [_]mt.Message{.{ .msg_id = 9, .seqno = 1, .body = &body }};
    var output: [256]u8 = undefined;
    const bytes = try mt.MessageContainer.serialize(&messages, &output);
    try std.testing.expectEqual(bytes.len, try mt.MessageContainer.serializedSize(&messages));
    const view = try mt.MessageContainer.view(bytes);
    try view.validateAll();
    var it = view.iterator();
    const message = (try it.next()).?;
    try std.testing.expectEqualSlices(u8, &body, message.body);
    try std.testing.expectEqual(@intFromPtr(bytes.ptr) + 24, @intFromPtr(message.body.ptr));
    try std.testing.expectEqual(null, try it.next());
    const rpc: mt.RpcResult = .{ .req_msg_id = 8, .body = &body };
    const result_bytes = try rpc.serialize(&output);
    const result = try mt.RpcResult.view(result_bytes);
    try std.testing.expectEqual(@as(u64, 8), result.req_msg_id);
    try std.testing.expectEqualSlices(u8, &body, result.body);
    const failure: api.rpc_error = .{ .error_code = 400, .error_message = "BAD_REQUEST" };
    const failure_bytes = try api.rpc_error.serialize(&failure, &output);
    try std.testing.expectEqualStrings("BAD_REQUEST", try (try api.rpc_error.view(failure_bytes)).error_message());
}

test "MTProto identification includes built-in envelopes and generated constructors" {
    @setEvalBranchQuota(20_000_000);
    const Identify = api.proto.IdentifyFn(api);

    try std.testing.expect(Identify.identify(&.{ 1, 2, 3 }) == null);
    try std.testing.expect(Identify.identifyId(0) == null);
    try std.testing.expectEqual(Identify.Identification.rpcResult, Identify.identifyId(api.proto.RpcResult.id).?);
    try std.testing.expectEqual(Identify.Identification.messageContainer, Identify.identifyId(api.proto.MessageContainer.id).?);
    try std.testing.expectEqual(api.proto.RpcResult.id, @intFromEnum(Identify.Identification.rpcResult));
    try std.testing.expectEqual(api.proto.MessageContainer.id, @intFromEnum(Identify.Identification.messageContainer));

    const ping_response = Identify.identifyId(api.pong.tl_id).?;
    try std.testing.expectEqual(Identify.Identification.pong, ping_response);
    const scoped = Identify.identifyId(api.@"updates.state".tl_id).?;
    try std.testing.expectEqual(Identify.Identification.@"updates.state", scoped);
    try std.testing.expectEqual(api.pong.tl_id, @intFromEnum(ping_response));

    var bytes: [4]u8 = undefined;
    std.mem.writeInt(u32, &bytes, api.pong.tl_id, .little);
    try std.testing.expectEqual(ping_response, Identify.identify(&bytes).?);
    std.mem.writeInt(u32, &bytes, api.proto.RpcResult.id, .little);
    try std.testing.expectEqual(Identify.Identification.rpcResult, Identify.identify(&bytes).?);
    std.mem.writeInt(u32, &bytes, api.proto.MessageContainer.id, .little);
    try std.testing.expectEqual(Identify.Identification.messageContainer, Identify.identify(&bytes).?);
    std.mem.writeInt(u32, &bytes, 0, .little);
    try std.testing.expect(Identify.identify(&bytes) == null);

    const object = @typeInfo(api.AnyObject).@"union";
    inline for (object.field_names, object.field_types) |name, Field| {
        const C = @typeInfo(Field).pointer.child;
        const found = Identify.identifyId(C.tl_id).?;
        try std.testing.expectEqual(@field(Identify.Identification, name), found);
        try std.testing.expectEqual(C.tl_id, @intFromEnum(found));
    }
}

test "Telegram constructors encode strings vectors and flags" {
    var output: [1024]u8 = undefined;
    const file: api.inputFile = .{ .id = 1, .parts = 2, .name = "name", .md5_checksum = "md5" };
    try std.testing.expectEqualSlices(u8, &.{
        0x7f, 0xf2, 0x2f, 0xf5, // inputFile
        1, 0, 0, 0, 0, 0, 0, 0, // id
        2,   0,   0,   0, // parts
        4,   'n', 'a', 'm',
        'e', 0,   0,   0,
        3,   'm', 'd', '5',
    }, try api.inputFile.serialize(&file, &output));

    const ids = [_]u64{ 1, 2, 100 };
    const ack: api.msgs_ack = .{ .msg_ids = &ids };
    try std.testing.expectEqualSlices(u8, &.{
        0x59, 0xb4, 0xd6, 0x62, // msgs_ack
        0x15, 0xc4, 0xb5, 0x1c, // Vector<long>
        3,    0,    0,    0,
        1,    0,    0,    0,
        0,    0,    0,    0,
        2,    0,    0,    0,
        0,    0,    0,    0,
        100,  0,    0,    0,
        0,    0,    0,    0,
    }, try api.msgs_ack.serialize(&ack, &output));

    const dc: api.dcOption = .{ .ipv6 = true, .media_only = true, .id = 2, .ip_address = "::1", .port = 443, .secret = "secret" };
    try std.testing.expectEqualSlices(u8, &.{
        0x0d, 0xa1, 0xb7, 0x18, // dcOption
        3, 4, 0, 0, // flags: ipv6, media_only, secret
        2, 0, 0, 0, // id
        3, ':', ':', '1', // ip_address
        0xbb, 1,   0,   0, // port
        6,    's', 'e', 'c',
        'r',  'e', 't', 0,
    }, try api.dcOption.serialize(&dc, &output));
}

test "nested objects have the caller-supplied global storage version" {
    const child: old.evolving = .{ .value = 12 };
    const value: old.holder = .{ .child = .{ .evolving = &child }, .tail = 34 };
    var output: [256]u8 = undefined;
    const bytes = try old.holder.serialize(1, &value, &output);
    const view = try storage.holder.view(1, bytes);
    const child_view = try (try view.child()).as(storage.evolving);
    try std.testing.expectEqual(@as(?[]const u8, null), try child_view.tag());
    try std.testing.expectEqual(@as(u32, 34), try view.tail());
    try view.validateAll();
    const newer_child: storage.evolving = .{ .value = 56, .tag = "new" };
    const newer: storage.holder = .{ .child = .{ .evolving = &newer_child }, .tail = 78 };
    const new_bytes = try storage.holder.serialize(5, &newer, &output);
    const new_view = try storage.holder.view(5, new_bytes);
    try std.testing.expectEqual(@as(u32, 5), new_view.storedVersion());
    const nested = try (try new_view.child()).as(storage.evolving);
    try std.testing.expectEqual(@as(u32, 5), nested.storedVersion());
    try std.testing.expectEqualStrings("new", (try nested.tag()).?);
}

test "generic wrappers inherit a usable typed response codec" {
    const e: telegram.entity = .{ .offset = 1, .text = "answer" };
    const response: telegram.metadata = .{ .entities = &.{}, .nested = &.{}, .count = 19, .bare = &e };
    var output: [512]u8 = undefined;
    const bytes = try telegram.metadata.serialize(&response, &output);
    const Wrapper = telegram.invoke(telegram.invoke(telegram.get));
    const layout = try Wrapper.TLResult.measure(bytes);
    var memory: [1024]u8 align(telegram.out_alignment) = undefined;
    const result = try Wrapper.TLResult.decodeExact(bytes, memory[0..layout.object_bytes]);
    try std.testing.expectEqual(@as(u32, 19), result.metadata.count);
    try std.testing.expectEqualStrings("answer", result.metadata.bare.text);
}

test "full Telegram Message union decoder compiles and reads a real constructor" {
    const message: api.messageEmpty = .{ .id = 123 };
    var output: [128]u8 = undefined;
    const bytes = try api.messageEmpty.serialize(&message, &output);
    const layout = try api.Message.measure(bytes);
    var memory: [1024]u8 align(api.out_alignment) = undefined;
    const decoded = try api.Message.decodeExact(bytes, memory[0..layout.object_bytes]);
    try std.testing.expectEqual(@as(u32, 123), decoded.messageEmpty.id);
}

test "cursor recursion and allocation arithmetic fail explicitly" {
    var writer = base.cursor.Serializer.measuring();
    var reader = base.cursor.Deserializer.init(&.{});
    for (0..128) |_| {
        try writer.enter();
        try reader.enter();
    }
    try std.testing.expectError(error.DepthLimit, writer.enter());
    try std.testing.expectError(error.DepthLimit, reader.enter());
    var memory = try base.cursor.ObjectBuffer(.measure).init(&.{});
    try std.testing.expectError(error.Overflow, memory.alloc(u64, std.math.maxInt(usize)));
}

test "runtime target version omits populated later fields and requires active payloads" {
    var value: storage.evolving = .{ .value = 12, .tag = "ignored for old version" };
    var output: [128]u8 = undefined;
    const v1 = try storage.evolving.serialize(1, &value, &output);
    // ID + payload length + value, with no root or nested version word.
    try std.testing.expectEqualSlices(u8, &.{ 3, 0, 0, 16, 4, 0, 0, 0, 12, 0, 0, 0 }, v1);
    try std.testing.expectEqual(@as(?[]const u8, null), try (try storage.evolving.view(1, v1)).tag());
    value.tag = null;
    try std.testing.expectEqual(v1.len, try storage.evolving.serializedSize(2, &value));
    try std.testing.expectError(error.MissingRequiredField, storage.evolving.serializedSize(3, &value));
    try std.testing.expectError(error.MissingRequiredField, storage.evolving.serialize(3, &value, &output));
    const older_bytes = try storage.evolving.serialize(1, &value, &output);
    try std.testing.expectError(error.EndOfInput, (try storage.evolving.view(3, older_bytes)).validateAll());
    try std.testing.expectError(error.UnsupportedVersion, storage.evolving.serialize(0, &value, &output));
    try std.testing.expectError(error.UnsupportedVersion, storage.evolving.measure(0, v1));
}

test "global version propagates through bare objects and lazy vectors" {
    const child: storage.evolving = .{ .value = 21, .tag = "new" };
    const items = [_]*const storage.evolving{&child};
    const value: storage.versionTree = .{ .items = &items, .child = &child };
    for ([_]u32{ 1, 2, 3, 5, 100 }) |version| {
        var output: [256]u8 = undefined;
        const bytes = try storage.versionTree.serialize(version, &value, &output);
        const view = try storage.versionTree.view(version, bytes);
        var it = (try view.items()).iterator();
        const element = (try it.next()).?;
        try std.testing.expectEqual(version, element.storedVersion());
        if (version < 3) try std.testing.expectEqual(@as(?[]const u8, null), try element.tag()) else try std.testing.expectEqualStrings("new", (try element.tag()).?);
        try (try view.items()).validateAll();
        try view.validateAll();
        try std.testing.expectEqual(version, (try view.child()).storedVersion());
        const layout = try storage.versionTree.measure(version, bytes);
        var bbuf: [1024]u8 align(storage.out_alignment) = undefined;
        const decoded = try storage.versionTree.decodeInto(version, bytes, bbuf[0..layout.object_bytes]);
        try std.testing.expectEqual(layout.object_bytes, decoded.object_bytes);
        try std.testing.expectEqual(version >= 3, decoded.value.items[0].tag != null);
        try std.testing.expectEqual(version >= 3, decoded.value.child.tag != null);
    }
}

test "versioned flag fields and flag words remain optional when active" {
    const value: storage.versionFlags = .{ .marked = true, .note = "note", .extra = 7 };
    for ([_]u32{ 1, 2, 3, 5 }) |version| {
        var output: [256]u8 = undefined;
        const bytes = try storage.versionFlags.serialize(version, &value, &output);
        const view = try storage.versionFlags.view(version, bytes);
        try view.validateAll();
        try std.testing.expectEqual(if (version < 2) @as(?bool, null) else true, try view.marked());
        try std.testing.expectEqual(version >= 2, (try view.note()) != null);
        try std.testing.expectEqual(version >= 3, (try view.extra()) != null);
        var bbuf: [512]u8 align(storage.out_alignment) = undefined;
        const decoded = try storage.versionFlags.decodeExact(version, bytes, &bbuf);
        try std.testing.expectEqual(try view.marked(), decoded.marked);
        try std.testing.expectEqual(try view.extra(), decoded.extra);
    }
    var output: [128]u8 = undefined;
    const absent: storage.versionFlags = .{};
    const bytes = try storage.versionFlags.serialize(5, &absent, &output);
    const view = try storage.versionFlags.view(5, bytes);
    try std.testing.expectEqual(@as(?bool, false), try view.marked());
    try std.testing.expectEqual(@as(?[]const u8, null), try view.note());
    try view.validateAll();
}

test "bbuf alignment follows nested allocations, unions and recursive vectors" {
    const expected = @alignOf(u256);
    try std.testing.expectEqual(@alignOf(telegram.small.Decoded), telegram.small.out_alignment);
    try std.testing.expectEqual(expected, telegram.wide.out_alignment);
    try std.testing.expectEqual(expected, telegram.holder.out_alignment);
    try std.testing.expectEqual(expected, telegram.Choice.out_alignment);
    try std.testing.expectEqual(expected, telegram.recursive.out_alignment);
    try std.testing.expectEqual(expected, telegram.wideVector.out_alignment);

    const wide: telegram.wide = .{ .value = 123 };
    const value: telegram.holder = .{ .child = &wide };
    var wire: [256]u8 = undefined;
    const bytes = try telegram.holder.serialize(&value, &wire);
    const layout = try telegram.holder.measure(bytes);
    var bbuf: [256]u8 align(telegram.holder.out_alignment) = undefined;
    const decoded = try telegram.holder.decodeInto(bytes, bbuf[0..layout.object_bytes]);
    try std.testing.expectEqual(layout.object_bytes, decoded.object_bytes);
    try std.testing.expectEqual(123, decoded.value.child.value);
    var copy: [256]u8 align(telegram.holder.out_alignment) = undefined;
    const clone = try telegram.holder.cloneInto(decoded.value, &copy);
    try std.testing.expectEqual(123, clone.value.child.value);

    const Vector = base.TLValue(base.Vector(base.Primitive(u256, null), .bare), .telegram);
    try std.testing.expectEqual(expected, Vector.out_alignment);
    const items = [_]u256{ 1, 2, 3 };
    const vector_bytes = try Vector.serialize(&items, &wire);
    const vector_layout = try Vector.measure(vector_bytes);
    const result = try Vector.decodeInto(vector_bytes, &bbuf);
    try std.testing.expectEqual(vector_layout.object_bytes, result.object_bytes);
    try std.testing.expectEqualSlices(u256, &items, result.value);
}

test "AnyFunction dispatches concrete requests and nested wrappers with expected results" {
    const query: telegram.get = .{};
    const inner: telegram.AnyFunction = .{ .get = &query };
    const wrapper: telegram.invoke(telegram.AnyFunction) = .{ .query = inner };
    const middle: telegram.AnyFunction = .{ .invoke = &wrapper };
    const outer: telegram.invoke(telegram.AnyFunction) = .{ .query = middle };
    const request: telegram.AnyFunction = .{ .invoke = &outer };
    try std.testing.expectEqual(query.resultOps().decodeInto, request.resultOps().decodeInto);

    var wire: [1024]u8 = undefined;
    const bytes = try telegram.AnyFunction.serialize(request, &wire);
    const typed_inner: telegram.invoke(telegram.get) = .{ .query = &query };
    const TypedOuter = telegram.invoke(telegram.invoke(telegram.get));
    const typed_outer: TypedOuter = .{ .query = &typed_inner };
    var reference: [1024]u8 = undefined;
    try std.testing.expectEqualSlices(u8, try TypedOuter.serialize(&typed_outer, &reference), bytes);
    const layout = try telegram.AnyFunction.measure(bytes);
    var bbuf: [2048]u8 align(telegram.AnyFunction.out_alignment) = undefined;
    const decoded = try telegram.AnyFunction.decodeExact(bytes, bbuf[0..layout.object_bytes]);
    try std.testing.expectEqual(request.resultOps().decodeInto, decoded.resultOps().decodeInto);
    var clone_space: [2048]u8 align(telegram.AnyFunction.out_alignment) = undefined;
    const clone = try telegram.AnyFunction.cloneInto(decoded, &clone_space);
    try std.testing.expectEqual(request.resultOps().decodeInto, clone.value.resultOps().decodeInto);

    const entity: telegram.entity = .{ .offset = 1, .text = "response" };
    const value: telegram.metadata = .{ .entities = &.{}, .nested = &.{}, .count = 9, .bare = &entity };
    const response_bytes = try telegram.metadata.serialize(&value, &wire);
    const expected = request.resultOps();
    const response_layout = try expected.measure(response_bytes);
    var response_space: [2048]u8 align(64) = undefined;
    const response = try expected.decodeExact(response_bytes, response_space[0..response_layout.object_bytes]);
    try std.testing.expectEqual(9, (try response.from(telegram.get)).metadata.count);
    try std.testing.expectEqualStrings("response", (try response.from(telegram.get)).metadata.bare.text);
    try std.testing.expectError(error.InvalidConstructor, telegram.AnyFunction.decodeExact(response_bytes, &bbuf));
}

test "dynamic function results decode bare primitives and vectors" {
    const number_query: telegram.getNumber = .{};
    const number: telegram.AnyFunction = .{ .getNumber = &number_query };
    var wire: [256]u8 = undefined;
    const bytes = try telegram.getNumber.TLResult.serialize(42, &wire);
    var bbuf: [256]u8 align(64) = undefined;
    const result = try number.resultOps().decodeExact(bytes, &bbuf);
    try std.testing.expectEqual(42, try result.from(telegram.getNumber));
    try std.testing.expectEqual(@sizeOf(u32), (try number.resultOps().measure(bytes)).object_bytes);

    const vector_query: telegram.getNumbers = .{};
    const vector: telegram.AnyFunction = .{ .getNumbers = &vector_query };
    const items = [_]u32{ 10, 20 };
    const vector_bytes = try telegram.getNumbers.TLResult.serialize(&items, &wire);
    const decoded = try vector.resultOps().decodeExact(vector_bytes, &bbuf);
    try std.testing.expectEqualSlices(u32, &items, try decoded.from(telegram.getNumbers));
}

test "full Telegram schema exposes dynamic functions and result mappings" {
    const ping: api.ping = .{ .ping_id = 123 };
    const query: api.AnyFunction = .{ .ping = &ping };
    const wrapped: api.invokeWithLayer(api.AnyFunction) = .{ .layer = 1, .query = query };
    const request: api.AnyFunction = .{ .invokeWithLayer = &wrapped };
    var wire: [256]u8 = undefined;
    const bytes = try api.AnyFunction.serialize(request, &wire);
    try std.testing.expectEqual(@as(usize, 20), bytes.len);
    try std.testing.expect(request.resultOps().out_alignment >= api.ping.TLResult.out_alignment);
    const pong: api.pong = .{ .msg_id = 1, .ping_id = 123 };
    const response_bytes = try api.pong.serialize(&pong, &wire);
    var bbuf: [256]u8 align(64) = undefined;
    const expected = request.resultOps();
    const layout = try expected.measure(response_bytes);
    const response = try expected.decodeExact(response_bytes, bbuf[0..layout.object_bytes]);
    try std.testing.expectEqual(123, (try response.from(api.ping)).pong.ping_id);
}

test "result operations retain no request and check type, capacity, alignment and trailing bytes" {
    const ops = blk: {
        const request: telegram.getNumbers = .{};
        break :blk request.resultOps();
    };
    var wire: [128]u8 = undefined;
    const values = [_]u32{ 3, 8 };
    const bytes = try telegram.getNumbers.TLResult.serialize(&values, &wire);
    const layout = try ops.measure(bytes);
    var bbuf: [256]u8 align(64) = undefined;
    try std.testing.expectError(error.MisalignedOutputBuffer, ops.decodeInto(bytes, bbuf[1..]));
    try std.testing.expectError(error.BufferTooSmall, ops.decodeInto(bytes, bbuf[0 .. layout.object_bytes - 1]));
    const decoded = try ops.decodeInto(bytes, bbuf[0..layout.object_bytes]);
    try std.testing.expectEqual(layout.object_bytes, decoded.object_bytes);
    try std.testing.expectEqual(layout.tl_bytes, decoded.tl_bytes);
    try std.testing.expectError(error.UnexpectedResultType, decoded.from(telegram.getNumber));
    @memset(&wire, 0);
    try std.testing.expectEqualSlices(u32, &values, try decoded.from(telegram.getNumbers));

    const again = try telegram.getNumbers.TLResult.serialize(&values, &wire);
    wire[again.len] = 0;
    try std.testing.expectError(error.InvalidData, ops.decodeExact(wire[0 .. again.len + 1], &bbuf));
    const prefix = try ops.decodeInto(wire[0 .. again.len + 1], &bbuf);
    try std.testing.expectEqual(again.len, prefix.tl_bytes);
    try std.testing.expectError(error.EndOfInput, ops.measure(again[0..3]));
}

test "erased results account for root alignment and runtime bbuf allocation" {
    const Function = struct {
        pub const Result = base.Vector(base.Primitive(u256, null), .bare);
    };
    const ops = base.ResultOps.forType(Function);
    const values = [_]u256{ 1, 2 };
    const Val = base.TLValue(Function.Result, .telegram);
    var wire: [256]u8 = undefined;
    const bytes = try Val.serialize(&values, &wire);
    const layout = try ops.measure(bytes);
    const alignment: std.mem.Alignment = .fromByteUnits(ops.out_alignment);
    const ptr = std.testing.allocator.rawAlloc(layout.object_bytes, alignment, @returnAddress()) orelse return error.OutOfMemory;
    const bbuf = ptr[0..layout.object_bytes];
    defer std.testing.allocator.rawFree(bbuf, alignment, @returnAddress());
    const decoded = try ops.decodeExact(bytes, bbuf);
    try std.testing.expectEqual(layout.object_bytes, decoded.object_bytes);
    try std.testing.expectEqualSlices(u256, &values, try decoded.from(Function));
    try std.testing.expect(ops.out_alignment >= @alignOf(u256));
}

test "basic Telegram views borrow normal TL strings and validate lazily" {
    var text: [300]u8 = @splat('x');
    for ([_]usize{ 0, 3, 253, 254, 300 }) |len| {
        const value: telegram.entity = .{ .offset = 17, .text = text[0..len] };
        var wire: [512]u8 = undefined;
        const bytes = try telegram.entity.serialize(&value, wire[1..]);
        const view = try telegram.entity.view(bytes);
        try std.testing.expectEqual(17, try view.offset());
        const borrowed = try view.text();
        try std.testing.expectEqualStrings(text[0..len], borrowed);
        try std.testing.expect(@intFromPtr(borrowed.ptr) >= @intFromPtr(bytes.ptr));
        try std.testing.expect(@intFromPtr(borrowed.ptr) + borrowed.len <= @intFromPtr(bytes.ptr) + bytes.len);
        try view.validateAll();
        const boxed = try telegram.Entity.view(bytes);
        try std.testing.expectEqualStrings(text[0..len], try (try boxed.as(telegram.entity)).text());
        try boxed.validateAll();
        if (len != 0) {
            const truncated = try telegram.entity.view(bytes[0 .. bytes.len - 1]);
            try std.testing.expectEqual(17, try truncated.offset());
            try std.testing.expectError(error.EndOfInput, truncated.text());
            try std.testing.expectError(error.EndOfInput, truncated.validateAll());
        }
        wire[1 + bytes.len] = 0;
        const trailing = try telegram.entity.view(wire[1 .. 2 + bytes.len]);
        try std.testing.expectError(error.InvalidData, trailing.validateAll());
    }
}

test "Telegram basic views handle flags and reject nested layouts" {
    var wire: [256]u8 = undefined;
    for ([_]bool{ false, true }) |present| {
        const value: telegram.shared = .{ .active = present, .value = if (present) 42 else null };
        const bytes = try telegram.shared.serialize(&value, &wire);
        const view = try telegram.shared.view(bytes);
        try std.testing.expectEqual(present, try view.active());
        try std.testing.expectEqual(value.value, try view.value());
        try view.validateAll();
    }
    const wide: telegram.wide = .{ .value = 1 };
    const holder: telegram.holder = .{ .child = &wide };
    const bytes = try telegram.holder.serialize(&holder, &wire);
    try std.testing.expectError(error.UnsupportedView, telegram.holder.view(bytes));
    try std.testing.expectError(error.UnsupportedView, telegram.AnyObject.view(bytes));
    try std.testing.expectError(error.InvalidConstructor, telegram.entity.view(bytes));
    try std.testing.expectError(error.EndOfInput, telegram.entity.view(bytes[0..3]));
}
