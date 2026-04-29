const tl = @import("../tl/api.zig");
const std = @import("std");

extern fn pq_factor(n: u64, p: [*c]u64, q: [*c]u64) c_int;
extern fn pq_seed(seed: u64) void;
extern fn pq_factorize(n: u64) u64;

const utils = @import("./utils.zig");

const MessageID = @import("./message_id.zig");

const Transport = @import("../transport.zig").Transport;
const ige = @import("../crypto/ige.zig").ige;

const RSAPublicKey = @import("../crypto/public_key_parser.zig");

pub const TEMP_KEYS_EXPIRE_IN_S = 1800;
pub const TEMP_KEYS_ADVANCE_S = 120;
pub const GenError = error{
    ConnectionClosed,
    InvalidResponse,
    Security,
    ModulusFailure,
    FailedResPQ,
    FailedReqDH,
    FailedSetClientDH,
    UnknownFingerprints,
} || std.mem.Allocator.Error;

pub const GeneratedAuthKey = struct {
    auth_key: [256]u8,
    first_salt: u64,
    expiration: ?std.Io.Clock.Timestamp,
};

const log = std.log.scoped(.mzproto_authkey);

const DH_PRIME_STANDARD = std.mem.readInt(u2048, &[_]u8{ 0xC7, 0x1C, 0xAE, 0xB9, 0xC6, 0xB1, 0xC9, 0x04, 0x8E, 0x6C, 0x52, 0x2F, 0x70, 0xF1, 0x3F, 0x73, 0x98, 0x0D, 0x40, 0x23, 0x8E, 0x3E, 0x21, 0xC1, 0x49, 0x34, 0xD0, 0x37, 0x56, 0x3D, 0x93, 0x0F, 0x48, 0x19, 0x8A, 0x0A, 0xA7, 0xC1, 0x40, 0x58, 0x22, 0x94, 0x93, 0xD2, 0x25, 0x30, 0xF4, 0xDB, 0xFA, 0x33, 0x6F, 0x6E, 0x0A, 0xC9, 0x25, 0x13, 0x95, 0x43, 0xAE, 0xD4, 0x4C, 0xCE, 0x7C, 0x37, 0x20, 0xFD, 0x51, 0xF6, 0x94, 0x58, 0x70, 0x5A, 0xC6, 0x8C, 0xD4, 0xFE, 0x6B, 0x6B, 0x13, 0xAB, 0xDC, 0x97, 0x46, 0x51, 0x29, 0x69, 0x32, 0x84, 0x54, 0xF1, 0x8F, 0xAF, 0x8C, 0x59, 0x5F, 0x64, 0x24, 0x77, 0xFE, 0x96, 0xBB, 0x2A, 0x94, 0x1D, 0x5B, 0xCD, 0x1D, 0x4A, 0xC8, 0xCC, 0x49, 0x88, 0x07, 0x08, 0xFA, 0x9B, 0x37, 0x8E, 0x3C, 0x4F, 0x3A, 0x90, 0x60, 0xBE, 0xE6, 0x7C, 0xF9, 0xA4, 0xA4, 0xA6, 0x95, 0x81, 0x10, 0x51, 0x90, 0x7E, 0x16, 0x27, 0x53, 0xB5, 0x6B, 0x0F, 0x6B, 0x41, 0x0D, 0xBA, 0x74, 0xD8, 0xA8, 0x4B, 0x2A, 0x14, 0xB3, 0x14, 0x4E, 0x0E, 0xF1, 0x28, 0x47, 0x54, 0xFD, 0x17, 0xED, 0x95, 0x0D, 0x59, 0x65, 0xB4, 0xB9, 0xDD, 0x46, 0x58, 0x2D, 0xB1, 0x17, 0x8D, 0x16, 0x9C, 0x6B, 0xC4, 0x65, 0xB0, 0xD6, 0xFF, 0x9C, 0xA3, 0x92, 0x8F, 0xEF, 0x5B, 0x9A, 0xE4, 0xE4, 0x18, 0xFC, 0x15, 0xE8, 0x3E, 0xBE, 0xA0, 0xF8, 0x7F, 0xA9, 0xFF, 0x5E, 0xED, 0x70, 0x05, 0x0D, 0xED, 0x28, 0x49, 0xF4, 0x7B, 0xF9, 0x59, 0xD9, 0x56, 0x85, 0x0C, 0xE9, 0x29, 0x85, 0x1F, 0x0D, 0x81, 0x15, 0xF6, 0x35, 0xB1, 0x05, 0xEE, 0x2E, 0x4E, 0x15, 0xD0, 0x4B, 0x24, 0x54, 0xBF, 0x6F, 0x4F, 0xAD, 0xF0, 0x34, 0xB1, 0x04, 0x03, 0x11, 0x9C, 0xD8, 0xE3, 0xB9, 0x2F, 0xCC, 0x5B }, .big);

