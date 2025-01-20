const std = @import("std");

pub fn ige(src: []const u8, dest: []u8, key: *const [32]u8, iv: *const [32]u8, comptime doEncrypt: bool) void {
    std.debug.assert(src.len % 16 == 0);

    var cipher = if (doEncrypt)
        std.crypto.core.aes.Aes256.initEnc(key.*)
    else
        std.crypto.core.aes.Aes256.initDec(key.*);

    var iv1: [16]u8 = undefined;
    var iv2: [16]u8 = undefined;

    if (doEncrypt) {
        @memcpy(&iv1, iv[0..16]);
        @memcpy(&iv2, iv[16..32]);
    } else {
        @memcpy(&iv2, iv[0..16]);
        @memcpy(&iv1, iv[16..32]);
    }

    var i: usize = 0;

    while (i < src.len) : (i += 16) {
        const chunk = src[i .. i + 16];

        for (0..16) |j| {
            iv1[j] ^= chunk[j];
        }

        if (doEncrypt) {
            cipher.encrypt(&iv1, &iv1);
        } else {
            cipher.decrypt(&iv1, &iv1);
        }

        for (0..16) |j| {
            iv1[j] = iv1[j] ^ iv2[j];
        }

        @memcpy(&iv2, chunk);
        @memcpy(dest[i .. i + 16], &iv1);
    }
}

test "ige encryption & decryption" {
    const text = "helloworldasfsdf";
    var dest = [_]u8{0} ** text.len;

    var key: [32]u8 = undefined;
    var iv: [32]u8 = undefined;

    std.crypto.random.bytes(&key);
    std.crypto.random.bytes(&iv);

    ige(text, &dest, &key, &iv, true);

    //var decrypted = [_]u8{0} ** text.len;

    ige(&dest, &dest, &key, &iv, false);

    try std.testing.expectEqualStrings(text, &dest);
}
