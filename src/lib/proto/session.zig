const tl = @import("../tl/api.zig");
const std = @import("std");
const Transport = @import("../transport.zig").Transport;
const MessageID = @import("./message_id.zig");
const ige = @import("../crypto/ige.zig").ige;
const utils = @import("./utils.zig");
const deserializeStringNoCopy = @import("../tl/base.zig").deserializeStringNoCopy;

const SALT_THRESHOLD = 15;
const SALTS_TO_OBTAIN = 64;
const MAX_WORKER_BATCH = 10;
const MSG_ID_CHECK_SET_SIZE = 30;
const PING_WRITE_INTERVAL_SECS = 30;

const log = std.log.scoped(.mzproto_session);

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

const PendingAnswer = struct {
    event: std.Io.Event = .unset,
    proto_req_id: ?u64 = null,
    deserializeResultSize: *const (fn (in: []const u8, size: *usize) usize),
    deserializeResult: *const (fn (noalias in: []const u8, noalias out: []u8) struct { tl.TL, usize, usize }),
    data: ?SendError!utils.Deserialized,
};

const Request = struct {
    id: ?u32,
    data: []u8,
    content_related: bool,
};

ping_timeout: std.Io.Timeout = .none,
ping_disconnect: bool = false, // if this is set to true, the connection must be closed after the timeout is set
ping_value: u32 = 0,

seq_no: usize,

salts: std.ArrayList(tl.ProtoFutureSalt),
requesting_salts: bool = false,

stored_msg_ids: utils.Ring(u64, MSG_ID_CHECK_SET_SIZE) = .{ .buf = .{0} ** MSG_ID_CHECK_SET_SIZE },

pending_ack: std.ArrayList(u64),
pending_ack_inflight: usize = 0,

time_synced: bool = false,

session_id: u64,
message_id: MessageID,
pending_answers_idmap: std.AutoArrayHashMapUnmanaged(u64, u32),
pending_answers: struct {
    map: std.AutoArrayHashMapUnmanaged(u32, *PendingAnswer),

    /// The mutex is assumed to be already acquired.
    pub fn create(self: *@This(), allocator: std.mem.Allocator, id: u32) !*PendingAnswer {
        const req = try self.map.getOrPut(allocator, id);
        if (req.found_existing) {
            return req.value_ptr.*;
        }

        const pending_req = try allocator.create(PendingAnswer);
        pending_req.* = .{ .deserializeResult = undefined, .deserializeResultSize = undefined, .data = null };
        req.value_ptr.* = pending_req;
        return pending_req;
    }
},

// Unless noted, for every field in this struct, we need to acquire the mutex first before using them
mutex: std.Io.Mutex,

// Thread-safe
requests_queue: std.Io.Queue(Request),
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

pub const SendError = error{
    Resend, // Happens when we receive a message like bad_msg_notification, shouldn't be returned
    NotFunction,
    Unknown,
    Shutdown,
    Canceled,
};

pub const SecurityError = error{
    AuthKeyMismatch,
    MsgKeyMismatch,
    SessionIdMismatch,
    PaddingMismatch,
    MsgIdTooOld, // also happens if it's too new
    DuplicatedMsgId,
    MsgIdNotOdd,
    InvalidMsgLength,
};

pub const SessionError = error{
    Transport404,
    TransportUnknown,
};

pub const ProcessMessageError = error{UnknownIncomingMessage} || std.mem.Allocator.Error || std.Io.Reader.LimitedAllocError || std.Io.Cancelable;

/// Generates the next sequence number for a message.
/// Returns the seqno to use and updates the internal counter if content-related.
///
/// The mutex is assumed to be already acquired.
inline fn nextSeqNo(self: *Session, is_content_related: bool) u32 {
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

/// The mutex is assumed to be already acquired.
fn getSalt(self: *Session, io: std.Io) tl.ProtoFutureSalt {
    if (self.salts.items.len == 0) {
        return .{ .salt = 0, .valid_since = 0, .valid_until = 0 };
    }
    const now = self.message_id.getUnix(io);
    for (self.salts.items) |salt| {
        if (salt.valid_since < now and salt.valid_until > now) {
            return salt;
        }
    }
    // return the last one as best effort
    return self.salts.items[self.salts.items.len - 1];
}

fn maybeRequestFutureSalts(self: *Session, io: std.Io, allocator: std.mem.Allocator) void {
    const now = self.message_id.getUnix(io);
    {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);

        const should_request = blk: {
            if (self.requesting_salts) {
                break :blk false;
            }

            if (self.salts.items.len < SALT_THRESHOLD) {
                break :blk true;
            }

            var valid_salts: usize = 0;

            for (self.salts.items) |salt| {
                // salts that are not valid yet are fine
                if (salt.valid_until > now) {
                    self.salts.items[valid_salts] = salt;
                    valid_salts += 1;
                }
            }

            self.salts.items.len = valid_salts;

            if (valid_salts < SALT_THRESHOLD) {
                break :blk true;
            }

            break :blk false;
        };

        if (!should_request) {
            return;
        }

        self.requesting_salts = true;
    }

    log.debug("Requesting more salts - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });

    self.sendNoWait(io, allocator, tl.TL{ .ProtoGetFutureSalts = &.{ .num = SALTS_TO_OBTAIN } }) catch {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);

        self.requesting_salts = false;
    };
}

