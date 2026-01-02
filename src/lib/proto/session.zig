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
        .FutureSalts,
        .ProtoPing,
        .ProtoPong,
        .ProtoPingDelayDisconnect,
        .ProtoDestroySession,
        .ProtoDestroySessionOk,
        .ProtoDestroySessionNone,
        .MessageContainer,
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

    const bad_msg, _, _ = tl.IProtoBadMsgNotification.deserialize(message.body, &buf);

    switch (bad_msg) {
        .ProtoBadServerSalt => |x| {
            self.salts.clearAndFree(allocator);
            try self.salts.append(allocator, .{
                .salt = x.new_server_salt,
                .valid_since = self.message_id.get(io),
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
                    self.message_id.updateTime(io, message.msg_id >> 32);
                },
                // msg_id too high (similar to the previous case, the client time has to be synchronized,
                // and the message re-sent with the correct msg_id)
                17 => {
                    self.message_id.updateTime(io, message.msg_id >> 32);
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
            }
        },
    }
}

fn processMessage(self: *Session, io: std.Io, message: tl.ProtoMessage) !void {
    //const allocator = self.arena.allocator();

    const id = std.mem.readInt(u32, message.body[0..4], .little);
    if (tl.TL.identify(id)) |ty| {
        switch (ty) {
            .ProtoRPCResult => unreachable,
            .ProtoMsgsAck => self.handleMsgsAck(message),
            .ProtoBadMsgNotification, .ProtoBadMsgNotification => self.handleBadNotification(io, message),
            else => {
                std.debug.print("got {any} to handle", .{ty});
            },
        }
    } else {
        return SessionError.UnknownIncomingMessage;
    }
}

pub fn recvMessageTransport(self: *Session, transport: *Transport) !tl.ProtoMessage2 {
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

    var size: usize = 0;

    _ = tl.ProtoMessage.deserializeSize(message_bytes, &size);

    const des = try allocator.alignedAlloc(u8, std.mem.Alignment.of(tl.ProtoMessage), size);
    errdefer allocator.free(des);

    const id = std.mem.readInt(u32, message_bytes[0..4], .little);

    std.debug.print("type: {any}\n", .{tl.TL.identify(id)});

    const message = tl.ProtoMessage.deserializeNoCopy(message_bytes);

    return message;
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

/// Encrypts raw bytes into a message to be sent directly to Telegram's servers.
///
/// Caller owns the returned bytes.
fn encryptMessage(self: *const Session, allocator: std.mem.Allocator, data: []const u8, seqno: usize, message_id: u64) ![]u8 {
    const len_headers = @sizeOf(u64) + //auth_key_id
        @sizeOf(u128); //msg_key

    var len_encrypted =
        @sizeOf(u64) + //salt
        @sizeOf(u64) + //session_id
        @sizeOf(u64) + //message_id
        @sizeOf(u32) + //seq_no
        @sizeOf(u32) + //message_data_len
        data.len;

    const padding = determineMessagePadding(len_encrypted);
    len_encrypted += padding;

    const buf = try allocator.alloc(u8, len_headers + len_encrypted);
    errdefer allocator.free(buf);

    const offset_salt = len_headers;
    const offset_session_id = offset_salt + 8;
    const offset_message_id = offset_session_id + 8;
    const offset_seqno = offset_message_id + 8;
    const offset_len_data = offset_seqno + 4;
    const offset_data = offset_len_data + 4;
    const offset_padding = offset_data + data.len;

    // write data to encrypt
    std.mem.writeInt(u64, buf[offset_salt..offset_session_id], self.salt.salt, .little);
    std.mem.writeInt(u64, buf[offset_session_id..offset_message_id], self.session_id, .little);
    std.mem.writeInt(u64, buf[offset_message_id..offset_seqno], message_id, .little);
    std.mem.writeInt(u32, buf[offset_seqno..offset_len_data], @intCast(seqno), .little);
    std.mem.writeInt(u32, buf[offset_len_data..offset_data], @intCast(data.len), .little);
    @memcpy(buf[offset_data..offset_padding], data);
    std.crypto.random.bytes(buf[offset_padding .. offset_padding + padding]);

    // Write auth_key_id
    @memcpy(buf[0..8], &self.auth_key_id);

    // create message_key
    const message_key = buf[8 .. 8 + 16];
    var digest = std.crypto.hash.sha2.Sha256.init(.{});
    digest.update(self.auth_key[88..120]);
    digest.update(buf[len_headers .. len_headers + len_encrypted]);
    @memcpy(buf[8 .. 8 + 16], digest.finalResult()[8..24]);

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

    ige(buf[len_headers .. len_headers + len_encrypted], buf[len_headers .. len_headers + len_encrypted], &key, &iv, true);

    return buf;
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
        .session_id = std.crypto.random.int(u64),
        .auth_key_id = undefined,
        .arena = std.heap.ArenaAllocator.init(allocator),
    };

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
