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

const tl = @import("../tl/api.zig");
const std = @import("std");
const Transport = @import("../transport.zig").Transport;
const MessageID = @import("./message_id.zig");
const ige = @import("../crypto/ige.zig").ige;
const utils = @import("./utils.zig");
const deserializeStringNoCopy = @import("../tl/base.zig").deserializeStringNoCopy;

pub fn isContentRelated(obj: tl.TL) bool {
    return switch (obj) {

        // A client must never mark msgs_ack, msg_container, msg_copy, gzip_packed constructors (i.e. containers and acknowledgements)
        // as content-related, or else a bad_msg_notification with error_code=34 will be emitted.
        .ProtoRpcDropAnswer,
        .ProtoRpcAnswerUnknown,
        .ProtoRpcAnswerDroppedRunning,
        .ProtoRpcAnswerDropped,
        .ProtoGetFutureSalts,
        .ProtoFutureSalt,
        .ProtoFutureSalts,
        .ProtoPing,
        .ProtoPong,
        .ProtoPingDelayDisconnect,
        .ProtoDestroySession,
        .ProtoDestroySessionOk,
        .ProtoDestroySessionNone,
        .ProtoMessageContainer,
        .ProtoGzipPacked,
        .ProtoHttpWait,
        .ProtoMsgsAck,
        .ProtoBadMsgNotification,
        .ProtoBadServerSalt,
        .ProtoMsgsStateReq,
        .ProtoMsgsStateInfo,
        .ProtoMsgsAllInfo,
        .ProtoMsgDetailedInfo,
        .ProtoMsgNewDetailedInfo,
        .ProtoMsgResendReq,
        => false,

        // A client must always mark all API-level RPC queries as content-related,
        // or else a bad_msg_notification with error_code=35 will be emitted.
        else => true,
    };
}

const Session = @This();

const PendingRequest = struct {
    event: std.Io.Event = .unset,
    data: union(enum) { none: struct {}, data: []u8, rpc_error: struct { *tl.ProtoRpcError, []u8 } } = .{ .none = .{} },
};

dc_id: u8,
is_media: bool,
is_test_mode: bool,
is_cdn: bool,

seq_no: usize,

salts: std.ArrayList(tl.ProtoFutureSalt),

pending_ack: std.ArrayList(u64),

//salt: tl.ProtoFutureSalt,
auth_key: [256]u8,
auth_key_id: [8]u8,
session_id: u64,
message_id: MessageID,
arena: std.heap.ArenaAllocator,
pending_requests_idmap: std.AutoArrayHashMapUnmanaged(u64, u32),
pending_requests: struct {
    map: std.AutoArrayHashMapUnmanaged(u32, PendingRequest),
    mutex: std.Io.Mutex,

    pub fn create(self: *@This(), io: std.Io, allocator: std.mem.Allocator, id: u32) !*PendingRequest {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);

        const req = try self.map.getOrPut(allocator, id);
        if (req.found_existing)
            return req.value_ptr;

        req.value_ptr.* = .{};
        return req.value_ptr;
    }

    pub fn destroyItem(self: *@This(), allocator: std.mem.Allocator, io: std.Io, id: u32) void {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);

        if (self.map.get(id)) |req| {
            switch (req.data) {
                .data => |data| {
                    allocator.free(data);
                },
                else => {},
            }
        }

        _ = self.map.swapRemove(id);
    }
},
requests_queue: std.Io.Queue(struct {
    id: u32,
    data: []u8,
    data_len: usize,
    content_related: bool,
}),
current_id: std.atomic.Value(u32) = .init(0),

pub const EncryptionError = error{
    AuthKeyMismatch,
    MsgKeyMismatch,
    SessionIdMismatch,
    PaddingMismatch,
};

pub const SessionError = error{
    Transport404,
    TransportUnknown,
    UnknownIncomingMessage,
};

pub const SendError = error{ NotFunction, Unknown };

