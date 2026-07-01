const tl = @import("tl");
const std = @import("std");
const Transport = @import("../transport.zig").Transport;
const MessageID = @import("./message_id.zig");
const utils = @import("./utils.zig");
const deserializeStringNoCopy = @import("tl_base").deserializeStringNoCopy;
const TransportConnector = @import("../transport_connector.zig");
const DcId = @import("../utils.zig").DcId;
const AuthKey = @import("./auth_key.zig");
const ClientManager = @import("../client_manager.zig");
const MT2Crypto = @import("../crypto/mt2.zig");
const MT1Crypto = @import("../crypto/mt1.zig");

const QUEUE_SIZE = 20;
const SALT_THRESHOLD = 15;
const SALTS_TO_OBTAIN = 64;
const MAX_WORKER_BATCH = 10;
const MSG_ID_CHECK_SET_SIZE = 30;
const PING_WRITE_INTERVAL_SECS = 30;

const log = std.log.scoped(.mzproto_session);

pub fn isContentRelated(obj: tl.TL.Enum) bool {
    return switch (obj) {

        // A client must never mark msgs_ack, msg_container, msg_copy, gzip_packed constructors (i.e. containers and acknowledgements)
        // as content-related, or else a bad_msg_notification with error_code=34 will be emitted.

        .ProtoMsgsAck,
        .ProtoMessageContainer,
        //.ProtoMsgCopy,
        .ProtoGzipPacked,

        // Service messages documented as not requiring acknowledgment.
        .ProtoPing,
        .ProtoPong,
        .ProtoPingDelayDisconnect,
        .ProtoFutureSalt,
        .ProtoFutureSalts,
        .ProtoBadMsgNotification,
        .ProtoBadServerSalt,
        .ProtoMsgsStateInfo,
        .ProtoMsgsAllInfo,
        .ProtoMsgDetailedInfo,
        .ProtoMsgNewDetailedInfo,
        .ProtoHttpWait,
        => false,

        // A client must always mark all API-level RPC queries as content-related,
        // or else a bad_msg_notification with error_code=35 will be emitted.
        else => true,
    };
}

const ReconnectReason = enum(u2) {
    none = 0,
    reconnect_only = 1,
    refresh_temp_key = 2,
};

const AcknowledgmentStatus = enum {
    unknown,
    sent,
    ack,
    answered,
};

fn requestReconnect(self: *Session, io: std.Io, reason: ReconnectReason) void {
    if (self.shutdown.load(.acquire)) {
        return;
    }
    log.debug("reconnection requested ({any}) {f}", .{ reason, self.dc });
    self.mutex.lockUncancelable(io);
    defer self.mutex.unlock(io);

    if (@intFromEnum(reason) > @intFromEnum(self.reconnect_reason)) {
        self.reconnect_reason = reason;
    }

    self.conn_restart.set(io);
}

const Session = @This();

const PendingAnswer = struct {
    event: std.Io.Event = .unset,
    status: AcknowledgmentStatus = .unknown,
    last_probed_at: std.Io.Timestamp = .zero,
    proto_req_id: ?u64 = null,
    proto_container_id: ?u64 = null,
    deserializeResultSize: *const (fn (in: []const u8, size: *usize) usize),
    deserializeResult: *const (fn (noalias in: []const u8, noalias out: []u8) struct { tl.TL, usize, usize }),
    data: ?SendError!utils.Deserialized,
};

const Request = struct {
    id: ?u32,
    data: []u8,
    content_related: bool,
    message_id: ?u64 = null,
};

ping_disconnect: bool = false, // if this is set to true, the connection must be closed after the timeout is set
ping_value: u32 = 0,

new_session_message_id: u64 = 0,

seq_no: usize,

salts: std.ArrayList(tl.ProtoFutureSalt),
requesting_salts: bool = false,

stored_msg_ids: utils.Ring(u64, MSG_ID_CHECK_SET_SIZE) = .{ .buf = @splat(0) },

pending_ack: std.ArrayList(u64),
pending_ack_inflight: usize = 0,

connection_bound_auth_key: bool = false,
init_ok: bool = false,

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
// the list maps directly to `pending_answers`, not to `pending_answers_idmap`
pending_containers: std.AutoArrayHashMapUnmanaged(u64, std.ArrayListUnmanaged(u32)),

auth_key: AuthKey.GeneratedAuthKey = undefined,
auth_key_id: [8]u8,

// Unless noted, for every field in this struct, we need to acquire the mutex first before using them
mutex: std.Io.Mutex,

// Thread-safe
requests_queue_buffer: [QUEUE_SIZE]Request,
requests_queue: std.Io.Queue(Request),
bootstrap_queue: std.Io.Queue(Request),
current_id: std.atomic.Value(u32) = .init(0),
shutdown: std.atomic.Value(bool) = .init(false),
pending_requests: std.atomic.Value(u32) = .init(0),
shutdown_event: std.Io.Event = .unset,
freeze_requests: std.atomic.Value(bool) = .init(false),
freeze_event: std.Io.Event = .unset,
auth_key_bound_event: std.Io.Event = .unset,

// not thread-safe, scope specific
wait_and_recreate_auth_key: bool = false,
reconnect_reason: ReconnectReason = .refresh_temp_key,
conn_restart: std.Io.Event = .unset,
retry_backlog: std.ArrayListUnmanaged(Request) = .empty,
client_manager: *ClientManager,

// Not specifically thread-safe, but they will not change for the entire lifecycle of the session
dc: DcId,
perm_auth_key: *const [256]u8,
perm_auth_key_id: [8]u8,
id: u32,

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

const MessageContainerLayout = struct {
    pub const CONSTRUCTOR = 0;
    pub const COUNT = CONSTRUCTOR + 4;
    pub const MESSAGES = COUNT + 4;

    pub const MESSAGE_ID = 0;
    pub const SEQNO = MESSAGE_ID + 8;
    pub const BODY_LEN = SEQNO + 4;
    pub const BODY = BODY_LEN + 4;

    pub inline fn messageOffset(container_body_offset: usize, cursor: usize) usize {
        return container_body_offset + MESSAGES + cursor;
    }

    pub inline fn messageEnd(container_body_offset: usize, cursor: usize, body_len: usize) usize {
        return messageOffset(container_body_offset, cursor) + BODY + body_len;
    }
};

pub fn format(
    self: Session,
    writer: *std.Io.Writer,
) !void {
    try writer.print("[session {d} - dc{d}", .{ self.id, self.dc.id });
    if (self.testmode) {
        _ = try writer.write(" testmode");
    }
    if (self.media) {
        _ = try writer.write(" media");
    }

    _ = try writer.write("]");

    try writer.flush();
}

/// The mutex is assumed to be already acquired.
fn removeMessageFromContainer(self: *Session, allocator: std.mem.Allocator, container_id: u64, id: u64) void {
    if (self.pending_containers.getPtr(container_id)) |container| {
        for (container.items, 0..) |c_msg_id, i| {
            if (c_msg_id == id) {
                _ = container.swapRemove(i);
                break;
            }
        }

        if (container.items.len == 0) {
            container.deinit(allocator);
            _ = self.pending_containers.swapRemove(container_id);
        }
    }
}

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

    log.debug("Requesting more salts - {f}", .{self.dc});

    self.sendNoWait(io, allocator, tl.TL{ .ProtoGetFutureSalts = &.{ .num = SALTS_TO_OBTAIN } }, null, false) catch {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);

        self.requesting_salts = false;
    };
}

/// The mutex is assumed to be already acquired.
fn resendUnprocessedRequests(self: *Session, allocator: std.mem.Allocator, io: std.Io, first_msg_id: u64) void {
    var it = self.pending_answers_idmap.iterator();
    while (it.next()) |msg_id| {
        if (self.pending_answers.map.get(msg_id.value_ptr.*)) |answer| {
            const effective_msg_id = answer.proto_container_id orelse answer.proto_req_id;
            if (effective_msg_id != null and first_msg_id > effective_msg_id.?) {
                if (answer.data != null) {
                    continue;
                }
                answer.data = SendError.Resend;
                if (answer.proto_container_id) |container_id| {
                    self.removeMessageFromContainer(allocator, container_id, msg_id.value_ptr.*);
                }

                answer.event.set(io);
            }
        }
    }
}

fn handleMsgsAck(self: *Session, allocator: std.mem.Allocator, io: std.Io, message: tl.ProtoMessage) !void {
    var size: usize = 0;
    _ = tl.ProtoMsgsAck.deserializeSize(message.body[4..], &size);

    const buf = try allocator.alignedAlloc(u8, std.mem.Alignment.of(tl.ProtoMsgsAck), size);
    defer allocator.free(buf);

    const ack_msgs, _, _ = tl.ProtoMsgsAck.deserialize(message.body[4..], buf);

    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    for (ack_msgs.msg_ids) |ack_msg_id| {
        if (self.pending_containers.get(ack_msg_id)) |container| {
            for (container.items) |msg_id| {
                if (self.pending_answers.map.get(msg_id)) |pending_answer| {
                    if (pending_answer.*.status != .answered) {
                        pending_answer.*.status = .ack;
                        pending_answer.*.last_probed_at = .now(io, .boot);
                    }
                }
            }
            continue;
        }

        if (self.pending_answers_idmap.get(ack_msg_id)) |id| {
            if (self.pending_answers.map.get(id)) |pending_answer| {
                if (pending_answer.*.status != .answered) {
                    pending_answer.*.status = .ack;
                    pending_answer.*.last_probed_at = .now(io, .boot);
                }
            }
        }
    }
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
                log.warn("got ProtoBadServerSalt - {f}", .{self.dc});
                self.requesting_salts = false;
                if (self.salts.items.len == 0) {
                    try self.salts.append(allocator, .{
                        .salt = x.new_server_salt,
                        .valid_since = 0,
                        .valid_until = 0,
                    });
                } else {
                    self.salts.shrinkAndFree(allocator, 1);
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
                        log.warn("got ProtoBadMsgNotification, msg_id too low - {f}", .{self.dc});
                        self.message_id.updateTime(io, message.msg_id >> 32);
                    },
                    // msg_id too high (similar to the previous case, the client time has to be synchronized,
                    // and the message re-sent with the correct msg_id)
                    17 => {
                        log.warn("got ProtoBadMsgNotification, msg_id too high - {f}", .{self.dc});
                        self.message_id.updateTime(io, message.msg_id >> 32);
                    },
                    // incorrect two lower order msg_id bits (the server expects client message msg_id to be divisible by 4)
                    18 => {
                        // an error like that should never happen, but you never know...
                        log.warn("got ProtoBadMsgNotification, incorrect two lower order msg_id bits - {f}", .{self.dc});
                        self.message_id.updateTime(io, message.msg_id >> 32);
                    },
                    // container msg_id is the same as msg_id of a previously received message (this must never happen)
                    19 => {
                        // what should I even do with an error like that?
                        log.warn("got ProtoBadMsgNotification, container msg_id is the same as msg_id of a previously received message - {f}", .{self.dc});
                    },
                    // message too old, and it cannot be verified whether the server has received a message with this msg_id or not
                    20 => {
                        log.warn("got ProtoBadMsgNotification, message too old, and it cannot be verified whether the server has received a message with this msg_id or not - {f}", .{self.dc});
                    },
                    // msg_seqno too low (the server has already received a message with a lower msg_id but with either
                    // a higher or an equal and odd seqno)
                    32 => {
                        log.warn("got ProtoBadMsgNotification, msg_seqno too low - {f}", .{self.dc});
                        self.seq_no += 64;
                    },
                    // msg_seqno too high (similarly, there is a message
                    // with a higher msg_id but with either a lower or an equal and odd seqno)
                    33 => {
                        log.warn("got ProtoBadMsgNotification, msg_seqno too high  -{f}", .{self.dc});
                        self.seq_no -= 16;
                    },
                    // an even msg_seqno expected (irrelevant message), but odd received
                    34 => {
                        log.warn("got ProtoBadMsgNotification, an even msg_seqno expected, but odd received - {f}", .{self.dc});
                    },
                    // odd msg_seqno expected (relevant message), but even received
                    35 => {
                        log.warn("got ProtoBadMsgNotification, odd msg_seqno expected, but even received - {f}", .{self.dc});
                    },
                    // invalid container.
                    64 => {
                        // very descriptive. Thanks, Telegram!
                        log.warn("got ProtoBadMsgNotification, invalid container - {f}", .{self.dc});
                    },
                    else => {
                        log.warn("got ProtoBadMsgNotification, unknown code {d} - {f}", .{ x.error_code, self.dc });
                    },
                }
                break :brk x.bad_msg_id;
            },
        }
    };

    if (self.pending_containers.getPtr(bad_msg_id)) |container| {
        for (container.items) |id| {
            if (self.pending_answers.map.get(id)) |answer| {
                answer.status = .answered;
                answer.last_probed_at = .now(io, .boot);
                answer.data = SendError.Resend;

                answer.event.set(io);
            }
        }
        container.deinit(allocator);
        _ = self.pending_containers.swapRemove(bad_msg_id);
        return;
    }

    const req_id = self.pending_answers_idmap.get(bad_msg_id) orelse {
        // TODO: do something?
        return;
    };

    const answer_ptr = self.pending_answers.map.getPtr(req_id) orelse {
        // TODO: do something?
        return;
    };

    answer_ptr.*.status = .answered;
    answer_ptr.*.last_probed_at = .now(io, .boot);

    if (answer_ptr.*.proto_container_id) |container_id| {
        self.removeMessageFromContainer(allocator, container_id, req_id);
    }

    answer_ptr.*.data = SendError.Resend;
    answer_ptr.*.event.set(io);
}

