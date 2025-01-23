const tl = @import("../tl//api.zig");
const std = @import("std");
const factorize = @import("../crypto/factorize.zig").factorize;
const TransportProvider = @import("../network/transport_provider.zig").TransportProvider;
const ConnectionEvent = @import("../network/network_data_provider.zig").ConnectionEvent;
const RecvDataCallback = @import("../network/transport_provider.zig").RecvDataCallback;
const ige = @import("../crypto/ige.zig").ige;
pub const GenError = error{
    ConnectionClosed,
    InvalidResponse,
    Security,
    FailedResPQ,
    FailedReqDH,
    FailedSetClientDH,
    UnknownFingerprints,
} || std.mem.Allocator.Error;

pub const GeneratedAuthKey = struct {
    authKey: [256]u8,
    firstSalt: u64,
};

fn getPublicKey(id: u64) ?struct { u2048, u64 } {
    return switch (id) {
        0xd09d1d85de64fd85 => .{ 0xE8BB3305C0B52C6CF2AFDF7637313489E63E05268E5BADB601AF417786472E5F93B85438968E20E6729A301C0AFC121BF7151F834436F7FDA680847A66BF64ACCEC78EE21C0B316F0EDAFE2F41908DA7BD1F4A5107638EEB67040ACE472A14F90D9F7C2B7DEF99688BA3073ADB5750BB02964902A359FE745D8170E36876D4FD8A5D41B2A76CBFF9A13267EB9580B2D06D10357448D20D9DA2191CB5D8C93982961CDFDEDA629E37F1FB09A0722027696032FE61ED663DB7A37F6F263D370F69DB53A0DC0A1748BDAAFF6209D5645485E6E001D1953255757E4B8E42813347B11DA6AB500FD0ACE7E6DFA3736199CCAF9397ED0745A427DCFA6CD67BCB1ACFF3, 0x010001 },
        0xb25898df208d2603 => .{ 0xC8C11D635691FAC091DD9489AEDCED2932AA8A0BCEFEF05FA800892D9B52ED03200865C9E97211CB2EE6C7AE96D3FB0E15AEFFD66019B44A08A240CFDD2868A85E1F54D6FA5DEAA041F6941DDF302690D61DC476385C2FA655142353CB4E4B59F6E5B6584DB76FE8B1370263246C010C93D011014113EBDF987D093F9D37C2BE48352D69A1683F8F6E6C2167983C761E3AB169FDE5DAAA12123FA1BEAB621E4DA5935E9C198F82F35EAE583A99386D8110EA6BD1ABB0F568759F62694419EA5F69847C43462ABEF858B4CB5EDC84E7B9226CD7BD7E183AA974A712C079DDE85B9DC063B8A5C08E8F859C0EE5DCD824C7807F20153361A7F63CFD2A433A1BE7F5, 0x010001 },
        else => null,
    };
}

const Deserialized = struct {
    ptr: []u8,
    data: tl.TL,
};