/// Generates the next sequence number for a message.
/// Returns the seqno to use and updates the internal counter if content-related.
fn nextSeqNo(self: *Session, is_content_related: bool) u32 {
    // The seqno of a content-related message is msg.seqNo = (current_seqno*2)+1
    // (and after generating it, the local current_seqno counter must be incremented by 1),
    // the seqno of a non-content related message is msg.seqNo = (current_seqno*2)
    // (current_seqno must not be incremented by 1 after generation).
    const seqno: u32 = @intCast(self.seq_no * 2);
    if (is_content_related) {
        self.seq_no += 1;
        return seqno + 1;
    }
    return seqno;
}

pub fn sendMessageTransport(self: *Session, transport: *Transport, io: std.Io, allocator: std.mem.Allocator, obj: tl.TL) !void {
    self.seq_no = self.nextSeqNo(isContentRelated(obj));

    const ser = try allocator.alloc(u8, obj.serializeSize());
    defer allocator.free(ser);

    const ser_len = obj.serialize(ser);

    const encrypted = try self.encryptMessage(allocator, ser[0..ser_len], self.seq_no, try self.message_id.get(io));
    defer allocator.free(encrypted);

    try transport.write(encrypted);
}

fn handleMsgsAck(self: *Session, message: tl.ProtoMessage) !void {
    _ = self;
    _ = message;
}

fn handleBadNotification(self: *Session, io: std.Io, message: tl.ProtoMessage) !void {
    var size: usize = 0;
    _ = tl.IProtoBadMsgNotification.deserializeSize(message.body, &size);
    const allocator = self.arena.allocator();

    const buf = try allocator.alloc(u8, size);
    defer allocator.free(buf);

    const bad_msg, _, _ = tl.IProtoBadMsgNotification.deserialize(message.body, buf);

    switch (bad_msg) {
        .ProtoBadServerSalt => |x| {
            self.salts.clearAndFree(allocator);
            try self.salts.append(allocator, .{
                .salt = x.new_server_salt,
                .valid_since = @intCast(try self.message_id.getUnix(io)),
                .valid_until = std.math.maxInt(i32),
            });
        },
        .ProtoBadMsgNotification => |x| {
            switch (x.error_code) {
                // msg_id too low (most likely, client time is wrong;
                // it would be worthwhile to synchronize it using msg_id notifications
                // and re-send the original message with the “correct” msg_id or wrap it in a
                // container with a new msg_id if the original message had waited too long on the client to be transmitted)
                16 => {
                    try self.message_id.updateTime(io, message.msg_id >> 32);
                },
                // msg_id too high (similar to the previous case, the client time has to be synchronized,
                // and the message re-sent with the correct msg_id)
                17 => {
                    try self.message_id.updateTime(io, message.msg_id >> 32);
                },
                // msg_seqno too low (the server has already received a message with a lower msg_id but with either
                // a higher or an equal and odd seqno)
                32 => {
                    self.seq_no += 64;
                },
                // msg_seqno too high (similarly, there is a message
                // with a higher msg_id but with either a lower or an equal and odd seqno)
                33 => {
                    self.seq_no -= 16;
                },
                else => unreachable,
            }
        },
    }
}