fn tryToRecover(self: *Session, err: *const tl.ProtoRpcError, req: *PendingAnswer) bool {
    _ = req;
    if (std.mem.eql(u8, err.error_message, "CONNECTION_NOT_INITED") or std.mem.eql(u8, err.error_message, "CONNECTION_LAYER_INVALID")) {
        self.init_ok = false;
        return true;
    }
    return false;
}

fn handleRPCResult(self: *Session, io: std.Io, allocator: std.mem.Allocator, rpc_result: tl.ProtoRPCResult) ProcessMessageError!void {
    const req_id, const deserializeResultSize, const deserializeResult = blk: {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);

        const req_id = self.pending_answers_idmap.get(rpc_result.req_msg_id) orelse {
            // TODO: do something?
            log.warn("Received unmapped RPC Result {d} - {f}", .{ rpc_result.req_msg_id, self.dc });
            return;
        };

        const req = self.pending_answers.map.getPtr(req_id) orelse {
            // TODO: do something?
            log.warn("Received unmapped RPC Result {d}->{d} - {f}", .{ rpc_result.req_msg_id, req_id, self.dc });
            return;
        };

        break :blk .{ req_id, req.*.deserializeResultSize, req.*.deserializeResult };
    };

    log.debug("Received RPC Result, {d}->{d} - {f}", .{ rpc_result.req_msg_id, req_id, self.dc });

    const id = tl.TL.identify(std.mem.readInt(u32, rpc_result.body[0..4], .little));

    const deserialized, const buf = blk: {
        if (id == .ProtoGzipPacked) {
            const gzip = deserializeStringNoCopy(rpc_result.body[4..]);
            var reader = std.Io.Reader.fixed(gzip);

            var decompress = std.compress.flate.Decompress.init(&reader, .gzip, &.{});

            const decompressed = try decompress.reader.allocRemaining(allocator, .limited64(4000000));
            defer allocator.free(decompressed);

            var size_deserialize: usize = 0;
            _ = deserializeResultSize(decompressed, &size_deserialize);

            const buf = try allocator.alloc(u8, size_deserialize);
            errdefer allocator.free(buf);

            const deserialized, _, _ = deserializeResult(decompressed, buf);
            break :blk .{ deserialized, buf };
        }

        if (id == .ProtoRpcError) {
            var size: usize = 0;
            _ = tl.ProtoRpcError.deserializeSize(rpc_result.body[4..], &size);

            const buf = try allocator.alignedAlloc(u8, std.mem.Alignment.of(tl.ProtoRpcError), size);
            errdefer allocator.free(buf);
            const err, _, _ = tl.ProtoRpcError.deserialize(rpc_result.body[4..], buf);

            break :blk .{ tl.TL{ .ProtoRpcError = err }, buf };
        }

        var size_deserialize: usize = 0;
        _ = deserializeResultSize(rpc_result.body, &size_deserialize);

        const buf = try allocator.alloc(u8, size_deserialize);
        errdefer allocator.free(buf);

        const deserialized, _, _ = deserializeResult(rpc_result.body, buf);

        break :blk .{ deserialized, buf };
    };

    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    var buf_used = false;

    defer {
        if (!buf_used) {
            allocator.free(buf);
        }
    }

    const answer = self.pending_answers.map.getPtr(req_id) orelse {
        return;
    };

    if (answer.*.proto_container_id) |container_id| {
        self.removeMessageFromContainer(allocator, container_id, req_id);
    }

    if (deserialized == .ProtoRpcError) {
        if (self.tryToRecover(deserialized.ProtoRpcError, answer.*)) {
            //allocator.free(buf);

            //if (answer.*.proto_container_id) |container_id| {
            //    self.removeMessageFromContainer(allocator, container_id, req_id);
            //}

            answer.*.data = SendError.Resend;
            answer.*.event.set(io);
            return;
        }
        answer.*.data = .{ .ptr = buf, .alignment = .of(tl.ProtoRpcError), .data = deserialized };
    } else {
        answer.*.data = .{ .data = deserialized, .ptr = buf };
    }

    buf_used = true;

    answer.*.status = .answered;
    answer.*.last_probed_at = .now(io, .boot);

    answer.*.event.set(io);

    self.init_ok = true;
}

fn handleNewDetailedInfo(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) ProcessMessageError!void {
    var buf: [@sizeOf(tl.ProtoMsgDetailedInfo)]u8 align(@alignOf(tl.ProtoMsgDetailedInfo)) = undefined;

    const msg_detailed, _, _ = tl.IProtoMsgDetailedInfo.deserialize(message.body, &buf);

    log.debug("Received ProtoMsgDetailedInfo - {f}", .{self.dc});

    // TODO: check this in detail, we might want to handle things differently

    switch (msg_detailed) {
        // The docs say this constructor is sent when the client sends an rpc request with a duplicate msg_id and the response is large.
        // This shouldn't probably happen normally since every message sent by the client always have a fresh msg_id, but handling is a good idea nonetheless
        .ProtoMsgDetailedInfo => |detailed_info| {
            const resend = resend: {
                try self.mutex.lock(io);
                defer self.mutex.unlock(io);

                const contains = self.pending_answers_idmap.contains(detailed_info.msg_id);

                if (!contains) {
                    try self.pending_ack.append(allocator, detailed_info.answer_msg_id);
                }

                break :resend contains;
            };
            if (resend) {
                self.sendNoWait(io, allocator, tl.TL{ .ProtoMsgResendReq = &.{ .msg_ids = &.{detailed_info.answer_msg_id} } }, null, false) catch {
                    //
                };
            }
        },
        // This variant is used we the server sends a message that is not bound to an rpc_result (eg. updates).
        // We will probably never need it since this part is generally handled by the higher-level update handler
        .ProtoMsgNewDetailedInfo => |new_detailed_info| {
            self.sendNoWait(io, allocator, tl.TL{ .ProtoMsgResendReq = &.{ .msg_ids = &.{new_detailed_info.answer_msg_id} } }, null, false) catch {
                //
            };
        },
    }
}

inline fn handleFutureSalt(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) ProcessMessageError!void {
    var buf: [@sizeOf(tl.ProtoFutureSalt)]u8 align(@alignOf(tl.ProtoFutureSalt)) = undefined;
    const future_salt, _, _ = tl.ProtoFutureSalt.deserialize(message.body[4..], &buf);

    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    self.requesting_salts = false;

    try self.salts.append(allocator, future_salt.*);
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

    log.debug("Added {d} salts - {f}", .{ salts.salts.len, self.dc });

    const req_id = self.pending_answers_idmap.get(salts.req_msg_id) orelse {
        // TODO: do something?
        return;
    };

    const answer = self.pending_answers.map.getPtr(req_id) orelse {
        // TODO: do something?
        return;
    };

    found_req = true;

    answer.*.status = .answered;
    answer.*.last_probed_at = .now(io, .boot);

    if (answer.*.proto_container_id) |container_id| {
        self.removeMessageFromContainer(allocator, container_id, req_id);
    }

    answer.*.data = .{ .data = tl.TL{ .ProtoFutureSalts = salts }, .ptr = buf, .alignment = .of(tl.ProtoFutureSalts) };
    answer.*.event.set(io);

    //  const future_salts, _, _ = tl.ProtoFutureSalts.deserialize(message.body, &buf);

}

fn handlePong(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) ProcessMessageError!void {
    const buf = try allocator.alignedAlloc(u8, std.mem.Alignment.of(tl.ProtoPong), @sizeOf(tl.ProtoPong));

    const pong, _, _ = tl.ProtoPong.deserialize(message.body[4..], buf);
    log.debug("Received pong, ping_id: {} - {f}", .{ pong.ping_id, self.dc });

    self.mutex.lock(io) catch |err| {
        allocator.free(buf);
        return err;
    };
    defer self.mutex.unlock(io);

    if (self.ping_value == pong.ping_id) {
        self.ping_disconnect = false;
    }

    const req_id = self.pending_answers_idmap.get(pong.msg_id) orelse {
        allocator.free(buf);
        return;
    };

    const answer = self.pending_answers.map.getPtr(req_id) orelse {
        allocator.free(buf);
        return;
    };

    answer.*.status = .answered;
    answer.*.last_probed_at = .now(io, .boot);

    if (answer.*.proto_container_id) |container_id| {
        self.removeMessageFromContainer(allocator, container_id, req_id);
    }

    answer.*.data = .{ .data = .{ .ProtoPong = pong }, .ptr = buf, .alignment = .of(tl.ProtoPong) };
    answer.*.event.set(io);
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
    const new_session, _, _ = tl.ProtoNewSessionCreated.deserialize(message.body[4..], &buf);

    {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);

        // Especially when the session is first created, the connection might die before the client has a chance to acknowledge the message,
        //  so we keep track of the message id of the last message sent to prevent duplicates

        if (self.new_session_message_id == message.msg_id) {
            return;
        }
        self.new_session_message_id = message.msg_id;

        log.debug("NewSessionCreated received from server, first_msg_id: {} - {f}", .{ new_session.first_msg_id, self.dc });

        self.resendUnprocessedRequests(allocator, io, new_session.first_msg_id);

        if (self.salts.items.len > 0) {
            self.salts.shrinkAndFree(allocator, 1);
            self.salts.items[0] = .{ .salt = new_session.server_salt, .valid_since = 0, .valid_until = 0 };
        } else {
            try self.salts.append(allocator, .{
                .salt = new_session.server_salt,
                .valid_since = 0,
                .valid_until = 0,
            });
        }

        // TODO: signal the main update handler to recover updates
    }
}