inline fn validateDhPrime(p: u2048, g: u32) bool {
    // Client is expected to check whether p = dh_prime is a safe 2048-bit prime
    // (meaning that both p and (p-1)/2 are prime, and that 2^2047 < p < 2^2048),
    // and that g generates a cyclic subgroup of prime order (p-1)/2,
    // i.e. is a quadratic residue mod p.
    if (p <= (@as(u4096, 1) << 2047)) return false;
    if (p >= (@as(u4096, 1) << 2048) - 1) return false;

    if ((p & 1) == 0) return false;

    switch (g) {
        2 => if (p % 8 != 7) return false,
        3 => if (p % 3 != 2) return false,
        4 => {},
        5 => if (!(p % 5 == 1 or p % 5 == 4)) return false,
        6 => if (!(p % 24 == 19 or p % 24 == 23)) return false,
        7 => if (!(p % 7 == 3 or p % 7 == 5 or p % 7 == 6)) return false,
        else => return false,
    }

    if (p == DH_PRIME_STANDARD) return true;

    // TODO: check if dh_prime is prime. we don't have libraries ready right now for that

    return true;
}

fn defaultKeys() []const RSAPublicKey {

    // Since the keys are already known, we can parse them at compile time. I love optimizations like these!!!!!!
    const keys = comptime blk: {
        const TELEGRAM_PUBLIC_KEYS = [_][]const u8{
            // testmode keys

            \\-----BEGIN RSA PUBLIC KEY-----
            \\MIIBCgKCAQEAyMEdY1aR+sCR3ZSJrtztKTKqigvO/vBfqACJLZtS7QMgCGXJ6XIR
            \\yy7mx66W0/sOFa7/1mAZtEoIokDP3ShoqF4fVNb6XeqgQfaUHd8wJpDWHcR2OFwv
            \\plUUI1PLTktZ9uW2WE23b+ixNwJjJGwBDJPQEQFBE+vfmH0JP503wr5INS1poWg/
            \\j25sIWeYPHYeOrFp/eXaqhISP6G+q2IeTaWTXpwZj4LzXq5YOpk4bYEQ6mvRq7D1
            \\aHWfYmlEGepfaYR8Q0YqvvhYtMte3ITnuSJs171+GDqpdKcSwHnd6FudwGO4pcCO
            \\j4WcDuXc2CTHgH8gFTNhp/Y8/SpDOhvn9QIDAQAB
            \\-----END RSA PUBLIC KEY-----
            ,
            // production key

            \\-----BEGIN RSA PUBLIC KEY-----
            \\MIIBCgKCAQEA6LszBcC1LGzyr992NzE0ieY+BSaOW622Aa9Bd4ZHLl+TuFQ4lo4g
            \\5nKaMBwK/BIb9xUfg0Q29/2mgIR6Zr9krM7HjuIcCzFvDtr+L0GQjae9H0pRB2OO
            \\62cECs5HKhT5DZ98K33vmWiLowc621dQuwKWSQKjWf50XYFw42h21P2KXUGyp2y/
            \\+aEyZ+uVgLLQbRA1dEjSDZ2iGRy12Mk5gpYc397aYp438fsJoHIgJ2lgMv5h7WY9
            \\t6N/byY9Nw9p21Og3AoXSL2q/2IJ1WRUhebgAdGVMlV1fkuOQoEzR7EdpqtQD9Cs
            \\5+bfo3Nhmcyvk5ftB0WkJ9z6bNZ7yxrP8wIDAQAB
            \\-----END RSA PUBLIC KEY-----
        };
        @setEvalBranchQuota(1000000);

        var default_keys: [TELEGRAM_PUBLIC_KEYS.len]RSAPublicKey = undefined;
        for (TELEGRAM_PUBLIC_KEYS, 0..) |key, i| {
            default_keys[i] = RSAPublicKey.parseRSAPublicKey(key) catch unreachable;
        }
        break :blk default_keys;
    };
    return &keys;
}