pub const AuthGen = struct {
    allocator: std.mem.Allocator,
    connection: TransportProvider,
    dcId: u8,
    testMode: bool,
    media: bool,
    callback: *const fn (*const anyopaque, GenError!GeneratedAuthKey) void,
    user_data: *const anyopaque,
    status: enum {
        Idle,
        ReqPQ,
        ReqDH,
        setClientDH,
        Failed,
        Completed,
    } = .Idle,

    nonce: i128 = 0,
    server_nonce: i128 = 0,
    new_nonce: i256 = 0,
    public_key: ?struct { u2048, u64 } = null,
    gA: u2048 = 0,
    b: u2048 = 0,
    dhPrime: u2048 = 0,

    const Modulus = std.crypto.ff.Modulus(2048);

    fn deserialize(self: *AuthGen, data: []const u8) std.mem.Allocator.Error!Deserialized {
        const len = std.mem.readInt(u32, data[16..20], .little);
        var written: usize = 0;
        var cursor: usize = 0;

        tl.TL.deserializedSize(data[20 .. 20 + len], &cursor, &written);
        const dest = try self.allocator.alloc(u8, written);

        written = 0;
        cursor = 0;

        return .{ .ptr = dest, .data = tl.TL.deserialize(data[20 .. 20 + len], dest, &cursor, &written) };
    }

    fn onEvent(event: ConnectionEvent, ptr: ?*const anyopaque) void {
        const self: *AuthGen = @constCast(@ptrCast(@alignCast(ptr.?)));
        switch (event) {
            ConnectionEvent.Connected => {},
            ConnectionEvent.Disconnected => {
                self.callback(self.user_data, GenError.ConnectionClosed);
            },
        }
    }
    // This is needed for now for the dhPrime part, because std.crypto.ff often returns "NonCanonical"
    // TODO: replace this with a proper, optimized implementation
    fn modPow(nn: u4096, ee: u4096, m: u4096) u4096 {
        if (m == 1) {
            return 0;
        }
        var n = nn;
        var e = ee;

        var result: u4096 = 1;
        n = nn % m;
        while (e > 0) {
            if (e % 2 == 1) {
                result = (result * n) % m;
            }

            e >>= 1;

            n = (n * n) % m;
        }
        return result;
    }

    inline fn rangeCheck(val: u2048, min: u2048, max: u2048) !void {
        if (!(min < val and val < max)) {
            return GenError.Security;
        }
    }

    fn rsaPad(src: []const u8, m: u2048, e: u64) [256]u8 {
        std.debug.assert(src.len <= 144);

        var result: [256]u8 = undefined;

        var temp_key: [32]u8 = undefined;
        std.crypto.random.bytes(&temp_key);
        @memcpy(result[0..32], &temp_key);

        {
            const data_with_padding = result[32 .. 32 + 192];
            @memcpy(data_with_padding[0..src.len], src);
            std.crypto.random.bytes(data_with_padding[src.len..192]);
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

        const encrypted_int = std.mem.readInt(u2048, &result, .big);

        // If `key_aes_encryped` is greater than the RSA modulus, we need to restart from the beginning
        if (encrypted_int > m) {
            return rsaPad(src, m, e);
        }

        const a = Modulus.fromPrimitive(u2048, m) catch {
            @panic("fromPrimitive failed");
        };

        const b = Modulus.Fe.fromPrimitive(u64, a, e) catch {
            @panic("fromPrimitive failed");
        };

        const c = Modulus.Fe.fromPrimitive(u2048, a, encrypted_int) catch {
            @panic("fromPrimitive failed");
        };

        const rsa = a.powPublic(c, b) catch {
            @panic("powPublic failed");
        };

        rsa.toBytes(&result, .big) catch {
            @panic("toBytes failed");
        };

        return result;
    }

    fn onData(data: []u8, ptr: ?*const anyopaque) void {
        const self: *AuthGen = @constCast(@ptrCast(@alignCast(ptr.?)));

        if (data.len == 4) {
            //const code = std.mem.readInt(i32, data[0..4], .little);
            self.status = .Failed;
            self.callback(self.user_data, GenError.InvalidResponse);
            return;
        }

        const d = self.deserialize(data) catch |err| {
            self.status = .Failed;
            self.callback(self.user_data, err);
            return;
        };
        defer self.allocator.free(d.ptr);

        switch (self.status) {
            .Idle => {},
            .ReqPQ => {
                if (d.data != .ProtoResPQ) {
                    self.status = .Failed;
                    self.callback(self.user_data, GenError.FailedResPQ);
                    return;
                }
                const resPQ = d.data.ProtoResPQ;
                if (resPQ.nonce != self.nonce) {
                    self.status = .Failed;
                    self.callback(self.user_data, GenError.Security);
                    return;
                }
                self.server_nonce = resPQ.server_nonce;

                // Find a public key to use

                self.public_key = null;

                var selectedFingerprint: i64 = 0;

                for (resPQ.server_public_key_fingerprints) |fingerprint| {
                    if (getPublicKey(@bitCast(fingerprint))) |k| {
                        self.public_key = k;
                        selectedFingerprint = fingerprint;
                        break;
                    }
                }

                if (self.public_key == null) {
                    self.status = .Failed;
                    self.callback(self.user_data, GenError.UnknownFingerprints);
                    return;
                }

                // calulate factors from pq
                const p, const q = factorize(std.mem.readInt(u64, resPQ.pq[0..8], .big));

                self.new_nonce = std.crypto.random.int(i256);

                //

                var dcId: i16 = self.dcId;
                if (self.testMode)
                    dcId += 10000;
                if (self.media)
                    dcId = -dcId;

                var sbuf: [144]u8 = undefined;

                var pBytes: [4]u8 = undefined;
                var qBytes: [4]u8 = undefined;

                std.mem.writeInt(u32, &pBytes, @intCast(p), .big);
                std.mem.writeInt(u32, &qBytes, @intCast(q), .big);

                const innerData = tl.ProtoPQInnerDataDc{ .dc = dcId, .new_nonce = self.new_nonce, .nonce = self.nonce, .server_nonce = self.server_nonce, .p = &pBytes, .q = &qBytes, .pq = resPQ.pq };
                var written = innerData.serialize(&sbuf);

                const bytes = rsaPad(sbuf[0..written], self.public_key.?[0], self.public_key.?[1]);

                var reqDH: [500]u8 = undefined;

                const r = tl.ProtoReqDHParams{ .encrypted_data = &bytes, .nonce = self.nonce, .p = &pBytes, .q = &qBytes, .public_key_fingerprint = selectedFingerprint, .server_nonce = self.server_nonce };
                written = r.serialize(&reqDH);

                self.sendData(reqDH[0..written]) catch |err| {
                    self.status = .Failed;
                    self.callback(self.user_data, err);
                };

                self.status = .ReqDH;
            },
            .ReqDH => {
                if (d.data != .ProtoServerDHParamsOk) {
                    self.status = .Failed;
                    self.callback(self.user_data, GenError.FailedReqDH);
                    return;
                }

                const dhParamsOk = d.data.ProtoServerDHParamsOk;

                if (dhParamsOk.nonce != self.nonce) {
                    self.status = .Failed;
                    self.callback(self.user_data, GenError.Security);
                    return;
                }

                if (dhParamsOk.server_nonce != self.server_nonce) {
                    self.status = .Failed;
                    self.callback(self.user_data, GenError.Security);
                    return;
                }

                var key: [32]u8 = undefined;

                {
                    var tmp: [48]u8 = undefined;
                    std.mem.writeInt(i256, tmp[0..32], self.new_nonce, .little);
                    std.mem.writeInt(i128, tmp[32..48], dhParamsOk.server_nonce, .little);
                    std.crypto.hash.Sha1.hash(&tmp, key[0..20], .{});

                    var tmp2: [20]u8 = undefined;
                    std.mem.writeInt(i128, tmp[0..16], dhParamsOk.server_nonce, .little);
                    std.mem.writeInt(i256, tmp[16..48], self.new_nonce, .little);
                    std.crypto.hash.Sha1.hash(&tmp, &tmp2, .{});
                    @memcpy(key[20..32], tmp2[0..12]);
                }

                var iv: [32]u8 = undefined;
                {
                    //tmp_aes_iv := substr (SHA1(server_nonce + new_nonce), 12, 8) + SHA1(new_nonce + new_nonce) + substr (new_nonce, 0, 4);
                    var tmp: [80]u8 = undefined;

                    std.mem.writeInt(i128, tmp[0..16], dhParamsOk.server_nonce, .little);
                    std.mem.writeInt(i256, tmp[16..48], self.new_nonce, .little);
                    std.crypto.hash.Sha1.hash(tmp[0..48], iv[0..20], .{});
                    @memcpy(iv[0..8], iv[12..20]);

                    std.mem.writeInt(i256, tmp[0..32], self.new_nonce, .little);
                    std.mem.writeInt(i256, tmp[32..64], self.new_nonce, .little);
                    std.crypto.hash.Sha1.hash(tmp[0..64], iv[8..28], .{});

                    @memcpy(iv[28..32], tmp[0..4]);
                }

                {
                    var tmp: [32]u8 = undefined;
                    var hash = std.crypto.hash.Sha1.init(.{});

                    std.mem.writeInt(i256, &tmp, self.new_nonce, .little);

                    hash.update(&tmp);
                    hash.update(&tmp);

                    hash.final(iv[8..28]);
                    @memcpy(iv[28..32], tmp[0..4]);
                }

                ige(dhParamsOk.encrypted_answer, @constCast(dhParamsOk.encrypted_answer), &key, &iv, false);

                var cursor: usize = 0;
                var written: usize = 0;

                tl.TL.deserializedSize(dhParamsOk.encrypted_answer[20..], &cursor, &written);

                const bufDeser = self.allocator.alloc(u8, written) catch |err| {
                    self.status = .Failed;
                    self.callback(self.user_data, err);
                    return;
                };
                defer self.allocator.free(bufDeser);

                cursor = 0;
                written = 0;

                const deser = tl.TL.deserialize(dhParamsOk.encrypted_answer[20..], bufDeser, &cursor, &written);

                if (deser != .ProtoServerDHInnerData) {
                    self.status = .Failed;
                    self.callback(self.user_data, GenError.FailedReqDH);
                    return;
                }

                const dhInnerData = deser.ProtoServerDHInnerData;

                if (dhInnerData.nonce != self.nonce) {
                    self.status = .Failed;
                    self.callback(self.user_data, GenError.Security);
                    return;
                }

                if (dhInnerData.server_nonce != self.server_nonce) {
                    self.status = .Failed;
                    self.callback(self.user_data, GenError.Security);
                    return;
                }

                self.dhPrime = std.mem.readInt(u2048, dhInnerData.dh_prime[0..256], .big);
                self.gA = std.mem.readInt(u2048, dhInnerData.g_a[0..256], .big);
                self.b = std.crypto.random.int(u2048);

                const gB = modPow(@intCast(dhInnerData.g), self.b, self.dhPrime);

                rangeCheck(@intCast(dhInnerData.g), 1, (self.dhPrime - 1)) catch |err| {
                    self.status = .Failed;
                    self.callback(self.user_data, err);
                    return;
                };
                rangeCheck(self.gA, 1, (self.dhPrime - 1)) catch |err| {
                    self.status = .Failed;
                    self.callback(self.user_data, err);
                    return;
                };
                rangeCheck(@intCast(gB), 1, (self.dhPrime - 1)) catch |err| {
                    self.status = .Failed;
                    self.callback(self.user_data, err);
                    return;
                };

                const safeRange = 1 << (2048 - 64);

                rangeCheck(self.gA, safeRange, (self.dhPrime - safeRange)) catch |err| {
                    self.status = .Failed;
                    self.callback(self.user_data, err);
                    return;
                };

                rangeCheck(@intCast(gB), safeRange, (self.dhPrime - safeRange)) catch |err| {
                    self.status = .Failed;
                    self.callback(self.user_data, err);
                    return;
                };

                var gbBytes: [256]u8 = undefined;
                std.mem.writeInt(u2048, &gbBytes, @intCast(gB), .big);

                const dhClientInnerData = tl.ProtoClientDHInnerData{ .nonce = self.nonce, .server_nonce = self.server_nonce, .retry_id = 0, .g_b = &gbBytes };

                var divisiblePadding: u8 = 0;
                const serSize = dhClientInnerData.serializedSize();

                while ((20 + serSize + divisiblePadding) % 16 != 0) {
                    divisiblePadding += 1;
                }

                const bufSer = self.allocator.alloc(u8, 20 + serSize + divisiblePadding) catch |err| {
                    self.status = .Failed;
                    self.callback(self.user_data, err);
                    return;
                };
                defer self.allocator.free(bufSer);

                written = dhClientInnerData.serialize(bufSer[20 .. 20 + serSize]);

                std.crypto.random.bytes(bufSer[20 + written .. 20 + written + divisiblePadding]);
                std.crypto.hash.Sha1.hash(bufSer[20 .. 20 + written], bufSer[0..20], .{});

                ige(bufSer, bufSer, &key, &iv, true);

                const setDH = tl.ProtoSetClientDHParams{ .nonce = self.nonce, .server_nonce = self.server_nonce, .encrypted_data = bufSer[0 .. 20 + written + divisiblePadding] };

                const bufSer2 = self.allocator.alloc(u8, setDH.serializedSize()) catch |err| {
                    self.status = .Failed;
                    self.callback(self.user_data, err);
                    return;
                };
                defer self.allocator.free(bufSer2);

                written = setDH.serialize(bufSer2);

                self.sendData(bufSer2[0..written]) catch |err| {
                    self.status = .Failed;
                    self.callback(self.user_data, err);
                };

                self.status = .setClientDH;
            },
            .setClientDH => {
                switch (d.data) {
                    .ProtoDhGenOk => {
                        var result = GeneratedAuthKey{
                            .authKey = undefined,
                            .firstSalt = 0,
                        };
                        // TODO: maybe optimize this
                        var newNonce: [32]u8 = undefined;
                        var serverNonce: [16]u8 = undefined;
                        std.mem.writeInt(i256, &newNonce, self.new_nonce, .little);
                        std.mem.writeInt(i128, &serverNonce, self.server_nonce, .little);

                        result.firstSalt = std.mem.readInt(u64, result.authKey[0..8], .little) ^ std.mem.readInt(u64, serverNonce[0..8], .little);

                        const key = modPow(self.gA, self.b, self.dhPrime);

                        std.mem.writeInt(u2048, &result.authKey, @intCast(key), .big);

                        var hash: [20]u8 = undefined;
                        std.crypto.hash.Sha1.hash(&result.authKey, &hash, .{});

                        var hash2: [20]u8 = undefined;
                        var hashData: [32 + 1 + 8]u8 = undefined;

                        @memcpy(hashData[0..32], &newNonce);
                        hashData[32] = 1;
                        @memcpy(hashData[33..41], hash[0..8]);

                        std.crypto.hash.Sha1.hash(&hashData, &hash2, .{});

                        const computed_hash = std.mem.readInt(i128, hash2[4..], .little);

                        if (computed_hash != d.data.ProtoDhGenOk.new_nonce_hash1) {
                            self.status = .Failed;
                            self.callback(self.user_data, GenError.Security);
                            return;
                        }

                        self.status = .Completed;
                        self.callback(self.user_data, result);
                    },
                    .ProtoDhGenRetry => {
                        // TODO: retry
                        self.status = .Failed;
                        self.callback(self.user_data, GenError.FailedSetClientDH);
                    },
                    else => {
                        self.status = .Failed;
                        self.callback(self.user_data, GenError.FailedSetClientDH);
                    },
                }
            },
            .Completed => {},
            .Failed => {},
        }
    }

    fn sendData(self: *AuthGen, data: []const u8) !void {
        const buf = try self.allocator.alloc(u8, @sizeOf(i64) + @sizeOf(i64) + @sizeOf(i32) + data.len);
        defer self.allocator.free(buf);

        @memcpy(buf[0..8], &[_]u8{
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
        });
        std.mem.writeInt(i64, buf[8..16], std.time.milliTimestamp() << 32, .little);
        std.mem.writeInt(i32, buf[16..20], @intCast(data.len), .little);
        @memcpy(buf[20..], data);
        self.connection.sendData(buf);
    }

    pub fn start(self: *AuthGen) void {
        self.connection.setUserData(self);
        self.connection.setRecvEventCallback(onEvent);
        self.connection.setRecvDataCallback(onData);

        self.status = .ReqPQ;

        self.nonce = std.crypto.random.int(i128);
        var data: [tl.ProtoReqPqMulti.serializedSize(&tl.ProtoReqPqMulti{ .nonce = 0 })]u8 = undefined;
        const written = tl.ProtoReqPqMulti.serialize(&.{ .nonce = self.nonce }, &data);

        self.sendData(data[0..written]) catch |err| {
            self.status = .Failed;
            self.callback(self.user_data, err);
        };
    }
};