inline fn handleStateInfo(self: *Session, allocator: std.mem.Allocator, io: std.Io, message: tl.ProtoMessage) ProcessMessageError!void {
    var size: usize = 0;
    _ = tl.ProtoMsgsStateInfo.deserializeSize(message.body[4..], &size);
    const buf = try allocator.alignedAlloc(u8, std.mem.Alignment.of(tl.ProtoMsgsStateInfo), size);
    const state_info, _, _ = tl.ProtoMsgsStateInfo.deserialize(message.body[4..], buf);

    self.mutex.lock(io) catch |err| {
        allocator.free(buf);
        return err;
    };
    defer self.mutex.unlock(io);

    const req_id = self.pending_answers_idmap.get(state_info.req_msg_id) orelse {
        allocator.free(buf);
        return;
    };

    const answer = self.pending_answers.map.getPtr(req_id) orelse {
        allocator.free(buf);
        return;
    };

    answer.*.status = .answered;
    answer.*.last_probed_at = .now(io, .boot);
    if (answer.*.proto_container_id) |container_id| {
        self.removeMessageFromContainer(allocator, container_id, req_id);
    }

    answer.*.data = .{ .data = .{ .ProtoMsgsStateInfo = state_info }, .ptr = buf, .alignment = .of(tl.ProtoMsgsStateInfo) };
    answer.*.event.set(io);
}

inline fn handleMsgsAllInfo(self: *Session, allocator: std.mem.Allocator, io: std.Io, message: tl.ProtoMessage) ProcessMessageError!void {
    var size: usize = 0;
    _ = tl.ProtoMsgsAllInfo.deserializeSize(message.body[4..], &size);
    const buf = try allocator.alignedAlloc(u8, std.mem.Alignment.of(tl.ProtoMsgsAllInfo), size);
    defer allocator.free(buf);

    const all_info, _, _ = tl.ProtoMsgsAllInfo.deserialize(message.body[4..], buf);

    return self.pushStateInfo(allocator, io, all_info.msg_ids, all_info.info);
}

inline fn handlePing(self: *Session, allocator: std.mem.Allocator, io: std.Io, message: tl.ProtoMessage) ProcessMessageError!void {
    var buf: [@sizeOf(tl.ProtoPing)]u8 align(@alignOf(tl.ProtoPing)) = undefined;
    const ping, _, _ = tl.ProtoPing.deserialize(message.body[4..], &buf);

    log.debug("Received ping request from server, ping_id: {}, msg_id: {} - {f}", .{ ping.ping_id, message.msg_id, self.dc });

    self.sendNoWait(io, allocator, tl.TL{ .ProtoPong = &.{ .ping_id = ping.ping_id, .msg_id = message.msg_id } }, null, false) catch {};
}

fn processMessage(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.ProtoMessage) ProcessMessageError!void {
    //const allocator = self.arena.allocator();

    const id = std.mem.readInt(u32, message.body[0..4], .little);
    //std.debug.print("received {any}", .{tl.TL.identify(id)});

    if (tl.TL.identify(id)) |ty| {
        switch (ty) {
            .ProtoNewSessionCreated => try self.handleNewSessionCreated(io, allocator, message),
            .ProtoRPCResult => try self.handleRPCResult(io, allocator, tl.ProtoRPCResult.deserializeNoCopy(message.body[4..])),
            .ProtoMsgsAck => try self.handleMsgsAck(allocator, io, message),
            .ProtoBadMsgNotification, .ProtoBadServerSalt => try self.handleBadNotification(io, allocator, message),
            .ProtoMsgDetailedInfo, .ProtoMsgNewDetailedInfo => try self.handleNewDetailedInfo(io, allocator, message),
            .ProtoFutureSalt => try self.handleFutureSalt(io, allocator, message),
            .ProtoFutureSalts => try self.handleFutureSalts(io, allocator, message),
            .ProtoPong => try self.handlePong(io, allocator, message),
            .ProtoPing => try self.handlePing(allocator, io, message),
            .ProtoMessageContainer => try self.handleMessageContainer(io, allocator, message),
            .ProtoMsgsAllInfo => try self.handleMsgsAllInfo(allocator, io, message),
            .ProtoGzipPacked => try self.handleGZipPacked(io, allocator, message),
            .ProtoMsgsStateInfo => try self.handleStateInfo(allocator, io, message),
            else => {
                // TODO: send to client manager
            },
        }

        // if the seqno is odd, then it needs to be acknowledged
        if ((message.seqno & 1) != 0) {
            self.mutex.lockUncancelable(io);
            defer self.mutex.unlock(io);

            try self.pending_ack.append(allocator, message.msg_id);
        }
    } else {
        return ProcessMessageError.UnknownIncomingMessage;
    }
}

fn readerWorker(self: *Session, io: std.Io, allocator: std.mem.Allocator, transport: *Transport) std.Io.Cancelable!void {
    while (true) {
        const len = transport.recvLen(io) catch {
            std.Io.checkCancel(io) catch {
                return;
            };
            self.requestReconnect(io, .reconnect_only);
            return;
        };

        const buf = allocator.alloc(u8, len) catch {
            // TODO: handle correctly?
            continue;
        };
        defer allocator.free(buf);

        if (buf.len == 4) {
            const code = std.mem.readInt(u32, @ptrCast(buf[0..4]), .little);
            log.err("Received transport error {} - {f}", .{ code, self.dc });

            if (code == 404) {
                //return SessionError.Transport404;
            }
            //return SessionError.TransportUnknown;
            self.requestReconnect(io, .refresh_temp_key);
            return;
        }

        _ = transport.recv(io, buf) catch {
            std.Io.checkCancel(io) catch {
                return;
            };
            self.requestReconnect(io, .reconnect_only);
            return;
        };

        self.decryptMessage(io, buf) catch |err| {
            std.Io.checkCancel(io) catch {
                return;
            };
            log.err("failed to decrypt message ({s}) - {f}", .{ @errorName(err), self.dc });
            self.requestReconnect(io, .refresh_temp_key);
            return;
        };

        const message_bytes = buf[8 + 16 + 8 + 8 ..];

        const message = tl.ProtoMessage.deserializeNoCopy(message_bytes);

        ok: {
            if (!(message.msg_id % 4 == 1 or message.msg_id % 4 == 3)) {
                log.err("security error: message is not odd - dc: {any}", .{self.dc});
                self.requestReconnect(io, .reconnect_only);

                return;
            }

            if (self.stored_msg_ids.contains(message.msg_id)) {
                log.err("security error: duplicated message - dc: {any}", .{self.dc});
                self.requestReconnect(io, .reconnect_only);

                return;
            }

            // when the session is initialized for the first time, the internal time might be wrong, so we skip these checks until we are sure about it
            if (!self.init_ok) {
                break :ok;
            }

            const server_time = message.msg_id >> 32;
            const now = self.message_id.getUnix(io);

            // Security check: msg_ids over 30 seconds in the future or over 300 seconds in the past must be rejected
            if (server_time > now +% 30 or server_time < now -% 300) {
                log.err("security error: message too old or too new - dc: {any}", .{self.dc});
                self.requestReconnect(io, .reconnect_only);

                return;
            }
        }

        self.stored_msg_ids.push(message.msg_id);

        log.debug("Incoming message, type {any} - {f}", .{ tl.TL.identify(std.mem.readInt(u32, @ptrCast(message.body[0..4]), .little)), self.dc });

        self.processMessage(io, allocator, message) catch {

            // TODO: handle error correctly
            continue;
        };
    }
}

const RETRY_IN = std.Io.Duration.fromMilliseconds(500);
const timeout: std.Io.Timeout = .{ .duration = .{ .raw = RETRY_IN, .clock = .boot } };

fn prepareNewTempAuthKey(self: *Session, allocator: std.mem.Allocator, io: std.Io, gen_key: *?AuthKey.GeneratedAuthKey, shutdown: bool) std.Io.Cancelable!void {
    if (!shutdown) {
        gen_key.* = null;
        gen_key.* = key: {
            while (true) {
                const transport = (self.client_manager.transport_connector.connectTo(allocator, io, self.dc) catch |err| {
                    if (err == std.Io.Cancelable.Canceled) {
                        return std.Io.Cancelable.Canceled;
                    }
                    log.warn("failed to generate temp auth key, retrying in {d}ms - {f}", .{ RETRY_IN.toMilliseconds(), self.dc });
                    try timeout.sleep(io);
                    continue;
                }).?;
                defer transport.deinit(io);

                const generated_key = AuthKey.generate(allocator, io, transport.transport, @intCast(self.dc.id), self.dc.media, self.dc.testmode, true, &self.message_id) catch |err| {
                    if (err == std.Io.Cancelable.Canceled) {
                        return std.Io.Cancelable.Canceled;
                    }
                    log.warn("failed to generate temp auth key, retrying in {d}ms - {f}", .{ RETRY_IN.toMilliseconds(), self.dc });
                    try timeout.sleep(io);
                    continue;
                };

                break :key generated_key;
            }
        };
    }

    self.shutdown_event.reset();

    if (self.pending_requests.load(.acquire) == 0) {
        self.shutdown_event.set(io);
    }

    try self.shutdown_event.wait(io);

    self.conn_restart.set(io);
}

fn setTempKey(self: *Session, allocator: std.mem.Allocator, io: std.Io, gen_key: AuthKey.GeneratedAuthKey) !void {
    //const transport = (try self.transport_connector.connectTo(allocator, io, self.dc)).?;
    //defer transport.deinit(io);

    // The authorization key id is the 64 lower-bits of the SHA1 hash of the
    // authorization key
    var auth_key_id: [20]u8 = undefined;
    std.crypto.hash.Sha1.hash(&gen_key.auth_key, &auth_key_id, .{});

    {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);
        self.connection_bound_auth_key = false;
        @memcpy(&self.auth_key_id, auth_key_id[12..20]);
        self.auth_key = gen_key;
        if (self.salts.items.len > 0) {
            self.salts.shrinkAndFree(allocator, 1);
            self.salts.items[0] = tl.ProtoFutureSalt{ .salt = gen_key.first_salt, .valid_since = 0, .valid_until = 0 };
        } else {
            try self.salts.append(allocator, tl.ProtoFutureSalt{ .salt = gen_key.first_salt, .valid_since = 0, .valid_until = 0 });
        }
    }
}

fn connectWithRetry(self: *Session, allocator: std.mem.Allocator, io: std.Io, reconnect_reason: ReconnectReason) std.Io.Cancelable!TransportConnector.TransportHolder {
    if (reconnect_reason == .refresh_temp_key) {
        log.debug("generating temp auth key - {f}", .{self.dc});
        while (true) {
            const transport = (self.client_manager.transport_connector.connectTo(allocator, io, self.dc) catch |err| {
                if (err == std.Io.Cancelable.Canceled) {
                    return std.Io.Cancelable.Canceled;
                }
                log.warn("failed to generate temp auth key, retrying in {d}ms - {f}", .{ RETRY_IN.toMilliseconds(), self.dc });
                try timeout.sleep(io);
                continue;
            }).?;
            defer transport.deinit(io);

            const gen_key = AuthKey.generate(allocator, io, transport.transport, @intCast(self.dc.id), self.dc.media, self.dc.testmode, true, &self.message_id) catch |err| {
                if (err == std.Io.Cancelable.Canceled) {
                    return std.Io.Cancelable.Canceled;
                }
                log.warn("failed to generate temp auth key, retrying in {d}ms - {f}", .{ RETRY_IN.toMilliseconds(), self.dc });
                try timeout.sleep(io);
                continue;
            };

            self.setTempKey(allocator, io, gen_key) catch |err| {
                if (err == std.Io.Cancelable.Canceled) {
                    return std.Io.Cancelable.Canceled;
                }
                log.warn("failed to generate temp auth key, retrying in {d}ms - {f}", .{ RETRY_IN.toMilliseconds(), self.dc });
                try timeout.sleep(io);
                continue;
            };
            break;
        }
    }

    while (true) {
        log.debug("connecting to datacenter {f}", .{self.dc});
        const transport = self.client_manager.transport_connector.connectTo(allocator, io, self.dc) catch {
            log.err("unable to connect - {f}", .{self.dc});
            try timeout.sleep(io);
            continue;
        };
        return transport.?;
    }

    log.debug("connectWithRetry end", .{});
}

