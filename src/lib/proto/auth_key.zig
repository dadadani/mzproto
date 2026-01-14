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
const factorize = @cImport({
    @cInclude("pq.h");
});
const utils = @import("./utils.zig");

const Transport = @import("../transport.zig").Transport;
const ige = @import("../crypto/ige.zig").ige;

const RSAPublicKey = @import("../crypto/public_key_parser.zig");

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
    authKey: [256]u8,
    first_salt: u64,
};

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
    dcId: u8,
    testMode: bool,
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
    dhPrime: u2048 = 0,
    transport: *Transport,
    io: std.Io,

    /// Sends data in plain text mode.
    ///
    /// The plain text mode sets the auth key to zero
    fn sendData(self: *AuthGen, data: []const u8) !void {
        var headers: [@sizeOf(i64) + @sizeOf(i64) + @sizeOf(i32)]u8 = undefined;

        @memset(headers[0..8], 0);
        std.mem.writeInt(i64, headers[8..16], (try std.Io.Clock.now(.real, self.io)).toMilliseconds() << 32, .little);
        std.mem.writeInt(i32, headers[16..20], @intCast(data.len), .little);

        try self.transport.writeVec(&.{ &headers, data });
    }

    fn reqPQ(self: *AuthGen) !utils.Deserialized {
        //self.nonce = std.crypto.random.int(u128);

        try std.Io.randomSecure(self.io, @ptrCast(&self.nonce));
        var data: [tl.TL.serializeSize(&tl.TL{ .ProtoReqPqMulti = &.{ .nonce = 0 } })]u8 = undefined;
        const toWrite = tl.TL.serialize(&.{ .ProtoReqPqMulti = &.{ .nonce = self.nonce } }, &data);

        try self.sendData(data[0..toWrite]);

        const d = try self.recvData();
        errdefer self.allocator.free(d.ptr);

        if (d.data != .ProtoResPQ) {
            self.status = .Failed;
            return GenError.FailedResPQ;
        }
        const resPQ = d.data.ProtoResPQ;
        if (resPQ.nonce != self.nonce) {
            self.status = .Failed;
            return GenError.Security;
        }
        self.server_nonce = resPQ.server_nonce;

        return d;
    }

    /// Receive data in plain text mode
    fn recvData(self: *AuthGen) !utils.Deserialized {
        const len = try self.transport.recvLen();

        const buf = try self.allocator.alloc(u8, len);
        defer self.allocator.free(buf);

        _ = try self.transport.recv(buf);

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
                return GenError.UnknownFingerprints;
            }

            var p: u64 = 0;
            var q: u64 = 0;

            // get the primes p and q from pq
            if (factorize.pq_factor(std.mem.readInt(u64, resPQ.pq[0..8], .big), &p, &q) != 1) {
                self.status = .Failed;
                return GenError.Security;
            }

            try std.Io.randomSecure(self.io, @ptrCast(&self.new_nonce));

            //

            var dcId: i32 = self.dcId;
            if (self.testMode)
                dcId += 10000;
            if (self.media)
                dcId = -dcId;

            var sbuf: [144]u8 = undefined;

            var pBytes: [4]u8 = undefined;
            var qBytes: [4]u8 = undefined;

            std.mem.writeInt(u32, &pBytes, @intCast(p), .big);
            std.mem.writeInt(u32, &qBytes, @intCast(q), .big);

            const innerData = tl.TL{ .ProtoPQInnerDataDc = &.{ .dc = @bitCast(dcId), .new_nonce = self.new_nonce, .nonce = self.nonce, .server_nonce = self.server_nonce, .p = &pBytes, .q = &qBytes, .pq = resPQ.pq } };
            var written = innerData.serialize(&sbuf);

            const bytes = try rsaPad(self.io, sbuf[0..written], self.public_key.?[0], self.public_key.?[1]);

            var req_dh: [500]u8 = undefined;

            const r = tl.TL{ .ProtoReqDHParams = &.{ .encrypted_data = &bytes, .nonce = self.nonce, .p = &pBytes, .q = &qBytes, .public_key_fingerprint = selectedFingerprint, .server_nonce = self.server_nonce } };
            written = r.serialize(&req_dh);

            try self.sendData(req_dh[0..written]);

            self.status = .ReqDH;
        }

        var key: [32]u8 = undefined;
        var iv: [32]u8 = undefined;

        const deser, const buf_deser = inner_data: {
            const d = try self.recvData();
            defer self.allocator.free(d.ptr);

            if (d.data != .ProtoServerDHParamsOk) {
                self.status = .Failed;
                return GenError.FailedReqDH;
            }

            const dhParamsOk = d.data.ProtoServerDHParamsOk;

            if (dhParamsOk.nonce != self.nonce) {
                self.status = .Failed;
                return GenError.Security;
            }

            if (dhParamsOk.server_nonce != self.server_nonce) {
                self.status = .Failed;
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

            _ = tl.TL.deserializeSize(dhParamsOk.encrypted_answer[20..], &size);

            const buf_deser = try self.allocator.alloc(u8, size);
            errdefer self.allocator.free(buf_deser);

            const deser = tl.TL.deserialize(dhParamsOk.encrypted_answer[20..], buf_deser);

            break :inner_data .{ deser[0], buf_deser };
        };
        defer self.allocator.free(buf_deser);

        if (deser != .ProtoServerDHInnerData) {
            self.status = .Failed;
            return GenError.FailedReqDH;
        }

        const dhInnerData = deser.ProtoServerDHInnerData;

        if (dhInnerData.nonce != self.nonce) {
            self.status = .Failed;
            return GenError.Security;
        }

        if (dhInnerData.server_nonce != self.server_nonce) {
            self.status = .Failed;
            return GenError.Security;
        }

        self.dhPrime = std.mem.readInt(u2048, dhInnerData.dh_prime[0..256], .big);
        self.gA = std.mem.readInt(u2048, dhInnerData.g_a[0..256], .big);
        try std.Io.randomSecure(self.io, @ptrCast(&self.b));

        var m = try Modulus.fromPrimitive(u2048, self.dhPrime);

        const x = try Modulus.Fe.fromPrimitive(u32, m, dhInnerData.g);

        const gB_m = try m.powWithEncodedPublicExponent(x, &self.b, .little);

        const gB = try gB_m.toPrimitive(u2048);

        rangeCheck(@intCast(dhInnerData.g), 1, (self.dhPrime - 1)) catch |err| {
            self.status = .Failed;
            return err;
        };
        rangeCheck(self.gA, 1, (self.dhPrime - 1)) catch |err| {
            self.status = .Failed;
            return err;
        };
        rangeCheck(@intCast(gB), 1, (self.dhPrime - 1)) catch |err| {
            self.status = .Failed;
            return err;
        };

        const safeRange = 1 << (2048 - 64);

        rangeCheck(self.gA, safeRange, (self.dhPrime - safeRange)) catch |err| {
            self.status = .Failed;
            return err;
        };

        rangeCheck(@intCast(gB), safeRange, (self.dhPrime - safeRange)) catch |err| {
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
        defer self.allocator.free(d.ptr);
        switch (d.data) {
            .ProtoDhGenOk => {
                var result = GeneratedAuthKey{
                    .authKey = undefined,
                    .first_salt = 0,
                };
                // TODO: maybe optimize this
                var newNonce: [32]u8 = undefined;
                var serverNonce: [16]u8 = undefined;
                std.mem.writeInt(u256, &newNonce, self.new_nonce, .little);
                std.mem.writeInt(u128, &serverNonce, self.server_nonce, .little);

                result.first_salt = std.mem.readInt(u64, newNonce[0..8], .little) ^ std.mem.readInt(u64, serverNonce[0..8], .little);

                var m = try Modulus.fromPrimitive(u2048, self.dhPrime);

                const x = try Modulus.Fe.fromPrimitive(u2048, m, self.gA);

                const key_m = try m.powWithEncodedPublicExponent(x, &self.b, .little);

                try key_m.toBytes(&result.authKey, .big);

                var hash: [20]u8 = undefined;
                std.crypto.hash.Sha1.hash(&result.authKey, &hash, .{});

                var hash2: [20]u8 = undefined;

                var digest = std.crypto.hash.Sha1.init(.{});
                digest.update(&newNonce);
                digest.update(&.{1});
                digest.update(hash[0..8]);
                digest.final(&hash2);

                const computed_hash = std.mem.readInt(u128, hash2[4..], .little);

                if (computed_hash != d.data.ProtoDhGenOk.new_nonce_hash1) {
                    self.status = .Failed;
                    return GenError.Security;
                }

                self.status = .Completed;
                return result;
            },
            .ProtoDhGenRetry => {
                // TODO: retry
                self.status = .Failed;
                return GenError.InvalidResponse;
            },
            else => {
                self.status = .Failed;
                return GenError.InvalidResponse;
            },
        }
    }
};

const Modulus = std.crypto.ff.Modulus(2048);

inline fn rangeCheck(val: u2048, min: u2048, max: u2048) !void {
    if (!(min < val and val < max)) {
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

/// Starts the auth key generation on the specified `transport`
pub fn generate(allocator: std.mem.Allocator, io: std.Io, transport: *Transport, dcId: u8, media: bool, test_mode: bool) !GeneratedAuthKey {
    var self = AuthGen{
        .allocator = allocator,
        .dcId = dcId,
        .media = media,
        .transport = transport,
        .testMode = test_mode,
        .io = io,
    };
    const req_pq = try self.reqPQ();
    defer self.allocator.free(req_pq.ptr);

    const td = req_pq.data;
    try self.reqDH(td.ProtoResPQ);

    const set_client_dh = try self.setClientDH();

    return set_client_dh;
}