fn getPublicKey(id: u64) ?struct { u2048, u64 } {
    const default_keys = comptime defaultKeys();

    // TODO: Allow adding third party keys, might be useful for unofficial servers.

    for (default_keys) |key| {
        if (id == key.fingerprint) {
            return .{ key.modulus, key.exponent };
        }
    }
    return null;
}

const AuthGen = struct {
    allocator: std.mem.Allocator,
    dc_id: u8,
    test_mode: bool,
    temp_key: bool,
    media: bool,
    status: enum {
        Idle,
        ReqPQ,
        ReqDH,
        setClientDH,
        Failed,
        Completed,
    } = .Idle,

    nonce: u128 = 0,
    server_nonce: u128 = 0,
    new_nonce: u256 = 0,
    public_key: ?struct { u2048, u64 } = null,
    gA: u2048 = 0,
    b: [256]u8 = undefined,
    dh_prime: u2048 = 0,
    transport: *Transport,
    io: std.Io,
    expiration: ?std.Io.Clock.Timestamp = null,
    message_id: ?*MessageID,

    /// Sends data in plain text mode.
    ///
    /// The plain text mode sets the auth key to zero
    fn sendData(self: *AuthGen, data: []const u8) !void {
        var headers: [@sizeOf(i64) + @sizeOf(i64) + @sizeOf(i32)]u8 = undefined;

        @memset(headers[0..8], 0);
        std.mem.writeInt(i64, headers[8..16], (std.Io.Clock.now(.real, self.io)).toMilliseconds() << 32, .little);
        std.mem.writeInt(i32, headers[16..20], @intCast(data.len), .little);

        var dataa = [_][]const u8{ &headers, data };
        try self.transport.writeVec(self.io, &dataa);
    }

    fn reqPQ(self: *AuthGen) !utils.Deserialized {
        //self.nonce = std.crypto.random.int(u128);

        try std.Io.randomSecure(self.io, @ptrCast(&self.nonce));
        var data: [tl.TL.serializeSize(&tl.TL{ .ProtoReqPqMulti = &.{ .nonce = 0 } })]u8 = undefined;
        const toWrite = tl.TL.serialize(&.{ .ProtoReqPqMulti = &.{ .nonce = self.nonce } }, &data);

        try self.sendData(data[0..toWrite]);

        const d = try self.recvData();
        errdefer d.deinit(self.allocator);

        if (d.data != .ProtoResPQ) {
            self.status = .Failed;
            log.err("received data is not ProtoResPQ", .{});
            return GenError.FailedResPQ;
        }
        const resPQ = d.data.ProtoResPQ;
        if (resPQ.nonce != self.nonce) {
            self.status = .Failed;
            log.err("the received resPQ.nonce is not the same as the stored one", .{});
            return GenError.Security;
        }
        self.server_nonce = resPQ.server_nonce;

        return d;
    }

    /// Receive data in plain text mode
    fn recvData(self: *AuthGen) !utils.Deserialized {
        const len = try self.transport.recvLen(self.io);

        const buf = try self.allocator.alloc(u8, len);
        defer self.allocator.free(buf);

        _ = try self.transport.recv(self.io, buf);

        const len_body = std.mem.readInt(u32, buf[16..20], .little);
        var size: usize = 0;
        _ = tl.TL.deserializeSize(buf[20 .. 20 + len_body], &size);
        const dest = try self.allocator.alloc(u8, size);
        errdefer self.allocator.free(dest);

        const des = tl.TL.deserialize(buf[20 .. 20 + len_body], dest);

        return .{ .ptr = dest, .data = des[0] };
    }

    fn reqDH(self: *AuthGen, resPQ: *const tl.ProtoResPQ) !void {
        {
            self.public_key = null;

            var selectedFingerprint: u64 = 0;

            for (resPQ.server_public_key_fingerprints) |fingerprint| {
                if (getPublicKey(@bitCast(fingerprint))) |k| {
                    self.public_key = k;
                    selectedFingerprint = fingerprint;
                    break;
                }
            }

            if (self.public_key == null) {
                self.status = .Failed;
                log.err("No known key fingerprints to use", .{});
                return GenError.UnknownFingerprints;
            }

            var p: u64 = 0;
            var q: u64 = 0;

            // get the primes p and q from pq
            if (pq_factor(std.mem.readInt(u64, resPQ.pq[0..8], .big), &p, &q) != 1) {
                self.status = .Failed;
                log.err("Factors failed to generate", .{});
                return GenError.Security;
            }

            try std.Io.randomSecure(self.io, @ptrCast(&self.new_nonce));

            //

            var dcId: i32 = self.dc_id;
            if (self.test_mode)
                dcId += 10000;
            if (self.media)
                dcId = -dcId;

            var sbuf: [144]u8 = undefined;

            var pBytes: [4]u8 = undefined;
            var qBytes: [4]u8 = undefined;

            std.mem.writeInt(u32, &pBytes, @intCast(p), .big);
            std.mem.writeInt(u32, &qBytes, @intCast(q), .big);

            var written: usize = 0;

            if (self.temp_key) {
                const innerData = tl.TL{ .ProtoPQInnerDataTempDc = &.{ .dc = @bitCast(dcId), .new_nonce = self.new_nonce, .nonce = self.nonce, .server_nonce = self.server_nonce, .p = &pBytes, .q = &qBytes, .pq = resPQ.pq, .expires_in = TEMP_KEYS_EXPIRE_IN_S } };
                written = innerData.serialize(&sbuf);
            } else {
                const innerData = tl.TL{ .ProtoPQInnerDataDc = &.{ .dc = @bitCast(dcId), .new_nonce = self.new_nonce, .nonce = self.nonce, .server_nonce = self.server_nonce, .p = &pBytes, .q = &qBytes, .pq = resPQ.pq } };
                written = innerData.serialize(&sbuf);
            }

            const bytes = try rsaPad(self.io, sbuf[0..written], self.public_key.?[0], self.public_key.?[1]);

            var req_dh: [500]u8 = undefined;

            const r = tl.TL{ .ProtoReqDHParams = &.{ .encrypted_data = &bytes, .nonce = self.nonce, .p = &pBytes, .q = &qBytes, .public_key_fingerprint = selectedFingerprint, .server_nonce = self.server_nonce } };
            written = r.serialize(&req_dh);

            if (self.temp_key) {
                self.expiration = std.Io.Clock.Timestamp.now(self.io, .boot).addDuration(.{ .clock = .boot, .raw = std.Io.Duration.fromSeconds(TEMP_KEYS_EXPIRE_IN_S) });
            }
            try self.sendData(req_dh[0..written]);

            self.status = .ReqDH;
        }

        var key: [32]u8 = undefined;
        var iv: [32]u8 = undefined;

        const deser, const buf_deser = inner_data: {
            const d = try self.recvData();
            defer d.deinit(self.allocator);

            if (d.data != .ProtoServerDHParamsOk) {
                self.status = .Failed;
                log.err("The response is not .ProtoServerDHParamsOk", .{});
                return GenError.FailedReqDH;
            }

            const dhParamsOk = d.data.ProtoServerDHParamsOk;

            if (dhParamsOk.nonce != self.nonce) {
                self.status = .Failed;
                log.err("The received dhParamsOk.nonce is not the same as the stored one", .{});
                return GenError.Security;
            }

            if (dhParamsOk.server_nonce != self.server_nonce) {
                self.status = .Failed;
                log.err("The received dhParamsOk.server_nonce is not the same as the stored one", .{});
                return GenError.Security;
            }

            {
                var tmp: [48]u8 = undefined;
                std.mem.writeInt(u256, tmp[0..32], self.new_nonce, .little);
                std.mem.writeInt(u128, tmp[32..48], dhParamsOk.server_nonce, .little);
                std.crypto.hash.Sha1.hash(&tmp, key[0..20], .{});

                var tmp2: [20]u8 = undefined;
                std.mem.writeInt(u128, tmp[0..16], dhParamsOk.server_nonce, .little);
                std.mem.writeInt(u256, tmp[16..48], self.new_nonce, .little);
                std.crypto.hash.Sha1.hash(&tmp, &tmp2, .{});
                @memcpy(key[20..32], tmp2[0..12]);
            }

            {
                //tmp_aes_iv := substr (SHA1(server_nonce + new_nonce), 12, 8) + SHA1(new_nonce + new_nonce) + substr (new_nonce, 0, 4);
                var tmp: [80]u8 = undefined;

                std.mem.writeInt(u128, tmp[0..16], dhParamsOk.server_nonce, .little);
                std.mem.writeInt(u256, tmp[16..48], self.new_nonce, .little);
                std.crypto.hash.Sha1.hash(tmp[0..48], iv[0..20], .{});
                @memcpy(iv[0..8], iv[12..20]);

                std.mem.writeInt(u256, tmp[0..32], self.new_nonce, .little);
                std.mem.writeInt(u256, tmp[32..64], self.new_nonce, .little);
                std.crypto.hash.Sha1.hash(tmp[0..64], iv[8..28], .{});

                @memcpy(iv[28..32], tmp[0..4]);
            }

            {
                var tmp: [32]u8 = undefined;
                var hash = std.crypto.hash.Sha1.init(.{});

                std.mem.writeInt(u256, &tmp, self.new_nonce, .little);

                hash.update(&tmp);
                hash.update(&tmp);

                hash.final(iv[8..28]);
                @memcpy(iv[28..32], tmp[0..4]);
            }

            ige(dhParamsOk.encrypted_answer, @constCast(dhParamsOk.encrypted_answer), &key, &iv, false);

            var size: usize = 0;

            const answer_len = tl.TL.deserializeSize(dhParamsOk.encrypted_answer[20..], &size);

            {
                var computed_hash: [20]u8 = undefined;
                std.crypto.hash.Sha1.hash(dhParamsOk.encrypted_answer[20 .. 20 + answer_len], &computed_hash, .{});
                if (!std.mem.eql(u8, &computed_hash, dhParamsOk.encrypted_answer[0..20])) {
                    log.err("dhParamsOk.encrypted_answer doesn't match the computed hash", .{});
                    return GenError.Security;
                }
            }

            const buf_deser = try self.allocator.alloc(u8, size);
            errdefer self.allocator.free(buf_deser);

            const deser = tl.TL.deserialize(dhParamsOk.encrypted_answer[20..], buf_deser);

            break :inner_data .{ deser[0], buf_deser };
        };
        defer self.allocator.free(buf_deser);

        if (deser != .ProtoServerDHInnerData) {
            self.status = .Failed;
            log.err("the response is not ProtoServerDHInnerData", .{});
            return GenError.FailedReqDH;
        }

        const dhInnerData = deser.ProtoServerDHInnerData;

        if (self.message_id) |message_id| {
            message_id.updateTime(self.io, dhInnerData.server_time);
        }

        if (dhInnerData.nonce != self.nonce) {
            self.status = .Failed;
            log.err("the received dhInnerData.nonce is not the same as the stored one", .{});
            return GenError.Security;
        }

        if (dhInnerData.server_nonce != self.server_nonce) {
            self.status = .Failed;
            log.err("the received dhInnerData.server_nonce is not the same as the stored one", .{});
            return GenError.Security;
        }

        self.dh_prime = std.mem.readInt(u2048, dhInnerData.dh_prime[0..256], .big);
        self.gA = std.mem.readInt(u2048, dhInnerData.g_a[0..256], .big);
        try std.Io.randomSecure(self.io, @ptrCast(&self.b));

        if (!validateDhPrime(self.dh_prime, dhInnerData.g)) {
            log.err("dh_prime failed validation", .{});
            return GenError.Security;
        }

        var m = try Modulus.fromPrimitive(u2048, self.dh_prime);

        const x = try Modulus.Fe.fromPrimitive(u32, m, dhInnerData.g);

        const gB_m = try m.powWithEncodedPublicExponent(x, &self.b, .little);

        const gB = try gB_m.toPrimitive(u2048);

        rangeCheck(@intCast(dhInnerData.g), 1, (self.dh_prime - 1)) catch |err| {
            self.status = .Failed;
            return err;
        };
        rangeCheck(self.gA, 1, (self.dh_prime - 1)) catch |err| {
            self.status = .Failed;
            return err;
        };
        rangeCheck(@intCast(gB), 1, (self.dh_prime - 1)) catch |err| {
            self.status = .Failed;
            return err;
        };

        const safeRange = 1 << (2048 - 64);

        rangeCheck(self.gA, safeRange, (self.dh_prime - safeRange)) catch |err| {
            self.status = .Failed;
            return err;
        };

        rangeCheck(@intCast(gB), safeRange, (self.dh_prime - safeRange)) catch |err| {
            self.status = .Failed;
            return err;
        };

        var gbBytes: [256]u8 = undefined;
        std.mem.writeInt(u2048, &gbBytes, @intCast(gB), .big);

        const dhClientInnerData = tl.TL{ .ProtoClientDHInnerData = &.{ .nonce = self.nonce, .server_nonce = self.server_nonce, .retry_id = 0, .g_b = &gbBytes } };

        var divisiblePadding: u8 = 0;
        const serSize = dhClientInnerData.serializeSize();

        while ((20 + serSize + divisiblePadding) % 16 != 0) {
            divisiblePadding += 1;
        }

        const bufSer = self.allocator.alloc(u8, 20 + serSize + divisiblePadding) catch |err| {
            self.status = .Failed;

            return err;
        };
        defer self.allocator.free(bufSer);

        var written = dhClientInnerData.serialize(bufSer[20 .. 20 + serSize]);

        try std.Io.randomSecure(self.io, bufSer[20 + written .. 20 + written + divisiblePadding]);
        std.crypto.hash.Sha1.hash(bufSer[20 .. 20 + written], bufSer[0..20], .{});

        ige(bufSer, bufSer, &key, &iv, true);

        const setDH = tl.TL{ .ProtoSetClientDHParams = &.{ .nonce = self.nonce, .server_nonce = self.server_nonce, .encrypted_data = bufSer[0 .. 20 + written + divisiblePadding] } };

        const bufSer2 = self.allocator.alloc(u8, setDH.serializeSize()) catch |err| {
            self.status = .Failed;
            return err;
        };
        defer self.allocator.free(bufSer2);

        written = setDH.serialize(bufSer2);

        self.sendData(bufSer2[0..written]) catch |err| {
            self.status = .Failed;
            return err;
        };

        self.status = .setClientDH;
    }

    fn setClientDH(self: *AuthGen) !GeneratedAuthKey {
        const d = try self.recvData();
        defer d.deinit(self.allocator);
        switch (d.data) {
            .ProtoDhGenOk => |dh_gen_ok| {
                var result = GeneratedAuthKey{
                    .auth_key = undefined,
                    .first_salt = 0,
                    .expiration = self.expiration,
                };

                if (dh_gen_ok.nonce != self.nonce) {
                    log.err("dh_gen_ok.nonce doesn't match stored nonce", .{});
                    return GenError.Security;
                }

                if (dh_gen_ok.server_nonce != self.server_nonce) {
                    log.err("dh_gen_ok.server_nonce doesn't match stored server_nonce", .{});
                    return GenError.Security;
                }

                var newNonce: [32]u8 = undefined;
                var serverNonce: [16]u8 = undefined;
                std.mem.writeInt(u256, &newNonce, self.new_nonce, .little);
                std.mem.writeInt(u128, &serverNonce, self.server_nonce, .little);

                result.first_salt = std.mem.readInt(u64, newNonce[0..8], .little) ^ std.mem.readInt(u64, serverNonce[0..8], .little);

                var m = try Modulus.fromPrimitive(u2048, self.dh_prime);

                const x = try Modulus.Fe.fromPrimitive(u2048, m, self.gA);

                const key_m = try m.powWithEncodedPublicExponent(x, &self.b, .little);

                try key_m.toBytes(&result.auth_key, .big);

                var hash: [20]u8 = undefined;
                std.crypto.hash.Sha1.hash(&result.auth_key, &hash, .{});

                var hash2: [20]u8 = undefined;

                var digest = std.crypto.hash.Sha1.init(.{});
                digest.update(&newNonce);
                digest.update(&.{1});
                digest.update(hash[0..8]);
                digest.final(&hash2);

                const computed_hash = std.mem.readInt(u128, hash2[4..], .little);

                if (computed_hash != dh_gen_ok.new_nonce_hash1) {
                    self.status = .Failed;
                    log.err("the computed hash doesn't match new_nonce_hash1", .{});
                    return GenError.Security;
                }

                self.status = .Completed;
                return result;
            },
            .ProtoDhGenRetry => {
                // TODO: retry
                self.status = .Failed;
                log.err("Received ProtoDhGenRetry", .{});
                return GenError.InvalidResponse;
            },
            else => {
                self.status = .Failed;
                log.err("Received an invalid response", .{});
                return GenError.InvalidResponse;
            },
        }
    }
};