fn initConnection(self: *Session, allocator: std.mem.Allocator, io: std.Io) std.Io.Cancelable!void {
    {
        var nonce: u64 = undefined;
        std.Io.randomSecure(io, @ptrCast(&nonce)) catch |err| {
            if (err == std.Io.Cancelable.Canceled) {
                return;
            }
            self.requestReconnect(io, .reconnect_only);
            return std.Io.Cancelable.Canceled;
        };
        const msg_id = self.message_id.get(io);
        const expires_at = self.message_id.getUnix(io) + AuthKey.TEMP_KEYS_EXPIRE_IN_S;

        const perm_key_id_u64 = std.mem.readInt(u64, &self.perm_auth_key_id, .little);
        const temp_key_id_u64 = std.mem.readInt(u64, &self.auth_key_id, .little);

        const message_to_encrypt = tl.IProtoBindAuthKeyInner{ .ProtoBindAuthKeyInner = &tl.ProtoBindAuthKeyInner{ .expires_at = @intCast(expires_at), .nonce = nonce, .perm_auth_key_id = perm_key_id_u64, .temp_auth_key_id = temp_key_id_u64, .temp_session_id = self.session_id } };
        const fake = comptime tl.IProtoBindAuthKeyInner{ .ProtoBindAuthKeyInner = &tl.ProtoBindAuthKeyInner{ .expires_at = 0, .nonce = 0, .perm_auth_key_id = 0, .temp_auth_key_id = 0, .temp_session_id = 0 } };
        const message_size = comptime fake.serializeSize();

        var encrypted_message: [MT1Crypto.Layout.totalLen(message_size)]u8 = undefined;
        _ = message_to_encrypt.serialize(encrypted_message[MT1Crypto.Layout.BODY..MT1Crypto.Layout.paddingOffset(message_size)]);

        var bind_salt: u64 = undefined;
        var bind_session_id: u64 = undefined;
        std.Io.randomSecure(io, std.mem.asBytes(&bind_salt)) catch |err| {
            if (err == std.Io.Cancelable.Canceled) {
                return;
            }
            self.requestReconnect(io, .reconnect_only);
            return std.Io.Cancelable.Canceled;
        };
        std.Io.randomSecure(io, std.mem.asBytes(&bind_session_id)) catch |err| {
            if (err == std.Io.Cancelable.Canceled) {
                return;
            }
            self.requestReconnect(io, .reconnect_only);
            return std.Io.Cancelable.Canceled;
        };

        MT1Crypto.encrypt(
            io,
            &encrypted_message,
            &self.perm_auth_key_id,
            self.perm_auth_key,
            bind_salt,
            bind_session_id,
            msg_id,
            0,
            message_size,
        ) catch |err| {
            if (err == std.Io.Cancelable.Canceled) {
                return;
            }
            self.requestReconnect(io, .reconnect_only);
            return std.Io.Cancelable.Canceled;
        };
        const init_data = blk: {
            try self.client_manager.session_info.lock.lockShared(io);
            defer self.client_manager.session_info.lock.unlockShared(io);
            const message = tl.TL{
                .InvokeWithLayer = &.{
                    .layer = tl.LAYER_VERSION,
                    .query = tl.TL{
                        .InitConnection = &.{
                            .api_id = self.client_manager.session_info.api_id,
                            .device_model = self.client_manager.session_info.device_model,
                            .system_version = self.client_manager.session_info.system_version,
                            .app_version = self.client_manager.session_info.app_version,
                            .system_lang_code = self.client_manager.session_info.system_lang_code,
                            .lang_pack = self.client_manager.session_info.lang_pack,
                            .lang_code = self.client_manager.session_info.lang_code,
                            .query = .{
                                .AuthBindTempAuthKey = &.{
                                    .perm_auth_key_id = perm_key_id_u64,
                                    .nonce = nonce,
                                    .expires_at = @intCast(expires_at),
                                    .encrypted_message = &encrypted_message,
                                },
                            },
                        },
                    },
                },
            };

            break :blk (self.send(io, allocator, message, msg_id, true) catch |err| {
                if (err == std.Io.Cancelable.Canceled) {
                    return;
                }
                self.requestReconnect(io, .reconnect_only);
                return std.Io.Cancelable.Canceled;
            });
        };
        defer init_data.deinit(allocator);

        if (init_data.data == .ProtoRpcError) {
            const err = init_data.data.ProtoRpcError.error_message;

            log.err("Unable to bind temporary auth key to permanent auth key: {s} - {f}", .{ err, self.dc });
            self.requestReconnect(io, .reconnect_only);
            return std.Io.Cancelable.Canceled;
        }
    }

    {
        // initConnection must also be called after each auth.bindTempAuthKey.
        const init_data = blk: {
            try self.client_manager.session_info.lock.lockShared(io);
            defer self.client_manager.session_info.lock.unlockShared(io);

            break :blk (self.send(io, allocator, tl.TL{
                .InvokeWithLayer = &.{
                    .layer = tl.LAYER_VERSION,
                    .query = tl.TL{
                        .InitConnection = &.{
                            .api_id = self.client_manager.session_info.api_id,
                            .device_model = self.client_manager.session_info.device_model,
                            .system_version = self.client_manager.session_info.system_version,
                            .app_version = self.client_manager.session_info.app_version,
                            .system_lang_code = self.client_manager.session_info.system_lang_code,
                            .lang_pack = self.client_manager.session_info.lang_pack,
                            .lang_code = self.client_manager.session_info.lang_code,
                            .query = .{ .HelpGetConfig = &.{} },
                        },
                    },
                },
            }, null, true) catch |err| {
                if (err == std.Io.Cancelable.Canceled) {
                    return;
                }
                self.requestReconnect(io, .reconnect_only);
                return std.Io.Cancelable.Canceled;
            });
        };

        defer init_data.deinit(allocator);

        if (init_data.data == .ProtoRpcError) {
            const err = init_data.data.ProtoRpcError.error_message;
            log.err("Unable to initConnection: {s} - {f}", .{ err, self.dc });
            self.requestReconnect(io, .reconnect_only);
            return std.Io.Cancelable.Canceled;
        }
        if (init_data.data == .Config) {
            self.client_manager.importConfig(allocator, io, init_data.data.Config) catch |err| {
                log.warn("{f} failed to import tl.Config: {}", .{ self.dc, err });
            };
        }
        // TODO: use the config to load things like available datacenters
    }
    {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);
        self.auth_key_bound_event.set(io);
        self.connection_bound_auth_key = true;
        self.init_ok = true;
    }

    // the prebindWriterWorker will get stuck waiting for an item on the queue, so we push an empty request to make it exit the loop
    _ = self.bootstrap_queue.putOne(io, .{ .id = null, .data = @constCast(&.{}), .content_related = false }) catch |err| {
        if (err == std.Io.Cancelable.Canceled) {
            return std.Io.Cancelable.Canceled;
        }
    };
}

/// Extracts the base message state from a state byte containing additional status flags.
fn messageStateCode(info: u8) u3 {
    return @truncate(info);
}

fn pushStateInfo(self: *Session, allocator: std.mem.Allocator, io: std.Io, id_messages: []const u64, data: []const u8) std.Io.Cancelable!void {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    if (id_messages.len != data.len) {
        return;
    }

    for (data, 0..) |info, i| {
        if (self.pending_answers_idmap.get(id_messages[i])) |id| {
            if (self.pending_answers.map.get(id)) |answer| {
                switch (messageStateCode(info)) {
                    // 1 = nothing is known about the message (msg\_id too low,
                    // the other party may have forgotten it)
                    //
                    // 2 = message not received (msg\_id falls within the range of stored identifiers;
                    // however, the other party has certainly not received a message like that)
                    //
                    // 3 = message not received (msg\_id too high; however,
                    // the other party has certainly not received it yet)
                    1, 2, 3 => {
                        answer.data = SendError.Resend;
                        if (answer.proto_container_id) |container_id| {
                            self.removeMessageFromContainer(allocator, container_id, id);
                        }

                        answer.event.set(io);
                    },
                    // 4 = message received (note that this response is also at the
                    // same time a receipt acknowledgment)
                    //   +8 = message already acknowledged
                    //   +16 = message not requiring acknowledgment
                    //   +32 = RPC query contained in message being processed or processing already complete
                    //   +64 = content-related response to message already generated
                    //   +128 = other party knows for a fact that message is already received
                    4 => {
                        answer.status = .ack;
                        answer.last_probed_at = .now(io, .boot);
                    },
                    else => {},
                }
            }
        }
    }
}

fn reqMessageState(self: *Session, allocator: std.mem.Allocator, io: std.Io, comptime reconnect: bool) !void {
    try self.auth_key_bound_event.wait(io);
    // sleep a bit, telegram might send something back automatically
    const DURATION = std.Io.Duration.fromMilliseconds(900);
    const sleep: std.Io.Timeout = .{ .duration = .{ .raw = DURATION, .clock = .boot } };

    try sleep.sleep(io);
    //self.sendNoWait(io, allocator, tl.TL{.ProtoMsgsStateReq =  tl.ProtoMsgsStateReq{.msg_ids = }}, null, false);
    var msg_ids = blk: {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);

        var msg_ids = try std.ArrayList(u64).initCapacity(allocator, self.pending_answers.map.count());
        errdefer msg_ids.deinit(allocator);

        var it = self.pending_answers.map.iterator();
        while (it.next()) |p| {
            // TODO: we might not really really need to request the state of every single unanswered message

            if (reconnect) {
                if (p.value_ptr.*.status != .answered) {
                    if (p.value_ptr.*.proto_req_id) |proto_req_id| {
                        try msg_ids.append(allocator, proto_req_id);
                    }
                }
            } else {
                if (p.value_ptr.*.status == .sent and !(p.value_ptr.*.last_probed_at.addDuration(.fromSeconds(10)).withClock(.boot).compare(.gt, std.Io.Clock.now(.boot, io).withClock(.boot)))) {
                    if (p.value_ptr.*.proto_req_id) |proto_req_id| {
                        try msg_ids.append(allocator, proto_req_id);
                    }
                }
            }
        }

        break :blk msg_ids;
    };
    defer msg_ids.deinit(allocator);

    if (msg_ids.items.len > 0) {
        const msg = try self.send(io, allocator, tl.TL{ .ProtoMsgsStateReq = &tl.ProtoMsgsStateReq{ .msg_ids = msg_ids.items } }, null, false);
        defer msg.deinit(allocator);

        switch (msg.data) {
            .ProtoMsgsStateInfo => |state_info| {
                return self.pushStateInfo(allocator, io, msg_ids.items, state_info.info);
            },
            else => {},
        }
    }
}

fn checkMessagesStatus(self: *Session, allocator: std.mem.Allocator, io: std.Io) std.Io.Cancelable!void {
    while (true) {
        self.reqMessageState(allocator, io, true) catch |err| {
            if (err == std.Io.Cancelable.Canceled) {
                return std.Io.Cancelable.Canceled;
            }
            log.err("Failed to request state of messages: {any}, retrying - {f}", .{ err, self.dc });
            try timeout.sleep(io);
            continue;
        };
        return;
    }
}