fn handleRPCResult(self: *Session, io: std.Io, rpc_result: tl.ProtoRPCResult) !void {
    // TODO: change, we shouldn't delete the element from the hashmap immediately
    const req_id = self.pending_requests_idmap.fetchSwapRemove(rpc_result.req_msg_id) orelse {
        // TODO: do something?
        return;
    };

    const req = blk: {
        try self.pending_requests.mutex.lock(io);
        defer self.pending_requests.mutex.unlock(io);

        const req = self.pending_requests.map.getPtr(req_id.value) orelse {
            // TODO: do something?
            return;
        };

        break :blk req;
    };

    const id = std.mem.readInt(u32, rpc_result.body[0..4], .little);
    if (tl.TL.identify(id)) |ty| {
        switch (ty) {
            .ProtoRpcError => {
                var size: usize = 0;
                _ = tl.ProtoRpcError.deserializeSize(rpc_result.body[4..], &size);

                const buf = try self.arena.allocator().alignedAlloc(u8, std.mem.Alignment.of(tl.ProtoRpcError), size);
                errdefer self.arena.allocator().free(buf);

                const err, _, _ = tl.ProtoRpcError.deserialize(rpc_result.body[4..], buf);

                req.data = .{
                    .rpc_error = .{ err, buf },
                };
                req.event.set(io);
            },
            .ProtoGzipPacked => {
                const gzip = deserializeStringNoCopy(rpc_result.body[4..]);
                var reader = std.Io.Reader.fixed(gzip);

                var decompress = std.compress.flate.Decompress.init(&reader, .gzip, &.{});

                const decompressed = try decompress.reader.allocRemaining(self.arena.allocator(), .unlimited);

                req.data = .{ .data = decompressed };
            },
            else => {
                const data = try self.arena.allocator().dupe(u8, rpc_result.body);

                req.data = .{ .data = data };
                req.event.set(io);
            },
        }
    }
}

fn handleNewDetailedInfo(self: *Session, message: tl.ProtoMessage) !void {
    var buf: [@sizeOf(tl.ProtoMsgDetailedInfo)]u8 align(@alignOf(tl.ProtoMsgDetailedInfo)) = undefined;

    const msg_detailed, _, _ = tl.IProtoMsgDetailedInfo.deserialize(message.body, &buf);

    switch (msg_detailed) {
        .ProtoMsgDetailedInfo => |detailed_info| try self.pending_ack.append(self.arena.allocator(), detailed_info.answer_msg_id),
        .ProtoMsgNewDetailedInfo => |new_detailed_info| try self.pending_ack.append(self.arena.allocator(), new_detailed_info.answer_msg_id),
    }
}

fn handleFutureSalts(_: *Session, _: tl.ProtoMessage) !void {
    // var buf: [512]u8 align(tl.ProtoFutureSalts) = undefined;

    //  const future_salts, _, _ = tl.ProtoFutureSalts.deserialize(message.body, &buf);

}

fn handlePong(self: *Session, io: std.Io, message: tl.ProtoMessage) !void {
    var buf: [@sizeOf(tl.ProtoPong)]u8 align(@alignOf(tl.ProtoPong)) = undefined;

    const pong, _, _ = tl.ProtoPong.deserialize(message.body[4..], &buf);

    const req_id = self.pending_requests_idmap.fetchSwapRemove(pong.msg_id) orelse {
        // TODO: do something?
        return;
    };

    const req = blk: {
        try self.pending_requests.mutex.lock(io);
        defer self.pending_requests.mutex.unlock(io);

        const req = self.pending_requests.map.getPtr(req_id.value) orelse {
            // TODO: do something?
            return;
        };

        break :blk req;
    };

    const msg = try self.arena.allocator().dupe(u8, message.body);

    req.data = .{ .data = msg };
    req.event.set(io);
}

fn handleMessageContainer(self: *Session, io: std.Io, message: tl.ProtoMessage) anyerror!void {
    const container = try tl.ProtoMessageContainer.deserializeContainer(self.arena.allocator(), message.body[4..]);
    defer self.arena.allocator().free(container);

    for (container) |msg| {
        try self.processMessage(io, msg);
    }
}

fn handleGZipPacked(self: *Session, io: std.Io, message: tl.ProtoMessage) anyerror!void {
    const gzip = deserializeStringNoCopy(message.body[4..]);
    var reader = std.Io.Reader.fixed(gzip);

    var decompress = std.compress.flate.Decompress.init(&reader, .gzip, &.{});

    const decompressed = try decompress.reader.allocRemaining(self.arena.allocator(), .unlimited);
    defer self.arena.allocator().free(decompressed);

    try self.processMessage(io, .{
        .seqno = message.seqno,
        .msg_id = message.msg_id,
        .body = decompressed,
    });
}