const Modulus = std.crypto.ff.Modulus(2048);

inline fn rangeCheck(val: u2048, min: u2048, max: u2048) !void {
    if (!(min < val and val < max)) {
        log.err("rangeCheck failed", .{});
        return GenError.Security;
    }
}

/// RSA_PAD is a version of RSA with a variant of OAEP+ padding
fn rsaPad(io: std.Io, src: []const u8, m: u2048, e: u64) ![256]u8 {
    std.debug.assert(src.len <= 144);

    var result: [256]u8 = undefined;

    var temp_key: [32]u8 = undefined;
    try std.Io.randomSecure(io, @ptrCast(&temp_key));

    @memcpy(result[0..32], &temp_key);

    {
        const data_with_padding = result[32 .. 32 + 192];
        @memcpy(data_with_padding[0..src.len], src);
        try std.Io.randomSecure(io, data_with_padding[src.len..192]);

        std.crypto.hash.sha2.Sha256.hash(result[0 .. 32 + 192], result[224 .. 224 + 32], .{});
        std.mem.reverse(u8, data_with_padding);
    }

    {
        const data_with_hash = result[32..];
        const zeroIv = [_]u8{0} ** 32;
        ige(data_with_hash, data_with_hash, &temp_key, &zeroIv, true);

        std.crypto.hash.sha2.Sha256.hash(data_with_hash, result[0..32], .{});

        for (0..32) |i| {
            result[i] ^= temp_key[i];
        }
    }

    const key_aes_encryped = std.mem.readInt(u2048, &result, .big);

    // If `key_aes_encryped` is greater than the RSA modulus, we need to restart from the beginning
    if (key_aes_encryped > m) {
        return rsaPad(io, src, m, e);
    }

    const a = Modulus.fromPrimitive(u2048, m) catch {
        return GenError.ModulusFailure;
    };

    const b = Modulus.Fe.fromPrimitive(u64, a, e) catch {
        return GenError.ModulusFailure;
    };

    const c = Modulus.Fe.fromPrimitive(u2048, a, key_aes_encryped) catch {
        return GenError.ModulusFailure;
    };

    const rsa = a.powPublic(c, b) catch {
        return GenError.ModulusFailure;
    };

    rsa.toBytes(&result, .big) catch {
        return GenError.ModulusFailure;
    };

    return result;
}

/// Starts auth key generation on the specified `transport`
pub fn generate(allocator: std.mem.Allocator, io: std.Io, transport: *Transport, dcId: u8, media: bool, test_mode: bool, temp_key: bool, message_id: ?*MessageID) !GeneratedAuthKey {
    var self = AuthGen{
        .allocator = allocator,
        .dc_id = dcId,
        .media = media,
        .transport = transport,
        .test_mode = test_mode,
        .temp_key = temp_key,
        .io = io,
        .message_id = message_id,
    };
    const req_pq = try self.reqPQ();
    defer req_pq.deinit(allocator);

    const td = req_pq.data;
    try self.reqDH(td.ProtoResPQ);

    const set_client_dh = try self.setClientDH();

    return set_client_dh;
}