fn sessionSupervisorRun(self: *Session, allocator: std.mem.Allocator, io: std.Io, reason: *ReconnectReason, holder: TransportConnector.TransportHolder) std.Io.Cancelable!void {
    reason.* = .none;

    var group: std.Io.Group = .init;

    group.concurrent(io, Session.readerWorker, .{ self, io, allocator, holder.transport }) catch {
        @panic("concurrency unavailable");
    };

    if (!self.connection_bound_auth_key) {
        self.auth_key_bound_event.reset();
        group.concurrent(io, Session.prebindWriterWorker, .{ self, io, allocator, holder.transport }) catch {
            @panic("concurrency unavailable");
        };
        group.concurrent(io, Session.initConnection, .{ self, allocator, io }) catch {
            @panic("concurrency unavailable");
        };
    } else {
        group.concurrent(io, Session.writerWorker, .{ self, io, allocator, holder.transport }) catch {
            @panic("concurrency unavailable");
        };
    }
    group.concurrent(io, Session.checkMessagesStatus, .{ self, allocator, io }) catch {
        @panic("concurrency unavailable");
    };

    group.concurrent(io, Session.pingWorker, .{ self, io, allocator }) catch {
        @panic("concurrency unavailable");
    };

    self.conn_restart.wait(io) catch {
        group.cancel(io);
        return;
    };

    group.cancel(io);

    reason.* = self.reconnect_reason;
    self.reconnect_reason = .none;
    self.conn_restart.reset();

    const shutdown = self.shutdown.load(.acquire);
    if ((shutdown or self.wait_and_recreate_auth_key) and reason.* != .refresh_temp_key) {

        // when a new auth key is generated, the session is usually cleared.
        // to make the switch seamless, we process the remaining pending requests, and only then we switch to the new auth key
        var auth_key: ?AuthKey.GeneratedAuthKey = null;

        group = .init;

        group.concurrent(io, Session.readerWorker, .{ self, io, allocator, holder.transport }) catch {
            @panic("concurrency unavailable");
        };
        group.concurrent(io, Session.writerWorker, .{ self, io, allocator, holder.transport }) catch {
            @panic("concurrency unavailable");
        };
        group.concurrent(io, Session.prepareNewTempAuthKey, .{ self, allocator, io, &auth_key, shutdown }) catch {
            @panic("concurrency unavailable");
        };

        self.conn_restart.wait(io) catch |err| {
            group.cancel(io);
            return err;
        };

        const sub_reason = reason: {
            self.mutex.lockUncancelable(io);
            defer self.mutex.unlock(io);
            break :reason self.reconnect_reason;
        };

        group.cancel(io);
        self.conn_restart.reset();
        self.reconnect_reason = .none;

        self.wait_and_recreate_auth_key = false;

        if (!shutdown and sub_reason == .none) {
            if (auth_key) |gen_key| {
                self.setTempKey(allocator, io, gen_key) catch |err| {
                    if (err == std.Io.Cancelable.Canceled) {
                        return std.Io.Cancelable.Canceled;
                    }
                    return;
                };
                self.reconnect_reason = .none;
            }
        }
    }
}

pub fn sessionSupervisor(self: *Session, allocator: std.mem.Allocator, io: std.Io) std.Io.Cancelable!void {
    var reason: ReconnectReason = self.reconnect_reason;
    self.reconnect_reason = .none;
    log.info("Starting supervisor - {f}", .{self.dc});
    while (!self.shutdown.load(.acquire)) {
        {
            try self.mutex.lock(io);
            defer self.mutex.unlock(io);
            self.init_ok = false;
        }
        self.freeze_event.set(io);
        self.freeze_requests.store(false, .release);
        self.freeze_event.reset();
        log.info("calling connectWithRetry", .{});
        {
            const holder = try self.connectWithRetry(allocator, io, reason);
            defer holder.deinit(io);
            try self.sessionSupervisorRun(allocator, io, &reason, holder);
        }
    }
}

/// Decrypts an encrypted message in-place.
fn decryptMessage(self: *Session, io: std.Io, data: []u8) !void {
    const header = try MT2Crypto.decrypt(data, &self.auth_key_id, &self.auth_key.auth_key, .server_to_client);

    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    if (header.session_id != self.session_id) {
        return SecurityError.SessionIdMismatch;
    }

    self.ping_disconnect = false;
}

inline fn payloadLen(requests: []const Request, requests_extra: []const Request, pending_acks: []const u64) struct { usize, usize, bool } {
    // if we have more than one request, or we have pending acks to send, we'll use a message container
    const use_container = if (requests.len > 1 or requests_extra.len > 0 or pending_acks.len > 0) true else false;

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

    for (requests_extra) |req| {
        if (use_container) {
            data_size += 8 // msg_id
                + 4 // seq_no
                + 4; // bytes
        }
        data_size += req.data.len;
    }

    return .{ MT2Crypto.Layout.totalLen(data_size), data_size, use_container };
}

inline fn payloadCreate(self: *Session, io: std.Io, data_size: usize, requests: []const Request, requests_extra: []const Request, pending_acks: []const u64, inner_msg_ids: []?u64, out: []u8) void {
    const offset_data = MT2Crypto.Layout.BODY;
    const offset_padding = MT2Crypto.Layout.paddingOffset(data_size);
    const Container = MessageContainerLayout;

    const writeContainerMessage = struct {
        fn run(dest: []u8, container_body_offset: usize, cursor: usize, msg_id: u64, seqno: u32, body: []const u8) usize {
            const start = Container.messageOffset(container_body_offset, cursor);
            const end = Container.messageEnd(container_body_offset, cursor, body.len);

            std.mem.writeInt(u64, @ptrCast(dest[start + Container.MESSAGE_ID .. start + Container.SEQNO]), msg_id, .little);
            std.mem.writeInt(u32, @ptrCast(dest[start + Container.SEQNO .. start + Container.BODY_LEN]), seqno, .little);
            std.mem.writeInt(u32, @ptrCast(dest[start + Container.BODY_LEN .. start + Container.BODY]), @intCast(body.len), .little);
            @memcpy(dest[start + Container.BODY .. end], body);

            return end - (container_body_offset + Container.MESSAGES);
        }
    }.run;

    const use_container = if (requests.len > 1 or requests_extra.len > 0 or pending_acks.len > 0) true else false;

    if (use_container) {
        std.mem.writeInt(u32, out[offset_data + Container.CONSTRUCTOR .. offset_data + Container.COUNT], 0x73f1f8dc, .little);
        std.mem.writeInt(u32, out[offset_data + Container.COUNT .. offset_data + Container.MESSAGES], @intCast(requests.len + requests_extra.len + (if (pending_acks.len > 0) @as(u32, 1) else 0)), .little);

        var b: usize = 0;

        if (pending_acks.len > 0) {
            const msg_id = self.message_id.get(io);
            const start = Container.messageOffset(offset_data, b);
            const body_start = start + Container.BODY;
            const data_wr = (tl.IProtoMsgsAck{ .ProtoMsgsAck = &.{ .msg_ids = pending_acks } }).serialize(out[body_start..]);

            b = writeContainerMessage(out, offset_data, b, msg_id, self.nextSeqNo(false), out[body_start..][0..data_wr]);
        }

        var i: usize = 0;

        for (requests_extra) |req| {
            const msg_id = if (req.message_id) |msg_id| msg_id else self.message_id.get(io);
            if (req.id) |id| {
                self.pending_answers_idmap.putAssumeCapacity(msg_id, id);
                inner_msg_ids[i] = msg_id;
                if (self.pending_answers.map.getPtr(id)) |pending_answer| {
                    pending_answer.*.proto_req_id = msg_id;
                }
                i += 1;
            }

            b = writeContainerMessage(out, offset_data, b, msg_id, self.nextSeqNo(req.content_related), req.data);
        }

        for (requests) |req| {
            const msg_id = if (req.message_id) |msg_id| msg_id else self.message_id.get(io);
            if (req.id) |id| {
                self.pending_answers_idmap.putAssumeCapacity(msg_id, id);
                inner_msg_ids[i] = msg_id;
                if (self.pending_answers.map.getPtr(id)) |pending_answer| {
                    pending_answer.*.proto_req_id = msg_id;
                }
                i += 1;
            }

            b = writeContainerMessage(out, offset_data, b, msg_id, self.nextSeqNo(req.content_related), req.data);
        }

        return;
    }

    @memcpy(out[offset_data..offset_padding], requests[0].data);
}

fn pingWorker(self: *Session, io: std.Io, allocator: std.mem.Allocator) std.Io.Cancelable!void {
    while (true) {
        const PING_TIMEOUT: std.Io.Timeout = .{ .duration = .{ .raw = .fromSeconds(PING_WRITE_INTERVAL_SECS), .clock = .boot } };

        try PING_TIMEOUT.sleep(io);

        if (std.Io.Clock.now(.boot, io).addDuration(.fromSeconds(AuthKey.TEMP_KEYS_ADVANCE_S)).withClock(.boot).compare(.gt, self.auth_key.expiration.?)) {
            log.debug("temp auth key is about to expire, starting to generate a new one - {f}", .{self.dc});
            {
                try self.mutex.lock(io);
                defer self.mutex.unlock(io);

                if (self.shutdown.load(.acquire)) {
                    return;
                }

                self.freeze_event.reset();
                self.freeze_requests.store(true, .release);
                self.wait_and_recreate_auth_key = true;
                self.conn_restart.set(io);
            }
            return;
        }

        self.maybeRequestFutureSalts(io, allocator);

        const ping_id = brk: {
            try self.mutex.lock(io);

            if (self.ping_disconnect) {
                log.debug("no pong received for more than {d} seconds, disconnecting - {f}", .{ PING_WRITE_INTERVAL_SECS * 2, self.dc });
                self.ping_disconnect = false;
                self.mutex.unlock(io);
                self.requestReconnect(io, .reconnect_only);
                return;
            }
            defer self.mutex.unlock(io);

            self.ping_value = self.ping_value +% 1;
            self.ping_disconnect = true;

            break :brk self.ping_value;
        };

        log.debug("sending PingDelayDisconnect, id: {d} - {f}", .{ ping_id, self.dc });

        self.sendNoWait(io, allocator, tl.TL{ .ProtoPingDelayDisconnect = &.{ .ping_id = ping_id, .disconnect_delay = PING_WRITE_INTERVAL_SECS * 2 } }, null, false) catch |err| {
            if (err == std.Io.Cancelable.Canceled) {
                return std.Io.Cancelable.Canceled;
            }
            // TODO: what to do?
            return;
        };

        self.reqMessageState(allocator, io, false) catch {};
    }
}

fn payload(self: *Session, allocator: std.mem.Allocator, io: std.Io, batch: []Request, comptime prebind: bool) !struct { []u8, []?u64, ?u64 } {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    const pending_acks = self.pending_ack.items;
    self.pending_ack_inflight = pending_acks.len;
    errdefer self.pending_ack_inflight = 0;

    const offset_end, const data_size, const use_container = payloadLen(batch, if (prebind) &.{} else self.retry_backlog.items, if (prebind) &.{} else pending_acks);

    //const messages_to_send = if (prebind) batch.len else batch.len + self.retry_backlog.items.len;

    const messages_to_send_traced = messages: {
        var i: usize = 0;
        for (batch) |req| {
            if (req.id != null) {
                i += 1;
            }
        }

        if (!prebind) {
            for (self.retry_backlog.items) |req| {
                if (req.id != null) {
                    i += 1;
                }
            }
        }

        break :messages i;
    };

    var container_id_list = list: {
        if (!use_container) {
            break :list std.ArrayListUnmanaged(u32).empty;
        }

        break :list try std.ArrayListUnmanaged(u32).initCapacity(allocator, messages_to_send_traced);
    };
    errdefer container_id_list.deinit(allocator);

    if (use_container) {
        try self.pending_containers.ensureUnusedCapacity(allocator, 1);
    }

    const inner_msg_ids = try allocator.alloc(?u64, messages_to_send_traced);
    errdefer allocator.free(inner_msg_ids);
    @memset(inner_msg_ids, null);

    const buf = try allocator.alloc(u8, offset_end);
    errdefer allocator.free(buf);

    try self.pending_answers_idmap.ensureUnusedCapacity(allocator, messages_to_send_traced);

    self.payloadCreate(io, data_size, batch, if (prebind) &.{} else self.retry_backlog.items, if (prebind) &.{} else pending_acks, inner_msg_ids, buf);

    const seqno = self.nextSeqNo(if (use_container) false else batch[0].content_related);

    const msgid = blk: {
        if (use_container) {
            break :blk self.message_id.get(io);
        }

        if (batch[0].message_id) |msg_id|
            break :blk msg_id;

        break :blk self.message_id.get(io);
    };
    if (!use_container) {
        if (batch[0].id) |id| {
            try self.pending_answers_idmap.put(allocator, msgid, id);
            if (self.pending_answers.map.getPtr(id)) |pending_answer| {
                pending_answer.*.proto_req_id = msgid;
            }
            inner_msg_ids[0] = msgid;
        }
    }

    errdefer {
        for (inner_msg_ids) |maybe_msgid| {
            if (maybe_msgid) |inner_msgid| {
                _ = self.pending_answers_idmap.swapRemove(inner_msgid);
            }
        }
    }

    try self.encryptMessage(io, buf, seqno, msgid, data_size, false);

    if (use_container) {
        for (batch) |req| {
            if (req.id) |id| {
                if (self.pending_answers.map.get(id)) |answer| {
                    answer.proto_container_id = msgid;
                }
                container_id_list.appendAssumeCapacity(id);
            }
        }
        if (!prebind) {
            for (self.retry_backlog.items) |req| {
                if (req.id) |id| {
                    if (self.pending_answers.map.get(id)) |answer| {
                        answer.proto_container_id = msgid;
                    }
                    container_id_list.appendAssumeCapacity(id);
                }
            }
        }
        self.pending_containers.putAssumeCapacity(msgid, container_id_list);
    }

    return .{ buf, inner_msg_ids, if (!use_container) null else msgid };
}