fn processMessage(self: *Session, io: std.Io, message: tl.ProtoMessage) !void {
    //const allocator = self.arena.allocator();

    const id = std.mem.readInt(u32, message.body[0..4], .little);
    if (tl.TL.identify(id)) |ty| {
        switch (ty) {
            .ProtoRPCResult => try self.handleRPCResult(io, tl.ProtoRPCResult.deserializeNoCopy(message.body)),
            .ProtoMsgsAck => try self.handleMsgsAck(message),
            .ProtoBadMsgNotification, .ProtoBadServerSalt => try self.handleBadNotification(io, message),
            .ProtoMsgDetailedInfo, .ProtoMsgNewDetailedInfo => try self.handleNewDetailedInfo(message),
            .ProtoFutureSalt => try self.handleFutureSalts(message),
            .ProtoPong => try self.handlePong(io, message),
            .ProtoMessageContainer => try self.handleMessageContainer(io, message),
            .ProtoGzipPacked => try self.handleGZipPacked(io, message),
            else => {
                std.debug.print("got {any} to handle\n", .{ty});
            },
        }
    } else {
        return SessionError.UnknownIncomingMessage;
    }
}

pub fn recvMessageTransport(self: *Session, io: std.Io, transport: *Transport) !void {
    const len = try transport.recvLen();
    const allocator = self.arena.allocator();

    const buf = try allocator.alloc(u8, len);
    defer allocator.free(buf);

    if (buf.len == 4) {
        const code = std.mem.readInt(u32, @ptrCast(buf[0..4]), .little);
        if (code == 404) {
            return SessionError.Transport404;
        }
        return SessionError.TransportUnknown;
    }

    _ = try transport.recv(buf);

    try self.decryptMessage(buf);

    const message_bytes = buf[8 + 16 + 8 + 8 ..];
    
    const message = tl.ProtoMessage.deserializeNoCopy(message_bytes);

    return self.processMessage(io, message);
}

/// Decrypts an encrypted message in-place.
fn decryptMessage(self: *const Session, data: []u8) !void {
    const auth_key_id = data[0..8];
    if (!std.mem.eql(u8, &self.auth_key_id, auth_key_id)) {
        return EncryptionError.AuthKeyMismatch;
    }

    const msg_key = data[8 .. 8 + 16];

    var digest = std.crypto.hash.sha2.Sha256.init(.{});
    var a: [32]u8 = undefined;
    digest.update(msg_key);
    digest.update(self.auth_key[8 .. 8 + 36]);
    digest.final(&a);

    var b: [32]u8 = undefined;
    digest = .init(.{});
    digest.update(self.auth_key[40 + 8 .. 76 + 8]);
    digest.update(msg_key);
    digest.final(&b);

    var key: [32]u8 = undefined;
    @memcpy(key[0..8], a[0..8]);
    @memcpy(key[8 .. 8 + 16], b[8..24]);
    @memcpy(key[8 + 16 .. 8 + 16 + 8], a[24..32]);

    var iv: [32]u8 = undefined;
    @memcpy(iv[0..8], b[0..8]);
    @memcpy(iv[8 .. 8 + 16], a[8..24]);
    @memcpy(iv[8 + 16 .. 8 + 16 + 8], b[24..32]);

    ige(data[8 + 16 ..], data[8 + 16 ..], &key, &iv, false);

    const plaintext = data[8 + 16 ..];

    // msg_key verification: x = 8 for server→client
    digest = .init(.{});
    digest.update(self.auth_key[88 + 8 .. 120 + 8]);
    digest.update(plaintext);

    if (!std.mem.eql(u8, msg_key, digest.finalResult()[8..24])) {
        return EncryptionError.MsgKeyMismatch;
    }

    //const salt = std.mem.readInt(u64, plaintext[0..8], .little); TODO: can we do something with it?
    const session_id = std.mem.readInt(u64, plaintext[8 .. 8 + 8], .little);

    if (session_id != self.session_id) {
        return EncryptionError.SessionIdMismatch;
    }
}