/// The mutex is assumed to be already acquired.
fn cancelUnprocessedRequests(self: *Session, io: std.Io, first_msg_id: u64) void {
    var it = self.pending_answers_idmap.iterator();
    while (it.next()) |msg_id| {
        if (first_msg_id > msg_id.key_ptr.*) {
            if (self.pending_answers.map.get(msg_id.value_ptr.*)) |answer| {
                if (answer.data == null) {
                    answer.data = SendError.Canceled;
                }
                answer.event.set(io);
            }
        }
    }
}

fn handleMsgsAck(self: *Session, message: tl.ProtoMessage) !void {
    _ = self;
    _ = message;
}

fn handleBadNotification(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) ProcessMessageError!void {
    var size: usize = 0;
    _ = tl.IProtoBadMsgNotification.deserializeSize(message.body, &size);

    const buf = try allocator.alloc(u8, size);
    defer allocator.free(buf);

    const bad_msg, _, _ = tl.IProtoBadMsgNotification.deserialize(message.body, buf);

    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    const bad_msg_id = brk: {
        switch (bad_msg) {
            // incorrect server salt (in this case, the bad_server_salt response is received with
            // the correct salt, and the message is to be re-sent with it)
            .ProtoBadServerSalt => |x| {
                log.warn("got ProtoBadServerSalt - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
                if (self.salts.items.len == 0) {
                    try self.salts.append(allocator, .{
                        .salt = x.new_server_salt,
                        .valid_since = 0,
                        .valid_until = 0,
                    });
                } else {
                    try self.salts.ensureTotalCapacityPrecise(allocator, 1);
                    self.salts.items.len = 1;
                    self.salts.items[0] = .{
                        .salt = x.new_server_salt,
                        .valid_since = 0,
                        .valid_until = 0,
                    };
                }
                break :brk x.bad_msg_id;
            },
            .ProtoBadMsgNotification => |x| {
                switch (x.error_code) {
                    // msg_id too low (most likely, client time is wrong;
                    // it would be worthwhile to synchronize it using msg_id notifications
                    // and re-send the original message with the “correct” msg_id or wrap it in a
                    // container with a new msg_id if the original message had waited too long on the client to be transmitted)
                    16 => {
                        log.warn("got ProtoBadMsgNotification, msg_id too low - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
                        self.message_id.updateTime(io, message.msg_id >> 32);
                        self.time_synced = true;
                    },
                    // msg_id too high (similar to the previous case, the client time has to be synchronized,
                    // and the message re-sent with the correct msg_id)
                    17 => {
                        log.warn("got ProtoBadMsgNotification, msg_id too high - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
                        self.message_id.updateTime(io, message.msg_id >> 32);
                        self.time_synced = true;
                    },
                    // incorrect two lower order msg_id bits (the server expects client message msg_id to be divisible by 4)
                    18 => {
                        // an error like that should never happen, but you never know...
                        log.warn("got ProtoBadMsgNotification, incorrect two lower order msg_id bits - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
                        self.message_id.updateTime(io, message.msg_id >> 32);
                        self.time_synced = true;
                    },
                    // container msg_id is the same as msg_id of a previously received message (this must never happen)
                    19 => {
                        // what should I even do with an error like that?
                        log.warn("got ProtoBadMsgNotification, container msg_id is the same as msg_id of a previously received message - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
                    },
                    // message too old, and it cannot be verified whether the server has received a message with this msg_id or not
                    20 => {
                        log.warn("got ProtoBadMsgNotification, message too old, and it cannot be verified whether the server has received a message with this msg_id or not - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
                    },
                    // msg_seqno too low (the server has already received a message with a lower msg_id but with either
                    // a higher or an equal and odd seqno)
                    32 => {
                        log.warn("got ProtoBadMsgNotification, msg_seqno too low - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
                        self.seq_no += 64;
                    },
                    // msg_seqno too high (similarly, there is a message
                    // with a higher msg_id but with either a lower or an equal and odd seqno)
                    33 => {
                        log.warn("got ProtoBadMsgNotification, msg_seqno too high - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
                        self.seq_no -= 16;
                    },
                    // an even msg_seqno expected (irrelevant message), but odd received
                    34 => {
                        log.warn("got ProtoBadMsgNotification, an even msg_seqno expected, but odd received - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
                    },
                    // odd msg_seqno expected (relevant message), but even received
                    35 => {
                        log.warn("got ProtoBadMsgNotification, odd msg_seqno expected, but even received - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
                    },
                    // invalid container.
                    64 => {
                        // very descriptive. Thanks, Telegram!
                        log.warn("got ProtoBadMsgNotification, invalid container - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
                    },
                    else => {
                        log.warn("got ProtoBadMsgNotification, unknown code {d} - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ x.error_code, self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
                    },
                }
                break :brk x.bad_msg_id;
            },
        }
    };

    const req_id = self.pending_answers_idmap.get(bad_msg_id) orelse {
        // TODO: do something?
        return;
    };

    const req_ptr = self.pending_answers.map.getPtr(req_id) orelse {
        // TODO: do something?
        return;
    };

    req_ptr.*.data = SendError.Resend;
    req_ptr.*.event.set(io);
}

fn handleRPCResult(self: *Session, io: std.Io, allocator: std.mem.Allocator, rpc_result: tl.ProtoRPCResult) ProcessMessageError!void {
    const req_id, const deserializeResultSize, const deserializeResult = blk: {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);

        const req_id = self.pending_answers_idmap.get(rpc_result.req_msg_id) orelse {
            // TODO: do something?
            log.warn("Received unmapped RPC Result {d} - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ rpc_result.req_msg_id, self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
            return;
        };

        const req = self.pending_answers.map.getPtr(req_id) orelse {
            // TODO: do something?
            log.warn("Received unmapped RPC Result {d}->{d} - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ rpc_result.req_msg_id, req_id, self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
            return;
        };

        break :blk .{ req_id, req.*.deserializeResultSize, req.*.deserializeResult };
    };

    log.debug("Received RPC Result, {d}->{d} - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ rpc_result.req_msg_id, req_id, self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });

    const id = std.mem.readInt(u32, rpc_result.body[0..4], .little);
    if (tl.TL.identify(id)) |ty| {
        switch (ty) {
            .ProtoRpcError => {
                var size: usize = 0;
                _ = tl.ProtoRpcError.deserializeSize(rpc_result.body[4..], &size);

                const buf = try allocator.alignedAlloc(u8, std.mem.Alignment.of(tl.ProtoRpcError), size);
                errdefer allocator.free(buf);

                const err, _, _ = tl.ProtoRpcError.deserialize(rpc_result.body[4..], buf);

                try self.mutex.lock(io);
                defer self.mutex.unlock(io);

                const req = self.pending_answers.map.getPtr(req_id) orelse {
                    allocator.free(buf);
                    return;
                };

                req.*.data = .{ .ptr = buf, .alignment = .of(tl.ProtoRpcError), .data = tl.TL{ .ProtoRpcError = err } };
                req.*.event.set(io);
            },
            .ProtoGzipPacked => {
                const gzip = deserializeStringNoCopy(rpc_result.body[4..]);
                var reader = std.Io.Reader.fixed(gzip);

                var decompress = std.compress.flate.Decompress.init(&reader, .gzip, &.{});

                const decompressed = try decompress.reader.allocRemaining(allocator, .unlimited);
                defer allocator.free(decompressed);

                var size_deserialize: usize = 0;
                _ = deserializeResultSize(decompressed, &size_deserialize);

                const buf = try allocator.alloc(u8, size_deserialize);
                errdefer allocator.free(buf);

                const deserialized, _, _ = deserializeResult(decompressed, buf);

                try self.mutex.lock(io);
                defer self.mutex.unlock(io);

                const req = self.pending_answers.map.getPtr(req_id) orelse {
                    allocator.free(buf);
                    return;
                };

                req.*.data = .{ .data = deserialized, .ptr = buf };
                req.*.event.set(io);
            },
            else => {
                var size_deserialize: usize = 0;
                _ = deserializeResultSize(rpc_result.body, &size_deserialize);

                const buf = try allocator.alloc(u8, size_deserialize);
                errdefer allocator.free(buf);

                const deserialized, _, _ = deserializeResult(rpc_result.body, buf);

                try self.mutex.lock(io);
                defer self.mutex.unlock(io);

                const req = self.pending_answers.map.getPtr(req_id) orelse {
                    allocator.free(buf);
                    return;
                };

                req.*.data = .{ .data = deserialized, .ptr = buf };
                req.*.event.set(io);
            },
        }
    } else {
        // Although this shouldn't happen for pretty much all of the registered functions (at the time of writing), an rpc_result may pass an object that is still valid (eg. bare constructors)
        var size_deserialize: usize = 0;
        _ = deserializeResultSize(rpc_result.body, &size_deserialize);

        const buf = try allocator.alloc(u8, size_deserialize);
        errdefer allocator.free(buf);

        const deserialized, _, _ = deserializeResult(rpc_result.body, buf);

        try self.mutex.lock(io);
        defer self.mutex.unlock(io);

        const req = self.pending_answers.map.getPtr(req_id) orelse {
            allocator.free(buf);
            return;
        };

        req.*.data = .{ .data = deserialized, .ptr = buf };
        req.*.event.set(io);
    }
}

fn handleNewDetailedInfo(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) ProcessMessageError!void {
    var buf: [@sizeOf(tl.ProtoMsgDetailedInfo)]u8 align(@alignOf(tl.ProtoMsgDetailedInfo)) = undefined;

    const msg_detailed, _, _ = tl.IProtoMsgDetailedInfo.deserialize(message.body, &buf);

    log.debug("Received ProtoMsgDetailedInfo - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });

    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    switch (msg_detailed) {
        .ProtoMsgDetailedInfo => |detailed_info| try self.pending_ack.append(allocator, detailed_info.answer_msg_id),
        .ProtoMsgNewDetailedInfo => |new_detailed_info| try self.pending_ack.append(allocator, new_detailed_info.answer_msg_id),
    }
}

fn handleFutureSalts(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) ProcessMessageError!void {
    var len: usize = 0;
    _ = tl.ProtoFutureSalts.deserializeSize(message.body[4..], &len);

    var found_req = false;

    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    self.requesting_salts = false;

    const buf = try allocator.alignedAlloc(u8, std.mem.Alignment.of(tl.ProtoFutureSalts), len);
    defer {
        if (!found_req) {
            allocator.free(buf);
        }
    }

    const salts, _, _ = tl.ProtoFutureSalts.deserialize(message.body[4..], buf);

    try self.salts.appendSlice(allocator, salts.salts);

    log.debug("Added {d} salts - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ salts.salts.len, self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });

    const req_id = self.pending_answers_idmap.get(salts.req_msg_id) orelse {
        // TODO: do something?
        return;
    };

    const req = self.pending_answers.map.getPtr(req_id) orelse {
        // TODO: do something?
        return;
    };

    found_req = true;

    req.*.data = .{ .data = tl.TL{ .ProtoFutureSalts = salts }, .ptr = buf, .alignment = .of(tl.ProtoFutureSalts) };
    req.*.event.set(io);

    //  const future_salts, _, _ = tl.ProtoFutureSalts.deserialize(message.body, &buf);

}

fn handlePong(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) ProcessMessageError!void {
    const buf = try allocator.alignedAlloc(u8, std.mem.Alignment.of(tl.ProtoPong), @sizeOf(tl.ProtoPong));

    const pong, _, _ = tl.ProtoPong.deserialize(message.body[4..], buf);
    log.debug("Received pong, ping_id: {} - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ pong.ping_id, self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });

    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    if (self.ping_value == pong.ping_id) {
        self.ping_disconnect = false;
    }

    const req_id = self.pending_answers_idmap.get(pong.msg_id) orelse {
        allocator.free(buf);
        return;
    };

    const req = self.pending_answers.map.getPtr(req_id) orelse {
        allocator.free(buf);
        return;
    };

    req.*.data = .{ .data = .{ .ProtoPong = pong }, .ptr = buf, .alignment = .of(tl.ProtoPong) };
    req.*.event.set(io);
}

fn handleMessageContainer(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) ProcessMessageError!void {
    const container = try tl.ProtoMessageContainer.deserializeContainer(allocator, message.body[4..]);
    defer allocator.free(container);

    for (container) |msg| {
        try self.processMessage(io, allocator, msg);
    }
}

fn handleGZipPacked(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) ProcessMessageError!void {
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

fn handleNewSessionCreated(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) ProcessMessageError!void {
    var buf: [@sizeOf(tl.ProtoNewSessionCreated)]u8 align(@alignOf(tl.ProtoNewSessionCreated)) = undefined;
    const new_session, _, _ = tl.ProtoNewSessionCreated.deserialize(message.body, &buf);

    log.debug("NewSessionCreated received from server, first_msg_id: {} - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ new_session.first_msg_id, self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });

    {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);

        self.time_synced = true;

        self.cancelUnprocessedRequests(io, new_session.first_msg_id);

        if (self.salts.items.len == 0) {
            try self.salts.append(allocator, .{
                .salt = new_session.server_salt,
                .valid_since = 0,
                .valid_until = 0,
            });
        }

        try self.pending_ack.append(allocator, message.msg_id);

        // TODO: signal the main update handler to recover updates
    }
}

fn processMessage(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) ProcessMessageError!void {
    //const allocator = self.arena.allocator();

    const id = std.mem.readInt(u32, message.body[0..4], .little);
    //std.debug.print("received {any}", .{tl.TL.identify(id)});

    if (tl.TL.identify(id)) |ty| {
        switch (ty) {
            .ProtoNewSessionCreated => try self.handleNewSessionCreated(io, allocator, message),
            .ProtoRPCResult => try self.handleRPCResult(io, allocator, tl.ProtoRPCResult.deserializeNoCopy(message.body[4..])),
            .ProtoMsgsAck => try self.handleMsgsAck(message),
            .ProtoBadMsgNotification, .ProtoBadServerSalt => try self.handleBadNotification(io, allocator, message),
            .ProtoMsgDetailedInfo, .ProtoMsgNewDetailedInfo => try self.handleNewDetailedInfo(io, allocator, message),
            .ProtoFutureSalts => try self.handleFutureSalts(io, allocator, message),
            .ProtoPong => try self.handlePong(io, allocator, message),
            .ProtoMessageContainer => try self.handleMessageContainer(io, allocator, message),
            .ProtoGzipPacked => try self.handleGZipPacked(io, allocator, message),
            else => {
                // std.debug.print("got {any} to handle", .{ty});
            },
        }
    } else {
        return ProcessMessageError.UnknownIncomingMessage;
    }
}

pub fn readerWorker(self: *Session, io: std.Io, allocator: std.mem.Allocator, transport: *Transport) !void {
    while (true) {
        const len = try transport.recvLen(io);

        const buf = try allocator.alloc(u8, len);
        defer allocator.free(buf);

        if (buf.len == 4) {
            const code = std.mem.readInt(u32, @ptrCast(buf[0..4]), .little);
            log.err("Received transport error {} - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ code, self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });

            if (code == 404) {
                return SessionError.Transport404;
            }
            return SessionError.TransportUnknown;
        }

        _ = try transport.recv(io, buf);

        try self.decryptMessage(io, buf);

        const message_bytes = buf[8 + 16 + 8 + 8 ..];

        const message = tl.ProtoMessage.deserializeNoCopy(message_bytes);

        ok: {
            if (!(message.msg_id % 4 == 1 or message.msg_id % 4 == 3)) {
                return SecurityError.MsgIdNotOdd;
            }

            if (self.stored_msg_ids.contains(message.msg_id)) {
                return SecurityError.DuplicatedMsgId;
            }

            // when the session is initialized for the first time, the internal time might be wrong, so we skip these checks until we are sure about it
            if (!self.time_synced) {
                break :ok;
            }

            const server_time = message.msg_id >> 32;
            const now = self.message_id.getUnix(io);

            // Security check: msg_ids over 30 seconds in the future or over 300 seconds in the past must be rejected
            if (server_time > now +% 30 or server_time < now -% 300) {
                return SecurityError.MsgIdTooOld;
            }
        }

        self.stored_msg_ids.push(message.msg_id);

        log.debug("Incoming message, type {any} - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ tl.TL.identify(std.mem.readInt(u32, @ptrCast(message.body[0..4]), .little)), self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });

        try self.processMessage(io, allocator, message);
    }
}

/// Decrypts an encrypted message in-place.
fn decryptMessage(self: *Session, io: std.Io, data: []u8) !void {
    const auth_key_id = data[0..8];
    if (!std.mem.eql(u8, &self.auth_key_id, auth_key_id)) {
        return SecurityError.AuthKeyMismatch;
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
        return SecurityError.MsgKeyMismatch;
    }

    //const salt = std.mem.readInt(u64, plaintext[0..8], .little); TODO: can we do something with it?
    const session_id = std.mem.readInt(u64, plaintext[8 .. 8 + 8], .little);
    const message_data_length = std.mem.readInt(u32, plaintext[8 + 8 + 8 + 4 .. 8 + 8 + 8 + 4 + 4], .little);

    if (!(message_data_length % 4 == 0 and message_data_length >= 0)) {
        return SecurityError.InvalidMsgLength;
    }

    const padding_len = plaintext.len - 32 - message_data_length;
    if (padding_len < 12 or message_data_length > plaintext.len) {
        return SecurityError.PaddingMismatch;
    }

    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    if (session_id != self.session_id) {
        return SecurityError.SessionIdMismatch;
    }
}

/// Determines how much padding is needed for the plaintext part of a message.
inline fn determineMessagePadding(len: usize) usize {
    // Padding must be 12-1024 bytes, total length divisible by 16
    const remainder = (len + 12) % 16;
    return if (remainder == 0) 12 else 12 + (16 - remainder);
}

fn payloadLen(requests: []const Request, pending_acks: []const u64) struct { usize, usize, bool } {
    // if we have more than one request, or we have pending acks to send, we'll use a message container
    const use_container = if (requests.len > 1 or pending_acks.len > 0) true else false;

    var data_size: usize = 0;

    if (use_container) {
        data_size += 4 // cid
            + 4; // len
    }

    if (pending_acks.len > 0) {
        data_size += 8 // msg_id
            + 4 // seq_no
            + 4 // bytes
            + (tl.IProtoMsgsAck{ .ProtoMsgsAck = &.{ .msg_ids = pending_acks } }).serializeSize();
    }

    for (requests) |req| {
        if (use_container) {
            data_size += 8 // msg_id
                + 4 // seq_no
                + 4; // bytes
        }
        data_size += req.data.len;
    }

    const offset_auth_key_id = 0;
    const offset_msg_key = offset_auth_key_id + 8;
    const offset_salt = offset_msg_key + 16;
    const offset_session_id = offset_salt + 8;
    const offset_message_id = offset_session_id + 8;
    const offset_seqno = offset_message_id + 8;
    const offset_len_data = offset_seqno + 4;
    const offset_data = offset_len_data + 4;
    const offset_padding = offset_data + data_size;
    const offset_end = offset_padding + determineMessagePadding(offset_padding - offset_salt);

    return .{ offset_end, data_size, use_container };
}

fn payloadCreate(self: *Session, io: std.Io, data_size: usize, requests: []const Request, pending_acks: []const u64, inner_msg_ids: []u64, out: []u8) void {
    const offset_auth_key_id = 0;
    const offset_msg_key = offset_auth_key_id + 8;
    const offset_salt = offset_msg_key + 16;
    const offset_session_id = offset_salt + 8;
    const offset_message_id = offset_session_id + 8;
    const offset_seqno = offset_message_id + 8;
    const offset_len_data = offset_seqno + 4;
    const offset_data = offset_len_data + 4;
    const offset_padding = offset_data + data_size;
    const offset_end = offset_padding + determineMessagePadding(offset_padding - offset_salt);
    _ = offset_end;

    const use_container = if (requests.len > 1 or pending_acks.len > 0) true else false;

    if (use_container) {
        std.mem.writeInt(u32, out[offset_data .. offset_data + 4], 0x73f1f8dc, .little);
        std.mem.writeInt(u32, out[offset_data + 4 .. offset_data + 4 + 4], @intCast(requests.len + (if (pending_acks.len > 0) @as(u32, 1) else 0)), .little);

        var b: usize = 0;

        if (pending_acks.len > 0) {
            const msg_id = self.message_id.get(io);
            std.mem.writeInt(u64, @ptrCast(out[offset_data + 4 + 4 + b .. offset_data + 4 + 4 + b + 8]), msg_id, .little);
            std.mem.writeInt(u32, @ptrCast(out[offset_data + 4 + 4 + b + 8 .. offset_data + 4 + 4 + b + 8 + 4]), self.nextSeqNo(false), .little);

            const data_wr = (tl.IProtoMsgsAck{ .ProtoMsgsAck = &.{ .msg_ids = pending_acks } }).serialize(out[offset_data + 4 + 4 + b + 8 + 4 + 4 ..]);

            std.mem.writeInt(u32, @ptrCast(out[offset_data + 4 + 4 + b + 8 + 4 .. offset_data + 4 + 4 + b + 8 + 4 + 4]), @intCast(data_wr), .little);

            b += 8 + 4 + 4 + data_wr;
        }

        for (requests, 0..) |req, i| {
            const msg_id = self.message_id.get(io);
            inner_msg_ids[i] = msg_id;
            if (req.id) |id| {
                self.pending_answers_idmap.putAssumeCapacity(msg_id, id);
                if (self.pending_answers.map.getPtr(id)) |pending_answer| {
                    pending_answer.*.proto_req_id = msg_id;
                }
            }

            std.mem.writeInt(u64, @ptrCast(out[offset_data + 4 + 4 + b .. offset_data + 4 + 4 + b + 8]), msg_id, .little);
            std.mem.writeInt(u32, @ptrCast(out[offset_data + 4 + 4 + b + 8 .. offset_data + 4 + 4 + b + 8 + 4]), self.nextSeqNo(req.content_related), .little);
            std.mem.writeInt(u32, @ptrCast(out[offset_data + 4 + 4 + b + 8 + 4 .. offset_data + 4 + 4 + b + 8 + 4 + 4]), @intCast(req.data.len), .little);
            @memcpy(out[offset_data + 4 + 4 + b + 8 + 4 + 4 .. offset_data + 4 + 4 + b + 8 + 4 + 4 + req.data.len], req.data);

            b += 8 + 4 + 4 + req.data.len;
        }
        return;
    }

    @memcpy(out[offset_data..offset_padding], requests[0].data);
}

pub fn pingWorker(self: *Session, io: std.Io, allocator: std.mem.Allocator) !void {
    // For now, I am implementing a separate worker that periodically sends PingDelayDisconnect. TODO: consider integrating pingWorker into writerWorker by using `select`
    while (true) {
        try self.ping_timeout.sleep(io);

        self.maybeRequestFutureSalts(io, allocator);

        const ping_id = brk: {
            try self.mutex.lock(io);
            defer self.mutex.unlock(io);

            if (self.ping_disconnect) {
                log.debug("no pong received for more than {d} seconds, disconnecting - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ PING_WRITE_INTERVAL_SECS * 2, self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });

                // TODO: handle proper way of disconnecting
                self.shutdown.store(true, .release);
                return;
            }

            self.ping_value = self.ping_value +% 1;
            self.ping_disconnect = true;

            break :brk self.ping_value;
        };

        log.debug("sending PingDelayDisconnect, id: {d} - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ ping_id, self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });

        try self.sendNoWait(io, allocator, tl.TL{ .ProtoPingDelayDisconnect = &.{ .ping_id = ping_id, .disconnect_delay = PING_WRITE_INTERVAL_SECS * 2 } });

        self.ping_timeout = .{ .deadline = std.Io.Clock.Timestamp.now(io, .boot).addDuration(.{ .raw = std.Io.Duration.fromSeconds(PING_WRITE_INTERVAL_SECS), .clock = .boot }) };
    }
}

pub fn writerWorker(self: *Session, io: std.Io, allocator: std.mem.Allocator, transport: *Transport) !void {
    {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);
        self.requesting_salts = false;
    }

    var batch: [MAX_WORKER_BATCH]Request = undefined;

    while (true) {
        const batch_size = try self.requests_queue.get(io, &batch, 1);

        log.debug("Processing {d} messages - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ batch_size, self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });

        defer {
            for (batch[0..batch_size]) |req| {
                allocator.free(req.data);
            }
        }

        errdefer {
            self.mutex.lockUncancelable(io);
            for (batch[0..batch_size]) |req| {
                if (req.id) |id| {
                    if (self.pending_answers.map.getPtr(id)) |pending_req| {
                        pending_req.*.event.set(io);
                    }
                }
            }
            self.mutex.unlock(io);
        }

        const buf, const inner_msg_ids = blk: {
            try self.mutex.lock(io);
            defer self.mutex.unlock(io);

            const pending_acks = self.pending_ack.items;
            self.pending_ack_inflight = pending_acks.len;
            errdefer self.pending_ack_inflight = 0;

            const offset_end, const data_size, const use_container = payloadLen(batch[0..batch_size], pending_acks);

            const inner_msg_ids = try allocator.alloc(u64, batch_size);
            errdefer allocator.free(inner_msg_ids);

            const buf = try allocator.alloc(u8, offset_end);
            errdefer allocator.free(buf);

            try self.pending_answers_idmap.ensureUnusedCapacity(allocator, batch_size);

            self.payloadCreate(io, data_size, batch[0..batch_size], pending_acks, inner_msg_ids, buf);

            const seqno = self.nextSeqNo(if (use_container) false else batch[0..batch_size][0].content_related);

            const msgid = self.message_id.get(io);
            if (!use_container) {
                if (batch[0].id) |id| {
                    try self.pending_answers_idmap.put(allocator, msgid, id);
                    if (self.pending_answers.map.getPtr(id)) |pending_answer| {
                        pending_answer.*.proto_req_id = msgid;
                    }
                    inner_msg_ids[0] = msgid;
                }
            }

            try self.encryptMessage(io, buf, seqno, msgid, data_size);

            break :blk .{ buf, inner_msg_ids };
        };

        errdefer {
            self.mutex.lockUncancelable(io);
            self.pending_ack_inflight = 0;
            self.mutex.unlock(io);
        }

        defer allocator.free(inner_msg_ids);
        defer allocator.free(buf);

        errdefer {
            self.mutex.lockUncancelable(io);
            for (inner_msg_ids) |msgid| {
                _ = self.pending_answers_idmap.swapRemove(msgid);
            }
            self.mutex.unlock(io);
        }
        try transport.write(io, buf);

        self.mutex.lockUncancelable(io);
        const remaining_len = self.pending_ack.items.len - self.pending_ack_inflight;
        std.mem.copyForwards(u64, self.pending_ack.items[0..remaining_len], self.pending_ack.items[self.pending_ack_inflight..]);
        self.pending_ack.items.len = remaining_len;
        self.pending_ack_inflight = 0;
        self.mutex.unlock(io);
    }
}

/// Enqueues a new TL function into the reader worker queue, without waiting for it to be acknowledged
pub fn sendNoWait(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.TL) !void {
    if (self.shutdown.load(.acquire)) {
        return SendError.Shutdown;
    }

    log.debug("Sending (nowait) {any} - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ message, self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });

    const len_serialized = message.serializeSize();

    const buf = try allocator.alloc(u8, len_serialized);
    errdefer allocator.free(buf);

    _ = message.serialize(buf);

    try self.requests_queue.putOne(io, .{ .id = null, .data = buf, .content_related = isContentRelated(message) });
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

    const id = self.current_id.fetchAdd(1, .seq_cst);

    defer {
        self.mutex.lockUncancelable(io);

        if (self.pending_answers.map.fetchSwapRemove(id)) |kv| {
            allocator.destroy(kv.value);
        }
        self.mutex.unlock(io);
    }

    log.debug("Sending {any}, id: {d} - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ message, id, self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });

    const answer = answ: {
        const buf = try allocator.alloc(u8, len_serialized);

        errdefer allocator.free(buf);

        _ = message.serialize(buf);

        const answer = brk: {
            try self.mutex.lock(io);
            defer self.mutex.unlock(io);

            const req = try self.pending_answers.create(allocator, id);

            req.deserializeResult = deserializeResult;
            req.deserializeResultSize = deserializeResultSize;

            break :brk req;
        };

        try self.requests_queue.putOne(io, .{ .id = id, .data = buf, .content_related = isContentRelated(message) });

        break :answ answer;
    };

    defer {
        self.mutex.lockUncancelable(io);

        if (answer.proto_req_id) |proto_req_id| {
            _ = self.pending_answers_idmap.swapRemove(proto_req_id);
        }
        self.mutex.unlock(io);
    }

    {
        _ = self.waiting_requests.fetchAdd(1, .seq_cst);
        defer {
            const sub = self.waiting_requests.fetchSub(1, .seq_cst);
            if (sub == 1) {
                self.shutdown_event.set(io);
            }
        }

        try answer.event.wait(io);
    }

    if (answer.data) |data| {
        return data catch |err| {
            if (err == SendError.Resend) {
                log.debug("Need to resend message, id: {d} - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ id, self.dc_id, self.is_test_mode, self.is_cdn, self.is_media });
                return self.send(io, allocator, message);
            }
            return err;
        };
    } else {
        return SendError.Unknown;
    }
}

/// Encrypts raw bytes in-place into a message to be sent directly to Telegram's servers.
/// The mutex is assumed to be already acquired.
fn encryptMessage(self: *Session, io: std.Io, data: []u8, seqno: usize, message_id: u64, message_len: usize) !void {
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
    std.mem.writeInt(u64, data[offset_salt..][0..8], self.getSalt(io).salt, .little);
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
    self.shutdown_event.reset();

    var it = self.pending_answers.map.iterator();
    while (it.next()) |pending_req| {
        pending_req.value_ptr.*.event.set(io);
    }
    if (self.waiting_requests.load(.acquire) == 0) {
        self.shutdown_event.set(io);
    }
    self.mutex.unlock(io);

    self.shutdown_event.waitUncancelable(io);
}

/// Before calling this function, make sure no worker is running and to have deleted every event in `pending_requests` (use `destroyRequests` for that)
pub fn deinit(self: *Session, io: std.Io, allocator: std.mem.Allocator) void {
    // keep the mutex always locked, since this session shouldn't be used ever again
    self.mutex.lockUncancelable(io);
    while (true) {
        var requests: [10]Request = undefined;
        const len = self.requests_queue.getUncancelable(io, &requests, 0) catch {
            break;
        };
        if (len == 0) {
            break;
        }

        for (0..len) |i| {
            allocator.free(requests[i].data);
        }
    }
    self.requests_queue.close(io);
    self.salts.deinit(allocator);
    self.pending_ack.deinit(allocator);
    self.pending_answers_idmap.deinit(allocator);

    var it = self.pending_answers.map.iterator();
    while (it.next()) |pending_req| {
        const req = pending_req.value_ptr.*;
        if (req.data) |data| {
            req.data = null;
            const data_ok = data catch {
                allocator.destroy(req);
                continue;
            };
            data_ok.deinit(allocator);
        }
        allocator.destroy(req);
    }
    self.pending_answers.map.deinit(allocator);
}

pub fn init(io: std.Io, allocator: std.mem.Allocator, auth_key: [256]u8, salt: tl.ProtoFutureSalt, dc_id: u8, test_mode: bool, is_cdn: bool, is_media: bool) !Session {
    log.info("Initializing session - dc {}, test_mode: {}, is_cdn: {}, is_media: {}", .{ dc_id, test_mode, is_cdn, is_media });
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
        .pending_answers = .{
            .map = .{},
        },
        .current_id = .init(0),
        .shutdown = .init(false),
        .waiting_requests = .init(0),
        .shutdown_event = .unset,
        .mutex = .init,
        .pending_answers_idmap = .{},
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
    self.message_id.updateTime(io, @intCast((std.Io.Clock.now(.real, io)).toSeconds()));

    try self.salts.append(allocator, salt);

    self.ping_timeout = .{ .deadline = std.Io.Clock.Timestamp.now(io, .boot).addDuration(.{ .raw = std.Io.Duration.fromSeconds(PING_WRITE_INTERVAL_SECS), .clock = .boot }) };

    return self;
}