inline fn processBatch(self: *Session, allocator: std.mem.Allocator, io: std.Io, transport: *Transport, batch: []Request) !void {
    var ok = false;

    defer {
        if (!ok) {
            log.err("failed to send messages, requeuing - {f}", .{self.dc});
            self.retry_backlog.appendSliceAssumeCapacity(batch);
        } else {
            for (batch) |req| {
                allocator.free(req.data);
            }

            self.mutex.lockUncancelable(io);
            for (self.retry_backlog.items) |req| {
                allocator.free(req.data);
            }
            self.retry_backlog.shrinkRetainingCapacity(0);
            self.mutex.unlock(io);
        }
    }

    //  errdefer {
    //    self.mutex.lockUncancelable(io);
    //      for (batch[0..batch_size]) |req| {
    //         if (req.id) |id| {
    //             if (self.pending_answers.map.getPtr(id)) |pending_req| {
    //                pending_req.*.event.set(io);
    //            }
    //         }
    //     }
    //   self.mutex.unlock(io);
    //  }

    const buf, const inner_msg_ids, const container_msg_id = try self.payload(allocator, io, batch, false);

    errdefer {
        self.mutex.lockUncancelable(io);
        self.pending_ack_inflight = 0;
        self.mutex.unlock(io);
    }

    defer allocator.free(inner_msg_ids);
    defer allocator.free(buf);

    errdefer {
        if (!ok) {
            self.mutex.lockUncancelable(io);
            for (inner_msg_ids) |maybe_msgid| {
                if (maybe_msgid) |msgid| {
                    _ = self.pending_answers_idmap.swapRemove(msgid);
                }
            }
            if (container_msg_id) |c_msg_id| {
                if (self.pending_containers.fetchSwapRemove(c_msg_id)) |msg_ids| {
                    var msg_ids_list = msg_ids.value;
                    msg_ids_list.deinit(allocator);
                }
            }

            self.mutex.unlock(io);
        }
    }

    transport.write(io, buf) catch {
        std.Io.checkCancel(io) catch {
            return;
        };
        self.requestReconnect(io, .reconnect_only);
        // We set ok to true because data might still have been written. once the connection is established again, we'll check for them
        ok = true;
        return std.Io.Cancelable.Canceled;
    };

    ok = true;

    self.mutex.lockUncancelable(io);

    for (inner_msg_ids) |maybe_msgid| {
        if (maybe_msgid) |msgid| {
            if (self.pending_answers_idmap.get(msgid)) |mapped_id| {
                if (self.pending_answers.map.get(mapped_id)) |pending_answer| {
                    pending_answer.status = .sent;
                }
            }
        }
    }

    const remaining_len = self.pending_ack.items.len - self.pending_ack_inflight;
    std.mem.copyForwards(u64, self.pending_ack.items[0..remaining_len], self.pending_ack.items[self.pending_ack_inflight..]);
    self.pending_ack.items.len = remaining_len;

    self.pending_ack_inflight = 0;
    self.mutex.unlock(io);
}

inline fn prebindProcessBatch(self: *Session, allocator: std.mem.Allocator, io: std.Io, transport: *Transport, batch: []Request) !void {
    defer {
        for (batch) |req| {
            allocator.free(req.data);
        }
    }

    //  errdefer {
    //    self.mutex.lockUncancelable(io);
    //      for (batch[0..batch_size]) |req| {
    //         if (req.id) |id| {
    //             if (self.pending_answers.map.getPtr(id)) |pending_req| {
    //                pending_req.*.event.set(io);
    //            }
    //         }
    //     }
    //   self.mutex.unlock(io);
    //  }

    const buf, const inner_msg_ids, const container_msg_id = try self.payload(allocator, io, batch, true);

    defer allocator.free(inner_msg_ids);
    defer allocator.free(buf);

    errdefer {
        self.mutex.lockUncancelable(io);
        for (inner_msg_ids) |maybe_msgid| {
            if (maybe_msgid) |msgid| {
                _ = self.pending_answers_idmap.swapRemove(msgid);
            }
        }

        if (container_msg_id) |c_msg_id| {
            if (self.pending_containers.fetchSwapRemove(c_msg_id)) |msg_ids| {
                var msg_ids_list = msg_ids.value;
                msg_ids_list.deinit(allocator);
            }
        }
        self.mutex.unlock(io);
    }

    try transport.write(io, buf);
}

fn prebindWriterWorker(self: *Session, io: std.Io, allocator: std.mem.Allocator, transport: *Transport) std.Io.Cancelable!void {
    {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);
        self.requesting_salts = false;
    }

    while (true) {
        const bound = blk: {
            try self.mutex.lock(io);
            defer self.mutex.unlock(io);
            break :blk self.connection_bound_auth_key;
        };
        var batch: [MAX_WORKER_BATCH]Request = undefined;

        var batch_size = self.bootstrap_queue.get(io, &batch, if (bound) 0 else 1) catch |err| {
            if (err == std.Io.Cancelable.Canceled) {
                return std.Io.Cancelable.Canceled;
            }
            if (err == std.Io.QueueClosedError.Closed) {
                break;
            }
            return;
        };
        // item with data.len = 0 coming from the initConnection helper
        if (batch_size == 0 or (batch_size == 1 and batch[0].data.len == 0)) {
            if (bound) break;
            continue;
        }

        if (bound) {
            for (0..batch_size) |item| {
                if (batch[item].data.len == 0) {
                    batch_size = item;
                    break;
                }
            }
        }

        log.debug("Processing {d} pre-bind outbound messages - {f}", .{ batch_size, self.dc });

        self.prebindProcessBatch(allocator, io, transport, batch[0..batch_size]) catch |err| {
            if (err == std.Io.Cancelable.Canceled) {
                return;
            }
            self.requestReconnect(io, .reconnect_only);
            return std.Io.Cancelable.Canceled;
        };
    }

    return self.writerWorker(io, allocator, transport);
}

fn writerWorker(self: *Session, io: std.Io, allocator: std.mem.Allocator, transport: *Transport) std.Io.Cancelable!void {
    {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);
        self.requesting_salts = false;
    }

    var batch: [MAX_WORKER_BATCH]Request = undefined;

    while (true) {
        self.retry_backlog.ensureUnusedCapacity(allocator, MAX_WORKER_BATCH) catch {
            continue;
        };
        const batch_size = self.requests_queue.get(io, &batch, if (self.retry_backlog.items.len > 0) 0 else 1) catch |err| {
            if (err == std.Io.Cancelable.Canceled) {
                return std.Io.Cancelable.Canceled;
            }
            if (err == std.Io.QueueClosedError.Closed) {
                // TODO: what to do?
                return;
            }
            return;
        };

        log.debug("Processing {d} outbound messages - {f}", .{ batch_size, self.dc });
        self.processBatch(allocator, io, transport, batch[0..batch_size]) catch |err| {
            if (err == std.Io.Cancelable.Canceled) {
                return;
            }
            continue;
        };
    }
}

/// Enqueues a new TL function into the reader worker queue, without waiting for it to be acknowledged
pub fn sendNoWait(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.TL, msg_id: ?u64, prebind: bool) !void {
    if (self.shutdown.load(.acquire)) {
        return SendError.Shutdown;
    }

    if (self.freeze_requests.load(.acquire)) {
        try self.freeze_event.wait(io);
    }

    if (self.shutdown.load(.acquire)) {
        return SendError.Shutdown;
    }

    _ = self.pending_requests.fetchAdd(1, .seq_cst);
    defer {
        const sub = self.pending_requests.fetchSub(1, .seq_cst);
        if (sub == 1) {
            self.shutdown_event.set(io);
        }
    }

    log.debug("Sending (nowait) {any} - {f}", .{ message, self.dc });

    const len_serialized = message.serializeSize();

    const buf = try allocator.alloc(u8, len_serialized);
    errdefer allocator.free(buf);

    _ = message.serialize(buf);

    const bootstrap_queue = blk: {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);
        if (prebind and !self.connection_bound_auth_key) {
            break :blk true;
        }
        break :blk false;
    };
    if (bootstrap_queue) {
        try self.bootstrap_queue.putOne(io, .{ .id = null, .data = buf, .content_related = isContentRelated(message), .message_id = msg_id });
    } else {
        try self.requests_queue.putOne(io, .{ .id = null, .data = buf, .content_related = isContentRelated(message), .message_id = msg_id });
    }
}