/// Determines how much padding is needed for the plaintext part of a message.
fn determineMessagePadding(len: usize) usize {
    // Padding must be 12-1024 bytes, total length divisible by 16
    const remainder = (len + 12) % 16;
    return if (remainder == 0) 12 else 12 + (16 - remainder);
}

pub fn worker(self: *Session, io: std.Io, transport: *Transport) !void {
    const req = try self.requests_queue.getOne(io);
    defer self.arena.allocator().free(req.data);

    const seqno = self.nextSeqNo(req.content_related);

    const msgid = try self.message_id.get(io);

    try self.encryptMessage(io, req.data, seqno, msgid, req.data_len);

    try self.pending_requests_idmap.put(
        self.arena.allocator(),
        msgid,
        req.id,
    );

    return transport.write(req.data);
}

pub fn send(self: *Session, io: std.Io, message: tl.TL) !utils.Deserialized {
    const deserializeResultSize = message.getDeserializeResultSize() orelse return SendError.NotFunction;
    const deserializeResult = message.getDeserializeResult() orelse return SendError.NotFunction;

    const len_serialized = message.serializeSize();

    // To avoid re-allocating again once we need to encrypt the message, we determine the full length in advance
    const offset_auth_key_id = 0;
    const offset_msg_key = offset_auth_key_id + 8; 
    const offset_salt = offset_msg_key + 16;
    const offset_session_id = offset_salt + 8;
    const offset_message_id = offset_session_id + 8;
    const offset_seqno = offset_message_id + 8;
    const offset_len_data = offset_seqno + 4;
    const offset_data = offset_len_data + 4;
    const offset_padding = offset_data + len_serialized;
    const offset_end = offset_padding + determineMessagePadding(offset_padding - offset_salt); // padding is based on encrypted portion length

    const id = self.current_id.fetchAdd(1, .seq_cst);

    const buf = try self.arena.allocator().alloc(u8, offset_end);
    // TODO: handle deallocation correctly. the buffer might get deallocated while the worker is reading it
    defer self.arena.allocator().free(buf);

    _ = message.serialize(buf[offset_data..offset_padding]);

    const req = try self.pending_requests.create(io, self.arena.allocator(), id);
    defer self.pending_requests.destroyItem(self.arena.allocator(), io, id);

    try self.requests_queue.putOne(io, .{ .id = id, .data = buf, .content_related = isContentRelated(message), .data_len = len_serialized });

    // TODO: handle cancellation correctly
    try req.event.wait(io);

    switch (req.data) {
        .none => {
            return SendError.Unknown;
        },
        .data => |data| {
            var size: usize = 0;

            _ = deserializeResultSize(data, &size);

            const buf_res = try self.arena.allocator().alloc(u8, size);
            errdefer self.arena.allocator().free(buf_res);

            const res, _, _ = deserializeResult(data, buf_res);

            return .{ .data = res, .ptr = buf_res };
        },
        .rpc_error => |err| {
            return .{
                .data = tl.TL{ .ProtoRpcError = err[0] },
                .ptr = err[1],
            };
        },
    }
}

