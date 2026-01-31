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
    proto_req_id: ?u64 = null,
    deserializeResultSize: *const (fn (in: []const u8, size: *usize) usize),
    deserializeResult: *const (fn (noalias in: []const u8, noalias out: []u8) struct { tl.TL, usize, usize }),
    data: ?utils.Deserialized,
    // data: union(enum) { none: struct {}, data: []u8, rpc_error: struct { *tl.ProtoRpcError, []u8 } } = .{ .none = .{} },
};

seq_no: usize,

salts: std.ArrayList(tl.ProtoFutureSalt),

pending_ack: std.ArrayList(u64),

//salt: tl.ProtoFutureSalt,
session_id: u64,
message_id: MessageID,
pending_requests_idmap: std.AutoArrayHashMapUnmanaged(u64, u32),
pending_requests: struct {
    map: std.AutoArrayHashMapUnmanaged(u32, PendingRequest),

    /// The mutex is assumed to be already acquired.
    pub fn create(self: *@This(), allocator: std.mem.Allocator, id: u32) !*PendingRequest {
        const req = try self.map.getOrPut(allocator, id);
        if (req.found_existing)
            return req.value_ptr;

        req.value_ptr.* = .{ .deserializeResult = undefined, .deserializeResultSize = undefined, .data = null };
        return req.value_ptr;
    }
},

// Unless noted, for every field in this struct, we need to acquire the mutex first before using them
mutex: std.Io.Mutex,

// Thread-safe
requests_queue: std.Io.Queue(struct {
    id: u32,
    data: []u8,
    data_len: usize,
    content_related: bool,
}),
current_id: std.atomic.Value(u32) = .init(0),
shutdown: std.atomic.Value(bool) = .init(false),
waiting_requests: std.atomic.Value(u32) = .init(0),
shutdown_event: std.Io.Event = .unset,

// Not specifically thread-safe, but they will not change for the entire lifecycle of the session
dc_id: u8,
is_media: bool,
is_test_mode: bool,
is_cdn: bool,
auth_key: [256]u8,
auth_key_id: [8]u8,

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

pub const SendError = error{ NotFunction, Unknown, Shutdown };

/// Generates the next sequence number for a message.
/// Returns the seqno to use and updates the internal counter if content-related.
///
/// The mutex is assumed to be already acquired.
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

fn handleMsgsAck(self: *Session, message: tl.ProtoMessage) !void {
    _ = self;
    _ = message;
}

fn handleBadNotification(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) !void {
    var size: usize = 0;
    _ = tl.IProtoBadMsgNotification.deserializeSize(message.body, &size);

    const buf = try allocator.alloc(u8, size);
    defer allocator.free(buf);

    const bad_msg, _, _ = tl.IProtoBadMsgNotification.deserialize(message.body, buf);

    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

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

fn handleRPCResult(self: *Session, io: std.Io, allocator: std.mem.Allocator, rpc_result: tl.ProtoRPCResult) !void {

    const req = blk: {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);

        const req_id = self.pending_requests_idmap.get(rpc_result.req_msg_id) orelse {
            // TODO: do something?
            return;
        };

        const req = self.pending_requests.map.getPtr(req_id) orelse {
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

                const buf = try allocator.alignedAlloc(u8, std.mem.Alignment.of(tl.ProtoRpcError), size);
                errdefer allocator.free(buf);

                const err, _, _ = tl.ProtoRpcError.deserialize(rpc_result.body[4..], buf);

                req.data = .{
                    .ptr = buf,
                    .data = tl.TL{ .ProtoRpcError = err },
                };

                req.event.set(io);
            },
            .ProtoGzipPacked => {

                const gzip = deserializeStringNoCopy(rpc_result.body[4..]);
                var reader = std.Io.Reader.fixed(gzip);

                var decompress = std.compress.flate.Decompress.init(&reader, .gzip, &.{});

                const decompressed = try decompress.reader.allocRemaining(allocator, .unlimited);
                defer allocator.free(decompressed);

                var size_deserialize: usize = 0;
                _ = req.deserializeResultSize(decompressed, &size_deserialize);

                const buf = try allocator.alloc(u8, size_deserialize);
                errdefer allocator.free(buf);

                const deserialized, _, _ = req.deserializeResult(decompressed, buf);

                req.data = .{ .data = deserialized, .ptr = buf };
                req.event.set(io);
            },
            else => {
                var size_deserialize: usize = 0;
                _ = req.deserializeResultSize(rpc_result.body, &size_deserialize);

                const buf = try allocator.alloc(u8, size_deserialize);
                errdefer allocator.free(buf);

                const deserialized, _, _ = req.deserializeResult(rpc_result.body, buf);

                req.data = .{ .data = deserialized, .ptr = buf };
                req.event.set(io);
            },
        }
    } else {
        // Although this shouldn't happen for pretty much all of the registered functions (at the time of writing), an rpc_result may pass an object that is still valid (eg. bare constructors)
        var size_deserialize: usize = 0;
        _ = req.deserializeResultSize(rpc_result.body, &size_deserialize);

        const buf = try allocator.alloc(u8, size_deserialize);
        errdefer allocator.free(buf);

        const deserialized, _, _ = req.deserializeResult(rpc_result.body, buf);

        req.data = .{ .data = deserialized, .ptr = buf };
        req.event.set(io);
    }
}