/// Enqueues a new TL function into the reader worker queue, and waits for the result.
///
/// Cancellation is supported for this function, but only to cancel the waiter itself (If the request has already been added to the queue, it will be sent to Telegram anyway).
pub fn send(self: *Session, io: std.Io, allocator: std.mem.Allocator, message: tl.TL, msg_id: ?u64, prebind: bool) !utils.Deserialized {
    const deserializeResultSize = message.getDeserializeResultSize() orelse utils.panicDeserializeResultSize;
    const deserializeResult = message.getDeserializeResult() orelse utils.panicDeserializeResult;
    if (self.shutdown.load(.acquire)) {
        return SendError.Shutdown;
    }

    if (self.freeze_requests.load(.acquire)) {
        try self.freeze_event.wait(io);
    }

    if (self.shutdown.load(.acquire)) {
        return SendError.Shutdown;
    }

    _ = self.pending_requests.fetchAdd(1, .seq_cst);
    defer {
        const sub = self.pending_requests.fetchSub(1, .seq_cst);
        if (sub == 1) {
            self.shutdown_event.set(io);
        }
    }

    // If the session hasn't been initialized properly yet, we wrap the message with initConnection
    const message_to_send, const bootstrap_queue = blk: {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);
        if (prebind and !self.connection_bound_auth_key) {
            break :blk .{ message, true };
        }
        if (!self.init_ok) {
            try self.client_manager.session_info.lock.lockShared(io);
            self.client_manager.session_info.lock.unlockShared(io);

            break :blk .{ tl.TL{
                .InvokeWithLayer = &.{
                    .layer = tl.LAYER_VERSION,
                    .query = tl.TL{
                        .InitConnection = &.{
                            .api_id = self.client_manager.session_info.api_id,
                            .device_model = self.client_manager.session_info.device_model,
                            .system_version = self.client_manager.session_info.system_version,
                            .app_version = self.client_manager.session_info.app_version,
                            .system_lang_code = self.client_manager.session_info.system_lang_code,
                            .lang_pack = self.client_manager.session_info.lang_pack,
                            .lang_code = self.client_manager.session_info.lang_code,
                            .query = message,
                        },
                    },
                },
            }, false };
        }

        break :blk .{ message, false };
    };

    const len_serialized = message_to_send.serializeSize();

    const id = self.current_id.fetchAdd(1, .seq_cst);

    defer {
        self.mutex.lockUncancelable(io);

        if (self.pending_answers.map.fetchSwapRemove(id)) |kv| {
            if (kv.value.proto_container_id) |container_id| {
                self.removeMessageFromContainer(allocator, container_id, id);
            }
            if (kv.value.data) |data_er| {
                const data_maybe = data_er catch null;
                if (data_maybe) |data| {
                    data.deinit(allocator);
                }
            }
            allocator.destroy(kv.value);
        }
        self.mutex.unlock(io);
    }

    log.debug("Sending {any}, id: {d} - {f}", .{ message_to_send, id, self.dc });

    const answer = answ: {
        const buf = try allocator.alloc(u8, len_serialized);

        errdefer allocator.free(buf);

        _ = message_to_send.serialize(buf);

        const answer = brk: {
            try self.mutex.lock(io);
            defer self.mutex.unlock(io);

            const req = try self.pending_answers.create(allocator, id);

            req.last_probed_at = .now(io, .boot);

            req.deserializeResult = deserializeResult;
            req.deserializeResultSize = deserializeResultSize;

            break :brk req;
        };

        if (bootstrap_queue) {
            try self.bootstrap_queue.putOne(io, .{ .id = id, .data = buf, .content_related = isContentRelated(message_to_send), .message_id = msg_id });
        } else {
            try self.requests_queue.putOne(io, .{ .id = id, .data = buf, .content_related = isContentRelated(message_to_send), .message_id = msg_id });
        }

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
        // TODO: add a timeout, so we can send something like `msg_resend_req`/`msgs_state_req` if we don't get an answer after some time
        // TODO: add full cancellation support by sending `rpc_drop_answer`. probably won't be implemented soon
        try answer.event.wait(io);
    }

    const maybe_data = data: {
        try self.mutex.lock(io);
        defer self.mutex.unlock(io);

        const maybe_data = answer.data;
        answer.data = null;
        break :data maybe_data;
    };

    if (maybe_data) |data| {
        return data catch |err| {
            if (err == SendError.Resend) {
                log.debug("Need to resend message, id: {d} - {f}", .{ id, self.dc });
                return self.send(io, allocator, message, null, prebind);
            }
            return err;
        };
    } else {
        return SendError.Unknown;
    }
}

/// Encrypts raw bytes in-place into a message to be sent directly to Telegram's servers.
/// The mutex is assumed to be already acquired.
fn encryptMessage(self: *Session, io: std.Io, data: []u8, seqno: usize, message_id: u64, message_len: usize, comptime bind_key: bool) !void {
    var salt: u64 = undefined;
    var session_id: u64 = undefined;
    if (bind_key) {
        try std.Io.randomSecure(io, std.mem.asBytes(&salt));
        try std.Io.randomSecure(io, std.mem.asBytes(&session_id));
    } else {
        salt = self.getSalt(io).salt;
        session_id = self.session_id;
    }

    const auth_key_id = if (bind_key) self.perm_auth_key_id else self.auth_key_id;
    const auth_key = if (bind_key) self.perm_auth_key else &self.auth_key.auth_key;
    try MT2Crypto.encrypt(io, data, &auth_key_id, auth_key, salt, session_id, message_id, @intCast(seqno), message_len, .client_to_server);
}

/// Executes a graceful shutdown, so that all the pending requests are processed before terminating the connection.
///
/// Waits for all the requests to be processed, and prevents new messages from being sent.
pub fn gracefulShutdown(self: *Session, io: std.Io) void {
    {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);

        if (self.shutdown.load(.acquire)) {
            return;
        }
        self.shutdown.store(true, .release);
        self.freeze_requests.store(false, .release);
        self.conn_restart.set(io);

        self.shutdown_event.reset();
    }
    if (self.pending_requests.load(.acquire) == 0) {
        self.shutdown_event.set(io);
    }

    self.shutdown_event.waitUncancelable(io);
}

/// Signals all pending requests and prevents new ones.
///
/// Call `deinit` after this function returns.
pub fn destroyRequests(self: *Session, allocator: std.mem.Allocator, io: std.Io) void {
    {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);

        self.shutdown.store(true, .release);
        self.shutdown_event.reset();

        self.freeze_requests.store(false, .release);

        var it = self.pending_answers.map.iterator();
        while (it.next()) |pending_answer| {
            pending_answer.value_ptr.*.data = SendError.Shutdown;
            if (pending_answer.value_ptr.*.proto_container_id) |container_id| {
                self.removeMessageFromContainer(allocator, container_id, pending_answer.key_ptr.*);
            }

            pending_answer.value_ptr.*.event.set(io);
        }

        if (self.pending_requests.load(.acquire) == 0) {
            self.shutdown_event.set(io);
        }
    }

    self.shutdown_event.waitUncancelable(io);
}