/// Encrypts raw bytes in-place into a message to be sent directly to Telegram's servers.
fn encryptMessage(self: *const Session, io: std.Io, data: []u8, seqno: usize, message_id: u64, message_len: usize) !void {
    const len_headers = @sizeOf(u64) + //auth_key_id
        @sizeOf(u128); //msg_key

    var len_encrypted =
        @sizeOf(u64) + //salt
        @sizeOf(u64) + //session_id
        @sizeOf(u64) + //message_id
        @sizeOf(u32) + //seq_no
        @sizeOf(u32) + //message_data_len
        message_len;

    const padding = determineMessagePadding(len_encrypted);
    len_encrypted += padding;

    const offset_salt = len_headers;
    const offset_session_id = offset_salt + 8;
    const offset_message_id = offset_session_id + 8;
    const offset_seqno = offset_message_id + 8;
    const offset_len_data = offset_seqno + 4;
    const offset_data = offset_len_data + 4;
    const offset_padding = offset_data + message_len;

    // write data to encrypt
    std.mem.writeInt(u64, data[offset_salt..][0..8], self.salts.items[0].salt, .little);
    std.mem.writeInt(u64, data[offset_session_id..][0..8], self.session_id, .little);
    std.mem.writeInt(u64, data[offset_message_id..][0..8], message_id, .little);
    std.mem.writeInt(u32, data[offset_seqno..][0..4], @intCast(seqno), .little);
    std.mem.writeInt(u32, data[offset_len_data..][0..4], @intCast(message_len), .little);
    try std.Io.randomSecure(io, data[offset_padding .. offset_padding + padding]);

    // Write auth_key_id
    @memcpy(data[0..8], &self.auth_key_id);

    // create message_key
    const message_key = data[8 .. 8 + 16];
    var digest = std.crypto.hash.sha2.Sha256.init(.{});
    digest.update(self.auth_key[88..120]);
    digest.update(data[len_headers .. len_headers + len_encrypted]);
    @memcpy(data[8 .. 8 + 16], digest.finalResult()[8..24]);

    var a: [32]u8 = undefined;
    digest = .init(.{});
    digest.update(message_key);
    digest.update(self.auth_key[0..36]);
    digest.final(&a);

    var b: [32]u8 = undefined;
    digest = .init(.{});
    digest.update(self.auth_key[40..76]);
    digest.update(message_key);
    digest.final(&b);

    var key: [32]u8 = undefined;
    @memcpy(key[0..8], a[0..8]);
    @memcpy(key[8 .. 8 + 16], b[8..24]);
    @memcpy(key[8 + 16 .. 8 + 16 + 8], a[24..32]);

    var iv: [32]u8 = undefined;
    @memcpy(iv[0..8], b[0..8]);
    @memcpy(iv[8 .. 8 + 16], a[8..24]);
    @memcpy(iv[8 + 16 .. 8 + 16 + 8], b[24..32]);

    ige(data[len_headers .. len_headers + len_encrypted], data[len_headers .. len_headers + len_encrypted], &key, &iv, true);
}

pub fn deinit(self: *Session) !void {
    self.arena.deinit();
}

pub fn init(io: std.Io, allocator: std.mem.Allocator, auth_key: [256]u8, salt: tl.ProtoFutureSalt, dc_id: u8, test_mode: bool, is_cdn: bool, is_media: bool) !Session {
    var self = Session{
        .dc_id = dc_id,
        .is_test_mode = test_mode,
        .message_id = .{},
        .is_cdn = is_cdn,
        .is_media = is_media,
        .seq_no = 0,
        .salts = .{},
        .auth_key = auth_key,
        .session_id = undefined,
        .auth_key_id = undefined,
        .arena = std.heap.ArenaAllocator.init(allocator),
        .pending_ack = .{},
        .pending_requests = .{ .map = .{}, .mutex = .init },
        .current_id = .init(0),
        .pending_requests_idmap = .{},
        .requests_queue = .init(&.{}),
    };

    try std.Io.randomSecure(io, @ptrCast(&self.session_id));

    // The authorization key id is the 64 lower-bits of the SHA1 hash of the
    // authorization key
    var auth_key_id: [20]u8 = undefined;
    std.crypto.hash.Sha1.hash(&self.auth_key, &auth_key_id, .{});
    @memcpy(&self.auth_key_id, auth_key_id[12..20]);

    // Update the message_id time with the system host's time.
    // We use this one as the "best guess", if we receive a bad_msg_notification, then we synchronize it with the expected time
    try self.message_id.updateTime(io, @intCast((try std.Io.Clock.now(.real, io)).toSeconds()));

    try self.salts.append(self.arena.allocator(), salt);

    return self;
}