fn handleNewDetailedInfo(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) !void {
    var buf: [@sizeOf(tl.ProtoMsgDetailedInfo)]u8 align(@alignOf(tl.ProtoMsgDetailedInfo)) = undefined;

    const msg_detailed, _, _ = tl.IProtoMsgDetailedInfo.deserialize(message.body, &buf);

    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    switch (msg_detailed) {
        .ProtoMsgDetailedInfo => |detailed_info| try self.pending_ack.append(allocator, detailed_info.answer_msg_id),
        .ProtoMsgNewDetailedInfo => |new_detailed_info| try self.pending_ack.append(allocator, new_detailed_info.answer_msg_id),
    }
}

fn handleFutureSalts(_: *Session, _: tl.ProtoMessage) !void {
    // var buf: [512]u8 align(tl.ProtoFutureSalts) = undefined;

    //  const future_salts, _, _ = tl.ProtoFutureSalts.deserialize(message.body, &buf);

}

fn handlePong(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) !void {
    const buf = try allocator.alignedAlloc(u8, std.mem.Alignment.of(tl.ProtoPong), @sizeOf(tl.ProtoPong));

    const pong, _, _ = tl.ProtoPong.deserialize(message.body[4..], buf);

    const req = blk: {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);

        const req_id = self.pending_requests_idmap.get(pong.msg_id) orelse {
            // TODO: do something?

            allocator.free(buf);
            return;
        };

        const req = self.pending_requests.map.getPtr(req_id) orelse {
            // TODO: do something?

            allocator.free(buf);
            return;
        };

        break :blk req;
    };

    req.data = .{ .data = .{ .ProtoPong = pong }, .ptr = buf };
    req.event.set(io);
}

fn handleMessageContainer(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) anyerror!void {
    const container = try tl.ProtoMessageContainer.deserializeContainer(allocator, message.body[4..]);
    defer allocator.free(container);

    for (container) |msg| {
        try self.processMessage(io, allocator, msg);
    }
}

fn handleGZipPacked(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) anyerror!void {
    const gzip = deserializeStringNoCopy(message.body[4..]);
    var reader = std.Io.Reader.fixed(gzip);

    var decompress = std.compress.flate.Decompress.init(&reader, .gzip, &.{});

    const decompressed = try decompress.reader.allocRemaining(allocator, .unlimited);
    defer allocator.free(decompressed);

    try self.processMessage(io, allocator, .{
        .seqno = message.seqno,
        .msg_id = message.msg_id,
        .body = decompressed,
    });
}

