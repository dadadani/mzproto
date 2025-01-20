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
    UnknownFingerprints,
} || std.mem.Allocator.Error;

pub const GeneratedAuthKey = struct {};

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
        Failed,
    } = .Idle,

    nonce: i128 = 0,
    server_nonce: i128 = 0,
    new_nonce: i256 = 0,
    public_key: ?struct { u2048, u64 } = null,

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

        const Modulus = std.crypto.ff.Modulus(2048);

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
        std.debug.print("Received data {d}\n", .{data});
        const self: *AuthGen = @constCast(@ptrCast(@alignCast(ptr.?)));

        if (data.len == 4) {
            std.debug.print("Received invalid response\n", .{});
            const code = std.mem.readInt(i32, data[0..4], .little);
            std.debug.print("Code: {d}\n", .{code});
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

                std.debug.print("p = {d}, q = {d}\n", .{ p, q });

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
                std.debug.print("innerData: {}\n", .{innerData});
                var written = innerData.serialize(&sbuf);

                const bytes = rsaPad(sbuf[0..written], self.public_key.?[0], self.public_key.?[1]);

                var reqDH: [500]u8 = undefined;

                const r = tl.ProtoReqDHParams{ .encrypted_data = &bytes, .nonce = self.nonce, .p = &pBytes, .q = &qBytes, .public_key_fingerprint = selectedFingerprint, .server_nonce = self.server_nonce };
                written = r.serialize(&reqDH);
                std.debug.print("Sending reqDH {d}\n", .{written});

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

                std.debug.print("Received DH params ok {}\n", .{dhParamsOk});

                var key: [32]u8 = undefined;

                {
                    var tmp: [48]u8 = undefined;
                    std.mem.writeInt(i256, tmp[0..32], self.new_nonce, .little);
                    std.mem.writeInt(i128, tmp[32..48], dhParamsOk.server_nonce, .little);
                    std.debug.print("new_nonce: {d}\n", .{tmp[0..32]});
                    std.debug.print("server_nonce: {d}\n", .{tmp[32..48]});
                    std.crypto.hash.Sha1.hash(&tmp, key[0..20], .{});

                    var tmp2: [20]u8 = undefined;
                    std.mem.writeInt(i128, tmp[0..16], dhParamsOk.server_nonce, .little);
                    std.mem.writeInt(i256, tmp[16..48], self.new_nonce, .little);
                    std.crypto.hash.Sha1.hash(&tmp, &tmp2, .{});
                    @memcpy(key[20..32], tmp2[0..12]);
                }

                std.debug.print("Key: {d}\n", .{key});

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

                std.debug.print("IV: {d}\n", .{iv});

                ige(dhParamsOk.encrypted_answer, @constCast(dhParamsOk.encrypted_answer), &key, &iv, false);

                var deserialized: [768]u8 = undefined;

                var cursor: usize = 0;
                var written: usize = 0;

                const deser = tl.TL.deserialize(dhParamsOk.encrypted_answer[20..], &deserialized, &cursor, &written);
                
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

                std.debug.print("Decrypted: {}\nwritten {d}\n", .{ deser, written });
            },
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