/// Before calling this function, make sure no worker is running and to have deleted every event in `pending_requests` (use `destroyRequests` for that)
pub fn deinit(self: *Session, io: std.Io, allocator: std.mem.Allocator) void {
    self.shutdown.store(true, .release);

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

    while (true) {
        var requests: [10]Request = undefined;
        const len = self.bootstrap_queue.getUncancelable(io, &requests, 0) catch {
            break;
        };
        if (len == 0) {
            break;
        }

        for (0..len) |i| {
            allocator.free(requests[i].data);
        }
    }
    self.bootstrap_queue.close(io);
    self.salts.deinit(allocator);
    self.pending_ack.deinit(allocator);
    self.pending_answers_idmap.deinit(allocator);

    {
        var it = self.pending_containers.iterator();

        while (it.next()) |container| {
            container.value_ptr.*.deinit(allocator);
        }
    }
    self.pending_containers.deinit(allocator);

    for (self.retry_backlog.items) |req| {
        allocator.free(req.data);
    }
    self.retry_backlog.deinit(allocator);

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

pub fn init(self: *Session, io: std.Io, client_manager: *ClientManager, auth_key: *const [256]u8, dc: DcId, id: u8) !void {
    log.info("Initializing session - {f}", .{dc});
    self.* = Session{
        .dc = dc,
        // time is automatically synced with the server during auth key gen
        .message_id = .{},
        .seq_no = 0,
        .salts = .empty,
        .perm_auth_key = auth_key,
        .auth_key_id = undefined,
        .session_id = undefined,
        .perm_auth_key_id = undefined,
        .pending_ack = .empty,
        .pending_answers = .{
            .map = .{},
        },
        .current_id = .init(0),
        .shutdown = .init(false),
        .pending_requests = .init(0),
        .pending_containers = .empty,
        .shutdown_event = .unset,
        .mutex = .init,
        .pending_answers_idmap = .{},
        .requests_queue = .init(&self.requests_queue_buffer),
        .bootstrap_queue = .init(&.{}),
        .requests_queue_buffer = undefined,
        .client_manager = client_manager,
        .id = id,
    };

    try std.Io.randomSecure(io, @ptrCast(&self.session_id));

    // The authorization key id is the 64 lower-bits of the SHA1 hash of the
    // authorization key
    var auth_key_id: [20]u8 = undefined;
    std.crypto.hash.Sha1.hash(self.perm_auth_key, &auth_key_id, .{});
    @memcpy(&self.perm_auth_key_id, auth_key_id[12..20]);
}

test "message state flags do not change the base state" {
    const all_flags = 8 | 16 | 32 | 64 | 128;

    try std.testing.expectEqual(@as(u3, 1), messageStateCode(1 | all_flags));
    try std.testing.expectEqual(@as(u3, 4), messageStateCode(4 | all_flags));
}

test "processBatch emits decryptable client packet" {
    const SessionTestServer = @import("./session_test_server.zig");
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var perm_auth_key: [256]u8 = undefined;
    var temp_auth_key: [256]u8 = undefined;
    for (&perm_auth_key, 0..) |*byte, i| {
        byte.* = @intCast((i * 17 + 3) % 251);
    }
    for (&temp_auth_key, 0..) |*byte, i| {
        byte.* = @intCast((i * 31 + 11) % 251);
    }

    var client_manager: ClientManager = undefined;
    var session: Session = undefined;
    try session.init(io, &client_manager, &perm_auth_key, .{ .id = 2, .testmode = true }, 0);
    defer session.deinit(io, allocator);

    session.session_id = 0x1122334455667788;
    session.auth_key = .{
        .auth_key = temp_auth_key,
        .first_salt = 0x8877665544332211,
        .expiration = null,
    };
    var temp_auth_key_sha1: [20]u8 = undefined;
    std.crypto.hash.Sha1.hash(&temp_auth_key, &temp_auth_key_sha1, .{});
    @memcpy(&session.auth_key_id, temp_auth_key_sha1[12..20]);

    try session.salts.append(allocator, .{
        .salt = session.auth_key.first_salt,
        .valid_since = 0,
        .valid_until = std.math.maxInt(i32),
    });

    const holder, const dummy = try TransportConnector.dummyTransport(allocator);
    defer holder.deinit(io);

    var server = SessionTestServer.init(dummy, &session.auth_key_id, &session.auth_key.auth_key, session.session_id, session.auth_key.first_salt);

    const body_bytes = [_]u8{ 0x04, 0x03, 0x02, 0x01 };
    const body = try allocator.dupe(u8, &body_bytes);
    const message_id = 0x0000000100000000;
    var batch = [_]Request{.{
        .id = null,
        .data = body,
        .content_related = false,
        .message_id = message_id,
    }};

    try session.processBatch(allocator, io, holder.transport, &batch);

    const packet = try server.recvClientPacket(io);
    defer packet.deinit();

    try std.testing.expectEqual(MT2Crypto.Layout.totalLen(body_bytes.len), packet.bytes.len);
    try std.testing.expectEqualSlices(u8, &session.auth_key_id, packet.bytes[MT2Crypto.Layout.AUTH_KEY_ID..MT2Crypto.Layout.MSG_KEY]);
    try std.testing.expectEqual(session.auth_key.first_salt, packet.header.salt);
    try std.testing.expectEqual(session.session_id, packet.header.session_id);
    try std.testing.expectEqual(message_id, packet.header.message_id);
    try std.testing.expectEqual(@as(u32, 0), packet.header.seqno);
    try std.testing.expectEqualSlices(u8, &body_bytes, packet.body);
}

test "send resolves rpc_result through reader and writer workers" {
    const SessionTestServer = @import("./session_test_server.zig");
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var perm_auth_key: [256]u8 = undefined;
    var temp_auth_key: [256]u8 = undefined;
    for (&perm_auth_key, 0..) |*byte, i| {
        byte.* = @intCast((i * 17 + 3) % 251);
    }
    for (&temp_auth_key, 0..) |*byte, i| {
        byte.* = @intCast((i * 31 + 11) % 251);
    }

    var client_manager: ClientManager = undefined;
    var session: Session = undefined;
    try session.init(io, &client_manager, &perm_auth_key, .{ .id = 2, .testmode = true }, 0);
    defer session.deinit(io, allocator);

    session.session_id = 0x1122334455667788;
    session.auth_key = .{
        .auth_key = temp_auth_key,
        .first_salt = 0x8877665544332211,
        .expiration = null,
    };
    var temp_auth_key_sha1: [20]u8 = undefined;
    std.crypto.hash.Sha1.hash(&temp_auth_key, &temp_auth_key_sha1, .{});
    @memcpy(&session.auth_key_id, temp_auth_key_sha1[12..20]);

    try session.salts.append(allocator, .{
        .salt = session.auth_key.first_salt,
        .valid_since = 0,
        .valid_until = std.math.maxInt(i32),
    });
    session.connection_bound_auth_key = true;
    session.init_ok = true;

    const holder, const dummy = try TransportConnector.dummyTransport(allocator);
    defer holder.deinit(io);

    var server = SessionTestServer.init(dummy, &session.auth_key_id, &session.auth_key.auth_key, session.session_id, session.auth_key.first_salt);

    const ScriptedServer = struct {
        fn run(test_server: *SessionTestServer, test_session: *Session, test_allocator: std.mem.Allocator, test_io: std.Io, expected_ping_id: u64) std.Io.Cancelable!void {
            const packet = test_server.recvClientPacket(test_io) catch unreachable;
            defer packet.deinit();

            std.testing.expectEqual(test_session.session_id, packet.header.session_id) catch unreachable;
            std.testing.expectEqual(test_session.auth_key.first_salt, packet.header.salt) catch unreachable;
            std.testing.expectEqual(tl.TL.Enum.ProtoPing, tl.TL.identify(std.mem.readInt(u32, packet.body[0..4], .little)).?) catch unreachable;

            var ping_buf: [@sizeOf(tl.ProtoPing)]u8 align(@alignOf(tl.ProtoPing)) = undefined;
            const ping, _, _ = tl.ProtoPing.deserialize(packet.body[4..], &ping_buf);
            std.testing.expectEqual(expected_ping_id, ping.ping_id) catch unreachable;

            const response_msg_id = (test_session.message_id.get(test_io) & ~@as(u64, 3)) | 1;
            test_server.sendRpcResult(
                test_allocator,
                test_io,
                response_msg_id,
                packet.header.message_id,
                tl.TL{ .ProtoPong = &.{ .msg_id = packet.header.message_id, .ping_id = ping.ping_id } },
            ) catch unreachable;
        }
    };

    var group: std.Io.Group = .init;
    defer group.cancel(io);

    try group.concurrent(io, Session.writerWorker, .{ &session, io, allocator, holder.transport });
    try group.concurrent(io, Session.readerWorker, .{ &session, io, allocator, holder.transport });

    const ping_id = 0x1122334455667788;
    try group.concurrent(io, ScriptedServer.run, .{ &server, &session, allocator, io, ping_id });

    const response = try session.send(io, allocator, tl.TL{ .ProtoPing = &.{ .ping_id = ping_id } }, null, false);
    defer response.deinit(allocator);

    switch (response.data) {
        .ProtoPong => |pong| {
            try std.testing.expectEqual(ping_id, pong.ping_id);
        },
        else => return error.UnexpectedResponse,
    }

    try session.mutex.lock(io);
    defer session.mutex.unlock(io);
    try std.testing.expectEqual(@as(usize, 0), session.pending_answers.map.count());
    try std.testing.expectEqual(@as(usize, 0), session.pending_answers_idmap.count());
    try std.testing.expectEqual(@as(u32, 0), session.pending_requests.load(.seq_cst));
}

test "concurrent rpc queries" {
    const SessionTestServer = @import("./session_test_server.zig");
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const request_count = 3;

    var perm_auth_key: [256]u8 = undefined;
    var temp_auth_key: [256]u8 = undefined;
    for (&perm_auth_key, 0..) |*byte, i| {
        byte.* = @intCast((i * 17 + 3) % 251);
    }
    for (&temp_auth_key, 0..) |*byte, i| {
        byte.* = @intCast((i * 31 + 11) % 251);
    }

    var client_manager: ClientManager = undefined;
    var session: Session = undefined;
    try session.init(io, &client_manager, &perm_auth_key, .{ .id = 2, .testmode = true }, 0);
    defer session.deinit(io, allocator);

    session.session_id = 0x1122334455667788;
    session.auth_key = .{
        .auth_key = temp_auth_key,
        .first_salt = 0x8877665544332211,
        .expiration = null,
    };
    var temp_auth_key_sha1: [20]u8 = undefined;
    std.crypto.hash.Sha1.hash(&temp_auth_key, &temp_auth_key_sha1, .{});
    @memcpy(&session.auth_key_id, temp_auth_key_sha1[12..20]);

    try session.salts.append(allocator, .{
        .salt = session.auth_key.first_salt,
        .valid_since = 0,
        .valid_until = std.math.maxInt(i32),
    });
    session.connection_bound_auth_key = true;
    session.init_ok = true;

    const holder, const dummy = try TransportConnector.dummyTransport(allocator);
    defer holder.deinit(io);

    var server = SessionTestServer.init(dummy, &session.auth_key_id, &session.auth_key.auth_key, session.session_id, session.auth_key.first_salt);

    const ClientRequest = struct {
        msg_id: u64,
        ping_id: u64,
    };

    const ScriptedServer = struct {
        fn appendPing(out: *[request_count]ClientRequest, out_len: *usize, msg_id: u64, body: []const u8) void {
            std.testing.expect(out_len.* < out.len) catch unreachable;
            std.testing.expectEqual(tl.TL.Enum.ProtoPing, tl.TL.identify(std.mem.readInt(u32, body[0..4], .little)).?) catch unreachable;

            var ping_buf: [@sizeOf(tl.ProtoPing)]u8 align(@alignOf(tl.ProtoPing)) = undefined;
            const ping, _, _ = tl.ProtoPing.deserialize(body[4..], &ping_buf);

            out[out_len.*] = .{
                .msg_id = msg_id,
                .ping_id = ping.ping_id,
            };
            out_len.* += 1;
        }

        fn appendPacketRequests(out: *[request_count]ClientRequest, out_len: *usize, packet: SessionTestServer.ClientPacket) void {
            const constructor = std.mem.readInt(u32, packet.body[0..4], .little);
            if (constructor != SessionTestServer.MESSAGE_CONTAINER_CID) {
                appendPing(out, out_len, packet.header.message_id, packet.body);
                return;
            }

            const count = std.mem.readInt(u32, packet.body[4..8], .little);
            var cursor: usize = 8;
            for (0..count) |_| {
                std.testing.expect(cursor + 16 <= packet.body.len) catch unreachable;

                const msg_id = std.mem.readInt(u64, packet.body[cursor..][0..8], .little);
                cursor += 8;
                cursor += 4;
                const body_len = std.mem.readInt(u32, packet.body[cursor..][0..4], .little);
                cursor += 4;

                std.testing.expect(cursor + body_len <= packet.body.len) catch unreachable;
                appendPing(out, out_len, msg_id, packet.body[cursor..][0..body_len]);
                cursor += body_len;
            }
            std.testing.expectEqual(packet.body.len, cursor) catch unreachable;
        }

        fn run(test_server: *SessionTestServer, test_session: *Session, test_allocator: std.mem.Allocator, test_io: std.Io, expected_ping_ids: *const [request_count]u64) std.Io.Cancelable!void {
            var requests: [request_count]ClientRequest = undefined;
            var requests_len: usize = 0;

            while (requests_len < request_count) {
                const packet = test_server.recvClientPacket(test_io) catch unreachable;
                defer packet.deinit();

                std.testing.expectEqual(test_session.session_id, packet.header.session_id) catch unreachable;
                std.testing.expectEqual(test_session.auth_key.first_salt, packet.header.salt) catch unreachable;

                appendPacketRequests(&requests, &requests_len, packet);
            }

            for (expected_ping_ids) |expected_ping_id| {
                var found = false;
                for (requests) |request| {
                    if (request.ping_id == expected_ping_id) {
                        found = true;
                        break;
                    }
                }
                std.testing.expect(found) catch unreachable;
            }

            const first_msg_id = (test_session.message_id.get(test_io) & ~@as(u64, 3)) | 1;
            var pongs: [request_count]tl.ProtoPong = undefined;
            var responses: [request_count]SessionTestServer.RpcResult = undefined;

            for (0..request_count) |i| {
                const request_index = request_count - 1 - i;
                pongs[i] = .{
                    .msg_id = requests[request_index].msg_id,
                    .ping_id = requests[request_index].ping_id,
                };
                responses[i] = .{
                    .msg_id = first_msg_id + @as(u64, @intCast(i)) * 4,
                    .req_msg_id = requests[request_index].msg_id,
                    .result = tl.TL{ .ProtoPong = &pongs[i] },
                };
            }

            const container_msg_id = first_msg_id + @as(u64, @intCast(request_count)) * 4;
            test_server.sendRpcResultContainer(test_allocator, test_io, container_msg_id, &responses) catch unreachable;
        }
    };

    const SendWorker = struct {
        fn run(test_session: *Session, test_allocator: std.mem.Allocator, test_io: std.Io, ping_id: u64, remaining: *std.atomic.Value(u32), all_done: *std.Io.Event, result: *u64) std.Io.Cancelable!void {
            defer if (remaining.fetchSub(1, .seq_cst) == 1) all_done.set(test_io);

            const response = test_session.send(test_io, test_allocator, tl.TL{ .ProtoPing = &.{ .ping_id = ping_id } }, null, false) catch unreachable;
            defer response.deinit(test_allocator);

            switch (response.data) {
                .ProtoPong => |pong| {
                    std.testing.expectEqual(ping_id, pong.ping_id) catch unreachable;
                    result.* = pong.ping_id;
                },
                else => unreachable,
            }
        }
    };

    const CompletionWait = struct {
        fn wait(event: *std.Io.Event, test_io: std.Io) !void {
            const Result = union(enum) {
                completed: std.Io.Cancelable!void,
                timeout: std.Io.Cancelable!void,
            };
            const Select = std.Io.Select(Result);
            const completion_timeout: std.Io.Timeout = .{ .duration = .{ .raw = .fromSeconds(5), .clock = .boot } };

            var buffer: [2]Result = undefined;
            var select = Select.init(test_io, &buffer);
            try select.concurrent(.completed, std.Io.Event.wait, .{ event, test_io });
            try select.concurrent(.timeout, std.Io.Timeout.sleep, .{ completion_timeout, test_io });

            const result = try select.await();
            _ = select.cancel();

            switch (result) {
                .completed => |completed| try completed,
                .timeout => |timed_out| {
                    try timed_out;
                    return error.Timeout;
                },
            }
        }
    };

    var group: std.Io.Group = .init;
    defer group.cancel(io);

    const ping_ids = [request_count]u64{
        0x1011121314151617,
        0x2021222324252627,
        0x3031323334353637,
    };
    var remaining: std.atomic.Value(u32) = .init(request_count);
    var all_done: std.Io.Event = .unset;
    var results: [request_count]u64 = @splat(0);

    for (ping_ids, 0..) |ping_id, i| {
        try group.concurrent(io, SendWorker.run, .{ &session, allocator, io, ping_id, &remaining, &all_done, &results[i] });
    }

    const poll_interval: std.Io.Timeout = .{ .duration = .{ .raw = .fromMilliseconds(1), .clock = .boot } };
    var queued = false;
    for (0..1000) |_| {
        try session.mutex.lock(io);
        const pending_count = session.pending_answers.map.count();
        session.mutex.unlock(io);

        if (pending_count == request_count) {
            queued = true;
            break;
        }

        try poll_interval.sleep(io);
    }
    try std.testing.expect(queued);
    try poll_interval.sleep(io);

    try group.concurrent(io, Session.writerWorker, .{ &session, io, allocator, holder.transport });
    try group.concurrent(io, Session.readerWorker, .{ &session, io, allocator, holder.transport });
    try group.concurrent(io, ScriptedServer.run, .{ &server, &session, allocator, io, &ping_ids });

    try CompletionWait.wait(&all_done, io);

    try std.testing.expectEqualSlices(u64, &ping_ids, &results);

    try session.mutex.lock(io);
    defer session.mutex.unlock(io);
    try std.testing.expectEqual(@as(usize, 0), session.pending_answers.map.count());
    try std.testing.expectEqual(@as(usize, 0), session.pending_answers_idmap.count());
    try std.testing.expectEqual(@as(usize, 0), session.pending_containers.count());
    try std.testing.expectEqual(@as(u32, 0), session.pending_requests.load(.seq_cst));
}