fn processMessage(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) !void {
    //const allocator = self.arena.allocator();

    const id = std.mem.readInt(u32, message.body[0..4], .little);
    //std.debug.print("received {any}\n", .{tl.TL.identify(id)});

    if (tl.TL.identify(id)) |ty| {
        switch (ty) {
            .ProtoRPCResult => try self.handleRPCResult(io, allocator, tl.ProtoRPCResult.deserializeNoCopy(message.body[4..])),
            .ProtoMsgsAck => try self.handleMsgsAck(message),
            .ProtoBadMsgNotification, .ProtoBadServerSalt => try self.handleBadNotification(io, allocator, message),
            .ProtoMsgDetailedInfo, .ProtoMsgNewDetailedInfo => try self.handleNewDetailedInfo(io, allocator, message),
            .ProtoFutureSalt => try self.handleFutureSalts(message),
            .ProtoPong => try self.handlePong(io, allocator, message),
            .ProtoMessageContainer => try self.handleMessageContainer(io, allocator, message),
            .ProtoGzipPacked => try self.handleGZipPacked(io, allocator, message),
            else => {
                // std.debug.print("got {any} to handle\n", .{ty});
            },
        }
    } else {
        return SessionError.UnknownIncomingMessage;
    }
}

pub fn recvMessageTransport(self: *Session, io: std.Io, allocator: std.mem.Allocator, transport: *Transport) !void {
    for (0..2) |_| {
        const len = try transport.recvLen(io);

        const buf = try allocator.alloc(u8, len);
        defer allocator.free(buf);

        if (buf.len == 4) {
            const code = std.mem.readInt(u32, @ptrCast(buf[0..4]), .little);
            if (code == 404) {
                return SessionError.Transport404;
            }
            return SessionError.TransportUnknown;
        }

        _ = try transport.recv(io, buf);

        try self.decryptMessage(io, buf);

        const message_bytes = buf[8 + 16 + 8 + 8 ..];

        const message = tl.ProtoMessage.deserializeNoCopy(message_bytes);

        try self.processMessage(io, allocator, message);
    }
}

/// Decrypts an encrypted message in-place.
fn decryptMessage(self: *Session, io: std.Io, data: []u8) !void {
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

    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

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

pub fn worker(self: *Session, io: std.Io, allocator: std.mem.Allocator, transport: *Transport) !void {
    const req = try self.requests_queue.getOne(io);

    defer allocator.free(req.data);

    errdefer {
        self.mutex.lockUncancelable(io);
        if (self.pending_requests.map.getPtr(req.id)) |pending_req| {
            pending_req.event.set(io);
        }
        self.mutex.unlock(io);
    }

    const msgid = blk: {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);

        if (self.shutdown.load(.acquire)) {
            return;
        }

        const seqno = self.nextSeqNo(req.content_related);

        const msgid = try self.message_id.get(io);

        try self.encryptMessage(io, req.data, seqno, msgid, req.data_len);

        try self.pending_requests_idmap.put(
            allocator,
            msgid,
            req.id,
        );

        self.pending_requests.map.getPtr(req.id).?.proto_req_id = msgid;

        break :blk msgid;
    };

    errdefer {
        self.mutex.lockUncancelable(io);
        _ = self.pending_requests_idmap.swapRemove(msgid);
        self.mutex.unlock(io);
    }

    try transport.write(io, req.data);
}

/// Enqueues a new TL function into the reader worker queue, and waits for the result.
///
/// Cancellation is supported for this function, but only to cancel the waiter itself (If the request has already been added to the queue, it will be sent to Telegram anyway).
pub fn send(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.TL) !utils.Deserialized {
    const deserializeResultSize = message.getDeserializeResultSize() orelse return SendError.NotFunction;
    const deserializeResult = message.getDeserializeResult() orelse return SendError.NotFunction;
    if (self.shutdown.load(.acquire)) {
        return SendError.Shutdown;
    }

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

    const buf = try allocator.alloc(u8, offset_end);

    _ = message.serialize(buf[offset_data..offset_padding]);

    const req = brk: {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);

        const req = try self.pending_requests.create(allocator, id);

        req.deserializeResult = deserializeResult;
        req.deserializeResultSize = deserializeResultSize;

        break :brk req;
    };

    defer {
        self.mutex.lockUncancelable(io);
        if (req.proto_req_id) |proto_req_id| {
            _ = self.pending_requests_idmap.swapRemove(proto_req_id);
        }
        _ = self.pending_requests.map.swapRemove(id);
        self.mutex.unlock(io);
    }
    self.requests_queue.putOne(io, .{ .id = id, .data = buf, .content_related = isContentRelated(message), .data_len = len_serialized }) catch |e| {
        allocator.free(buf);
        return e;
    };

    {
        _ = self.waiting_requests.fetchAdd(1, .seq_cst);
        defer {
            const sub = self.waiting_requests.fetchSub(1, .seq_cst);
            if (sub == 1) {
                self.shutdown_event.set(io);
            }
        }

        try req.event.wait(io);
    }

    if (req.data) |data| {
        return data;
    } else {
        return SendError.Unknown;
    }
}

