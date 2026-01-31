const std = @import("std");

const RSAPublicKey = @This();

const serializeString = @import("../tl/base.zig").serializeString;

modulus: u2048,
exponent: u64,
fingerprint: u64,

fn genFingerprint(self: *const RSAPublicKey) u64 {
    var modulus_bytes: [256]u8 = undefined;
    std.mem.writeInt(u2048, &modulus_bytes, self.modulus, .big);

    var mod_start: usize = 0;
    while (mod_start < modulus_bytes.len and modulus_bytes[mod_start] == 0) : (mod_start += 1) {}
    const mod_slice = modulus_bytes[mod_start..];
    var tl_modulus_bytes: [512]u8 = undefined;
    const tl_modulus_bytes_size = serializeString(mod_slice, &tl_modulus_bytes);

    var exponent_bytes: [8]u8 = undefined;
    std.mem.writeInt(u64, &exponent_bytes, self.exponent, .big);

    var exp_start: usize = 0;
    while (exp_start < exponent_bytes.len and exponent_bytes[exp_start] == 0) : (exp_start += 1) {}
    const exp_slice = exponent_bytes[exp_start..];

    var tl_exponent_bytes: [16]u8 = undefined;
    const tl_exponent_size = serializeString(exp_slice, &tl_exponent_bytes);

    var digest = std.crypto.hash.Sha1.init(.{});
    digest.update(tl_modulus_bytes[0..tl_modulus_bytes_size]);
    digest.update(tl_exponent_bytes[0..tl_exponent_size]);

    return std.mem.readInt(u64, digest.finalResult()[12..20], .little);
}

const RSAPublicKeyInternal = struct {
    modulus: std.crypto.codecs.asn1.Opaque(.{ .number = .integer, .constructed = false, .class = .universal }),
    exponent: u64,

    pub fn modulusBytes(self: RSAPublicKeyInternal) []const u8 {
        var bytes = self.modulus.bytes;
        // Skip leading zero byte if present (used for sign in ASN.1)
        if (bytes.len > 0 and bytes[0] == 0) {
            bytes = bytes[1..];
        }
        return bytes;
    }
};

const Error = error{InvalidStructure};

pub fn parseRSAPublicKey(data: []const u8) !RSAPublicKey {
    if (!std.mem.startsWith(u8, data, "-----BEGIN RSA PUBLIC KEY-----\n")) {
        return Error.InvalidStructure;
    }
    if (!std.mem.endsWith(u8, data, "\n-----END RSA PUBLIC KEY-----")) {
        return Error.InvalidStructure;
    }

    const start = std.mem.indexOf(u8, data, "\n").? + 1;
    const end = std.mem.lastIndexOf(u8, data, "\n-----END").?;
    const base64_content = data[start..end];

    const base64 = std.base64.standard.decoderWithIgnore("\n");

    var der_bytes: [1024]u8 = undefined;
    const decoded = try base64.decode(&der_bytes, base64_content);

    const der = std.crypto.codecs.asn1.der;
    const key = try der.decode(RSAPublicKeyInternal, der_bytes[0..decoded]);

    var self: RSAPublicKey = undefined;

    self.exponent = key.exponent;
    self.modulus = std.mem.readInt(u2048, @ptrCast(key.modulusBytes()[0..256]), .big);
    self.fingerprint = self.genFingerprint();

    return self;
}

test {
    const pem =
        \\-----BEGIN RSA PUBLIC KEY-----
        \\MIIBCgKCAQEA6LszBcC1LGzyr992NzE0ieY+BSaOW622Aa9Bd4ZHLl+TuFQ4lo4g
        \\5nKaMBwK/BIb9xUfg0Q29/2mgIR6Zr9krM7HjuIcCzFvDtr+L0GQjae9H0pRB2OO
        \\62cECs5HKhT5DZ98K33vmWiLowc621dQuwKWSQKjWf50XYFw42h21P2KXUGyp2y/
        \\+aEyZ+uVgLLQbRA1dEjSDZ2iGRy12Mk5gpYc397aYp438fsJoHIgJ2lgMv5h7WY9
        \\t6N/byY9Nw9p21Og3AoXSL2q/2IJ1WRUhebgAdGVMlV1fkuOQoEzR7EdpqtQD9Cs
        \\5+bfo3Nhmcyvk5ftB0WkJ9z6bNZ7yxrP8wIDAQAB
        \\-----END RSA PUBLIC KEY-----
    ;

    const key = try parseRSAPublicKey(pem);

    try std.testing.expectEqual(0xe8bb3305c0b52c6cf2afdf7637313489e63e05268e5badb601af417786472e5f93b85438968e20e6729a301c0afc121bf7151f834436f7fda680847a66bf64accec78ee21c0b316f0edafe2f41908da7bd1f4a5107638eeb67040ace472a14f90d9f7c2b7def99688ba3073adb5750bb02964902a359fe745d8170e36876d4fd8a5d41b2a76cbff9a13267eb9580b2d06d10357448d20d9da2191cb5d8c93982961cdfdeda629e37f1fb09a0722027696032fe61ed663db7a37f6f263d370f69db53a0dc0a1748bdaaff6209d5645485e6e001d1953255757e4b8e42813347b11da6ab500fd0ace7e6dfa3736199ccaf9397ed0745a427dcfa6cd67bcb1acff3, key.modulus);
    try std.testing.expectEqual(@as(u64, 65537), key.exponent);

    try std.testing.expectEqual(0xd09d1d85de64fd85, key.fingerprint());
}