/// Encrypts raw bytes in-place into a message to be sent directly to Telegram's servers.
/// The mutex is assumed to be already acquired.
fn encryptMessage(self: *const Session, io: std.Io, data: []u8, seqno: usize, message_id: u64, message_len: usize) !void {
    const offset_auth_key_id = 0;
    const offset_msg_key = offset_auth_key_id + 8;
    const offset_salt = offset_msg_key + 16;
    const offset_session_id = offset_salt + 8;
    const offset_message_id = offset_session_id + 8;
    const offset_seqno = offset_message_id + 8;
    const offset_len_data = offset_seqno + 4;
    const offset_data = offset_len_data + 4;
    const offset_padding = offset_data + message_len;

    const padding = determineMessagePadding(offset_padding - offset_salt);

    // write data to encrypt
    std.mem.writeInt(u64, data[offset_salt..][0..8], self.salts.items[0].salt, .little);
    std.mem.writeInt(u64, data[offset_session_id..][0..8], self.session_id, .little);
    std.mem.writeInt(u64, data[offset_message_id..][0..8], message_id, .little);
    std.mem.writeInt(u32, data[offset_seqno..][0..4], @intCast(seqno), .little);
    std.mem.writeInt(u32, data[offset_len_data..][0..4], @intCast(message_len), .little);
    try std.Io.randomSecure(io, data[offset_padding .. offset_padding + padding]);

    // Write auth_key_id
    @memcpy(data[offset_auth_key_id..offset_msg_key], &self.auth_key_id);

    // create message_key
    const message_key = data[offset_msg_key..offset_salt];
    var digest = std.crypto.hash.sha2.Sha256.init(.{});
    digest.update(self.auth_key[88..120]);
    digest.update(data[offset_salt .. offset_padding + padding]);
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

    ige(data[offset_salt .. offset_padding + padding], data[offset_salt .. offset_padding + padding], &key, &iv, true);
}

/// Signals all pending requests and prevents new ones.
///
/// This does not deinit the map because callers might still be waiting on `req.event`.
/// Call `deinit` after all waiters have returned.
pub fn destroyRequests(self: *Session, io: std.Io) void {
    self.mutex.lockUncancelable(io);
    self.shutdown.store(true, .release);

    var it = self.pending_requests.map.iterator();
    while (it.next()) |pending_req| {
        pending_req.value_ptr.event.set(io);
    }
    if (self.waiting_requests.load(.acquire) == 0) {
        self.shutdown_event.set(io);
    }
    self.mutex.unlock(io);

    self.shutdown_event.waitUncancelable(io);
}

/// Before calling this function, make sure no worker is running and to have deleted every event in `pending_requests` (use `destroyRequests` for that)
pub fn deinit(self: *Session, io: std.Io, allocator: std.mem.Allocator) void {
    self.mutex.lockUncancelable(io);
    // keep the mutex always locked, since this session shouldn't be used ever again
    while (true) {
        if (self.requests_queue.capacity() == 0) {
            break;
        }
        const req = self.requests_queue.getOneUncancelable(io) catch {
            break;
        };
        allocator.free(req.data);
    }
    self.requests_queue.close(io);
    self.salts.deinit(allocator);
    self.pending_ack.deinit(allocator);
    self.pending_requests_idmap.deinit(allocator);

    var it = self.pending_requests.map.iterator();
    while (it.next()) |pending_req| {
        if (pending_req.value_ptr.data) |data| {
            pending_req.value_ptr.data = null;
            allocator.free(data.ptr);
        }
    }
    self.pending_requests.map.deinit(allocator);
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
        .pending_ack = .{},
        .pending_requests = .{
            .map = .{},
        },
        .current_id = .init(0),
        .shutdown = .init(false),
        .waiting_requests = .init(0),
        .shutdown_event = .unset,
        .mutex = .init,
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

    try self.salts.append(allocator, salt);

    return self;
}
