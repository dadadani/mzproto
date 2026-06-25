const std = @import("std");

const Modulus2048 = std.crypto.ff.Modulus(2048);

pub const default_rounds = 15;
const small_prime_limit = 100_000;

const small_primes = calculatePrimeNumbers(small_prime_limit);

pub fn calculatePrimeNumbers(comptime size: usize) std.StaticBitSet(size) {
    @setEvalBranchQuota(10_000_000);

    var sieve = std.StaticBitSet(size).full;
    if (size > 0) sieve.setValue(0, false);
    if (size > 1) sieve.setValue(1, false);
    if (size <= 2) return sieve;

    const last: usize = @intFromFloat(@sqrt(@as(f64, @floatFromInt(size - 1))));

    for (2..last + 1) |n| {
        if (!sieve.isSet(n)) continue;

        var i = n * n;
        while (i < size) : (i += n) {
            sieve.setValue(i, false);
        }
    }

    return sieve;
}

pub fn isProbablyPrime2048(io: std.Io, n: u2048, rounds: usize) std.Io.RandomSecureError!bool {
    if (n < 2) return false;
    if (n == 2 or n == 3) return true;
    if ((n & 1) == 0) return false;

    for (2..small_prime_limit) |prime| {
        if (!small_primes.isSet(prime)) continue;

        const p: u2048 = prime;
        if (n == p) return true;
        if (n % p == 0) return false;
    }

    const rounds_to_run = @max(rounds, 1);
    for (0..rounds_to_run) |_| {
        const base = try randomBase(io, n);
        if (!millerRabinRound2048(n, base)) return false;
    }
    return true;
}

fn randomBase(io: std.Io, n: u2048) std.Io.RandomSecureError!u2048 {
    const span = n - 3;
    const bits = @bitSizeOf(u2048) - @as(usize, @intCast(@clz(span)));

    while (true) {
        var bytes: [256]u8 = undefined;
        try std.Io.randomSecure(io, &bytes);

        var candidate = std.mem.readInt(u2048, &bytes, .big);
        if (bits < @bitSizeOf(u2048)) {
            const shift: std.math.Log2Int(u2048) = @intCast(@bitSizeOf(u2048) - bits);
            candidate >>= shift;
        }

        if (candidate < span) return candidate + 2;
    }
}

fn millerRabinRound2048(n: u2048, base: u2048) bool {
    std.debug.assert(n > 3);
    std.debug.assert((n & 1) == 1);
    std.debug.assert(base > 1 and base < n - 1);

    var d = n - 1;
    const s: std.math.Log2Int(u2048) = @intCast(@ctz(d));
    d >>= s;

    var d_bytes: [256]u8 = undefined;
    std.mem.writeInt(u2048, &d_bytes, d, .big);

    const modulus = Modulus2048.fromPrimitive(u2048, n) catch return false;
    const base_fe = Modulus2048.Fe.fromPrimitive(u2048, modulus, base) catch return false;
    const one = modulus.one();
    const n_minus_one = Modulus2048.Fe.fromPrimitive(u2048, modulus, n - 1) catch return false;

    var x = modulus.powWithEncodedPublicExponent(base_fe, &d_bytes, .big) catch return false;
    if (x.eql(one) or x.eql(n_minus_one)) return true;

    var i: usize = 1;
    while (i < s) : (i += 1) {
        x = modulus.sq(x);
        if (x.eql(n_minus_one)) return true;
        if (x.eql(one)) return false;
    }

    return false;
}

test isProbablyPrime2048 {
    const DH_PRIME_STANDARD = std.mem.readInt(u2048, &[_]u8{ 0xC7, 0x1C, 0xAE, 0xB9, 0xC6, 0xB1, 0xC9, 0x04, 0x8E, 0x6C, 0x52, 0x2F, 0x70, 0xF1, 0x3F, 0x73, 0x98, 0x0D, 0x40, 0x23, 0x8E, 0x3E, 0x21, 0xC1, 0x49, 0x34, 0xD0, 0x37, 0x56, 0x3D, 0x93, 0x0F, 0x48, 0x19, 0x8A, 0x0A, 0xA7, 0xC1, 0x40, 0x58, 0x22, 0x94, 0x93, 0xD2, 0x25, 0x30, 0xF4, 0xDB, 0xFA, 0x33, 0x6F, 0x6E, 0x0A, 0xC9, 0x25, 0x13, 0x95, 0x43, 0xAE, 0xD4, 0x4C, 0xCE, 0x7C, 0x37, 0x20, 0xFD, 0x51, 0xF6, 0x94, 0x58, 0x70, 0x5A, 0xC6, 0x8C, 0xD4, 0xFE, 0x6B, 0x6B, 0x13, 0xAB, 0xDC, 0x97, 0x46, 0x51, 0x29, 0x69, 0x32, 0x84, 0x54, 0xF1, 0x8F, 0xAF, 0x8C, 0x59, 0x5F, 0x64, 0x24, 0x77, 0xFE, 0x96, 0xBB, 0x2A, 0x94, 0x1D, 0x5B, 0xCD, 0x1D, 0x4A, 0xC8, 0xCC, 0x49, 0x88, 0x07, 0x08, 0xFA, 0x9B, 0x37, 0x8E, 0x3C, 0x4F, 0x3A, 0x90, 0x60, 0xBE, 0xE6, 0x7C, 0xF9, 0xA4, 0xA4, 0xA6, 0x95, 0x81, 0x10, 0x51, 0x90, 0x7E, 0x16, 0x27, 0x53, 0xB5, 0x6B, 0x0F, 0x6B, 0x41, 0x0D, 0xBA, 0x74, 0xD8, 0xA8, 0x4B, 0x2A, 0x14, 0xB3, 0x14, 0x4E, 0x0E, 0xF1, 0x28, 0x47, 0x54, 0xFD, 0x17, 0xED, 0x95, 0x0D, 0x59, 0x65, 0xB4, 0xB9, 0xDD, 0x46, 0x58, 0x2D, 0xB1, 0x17, 0x8D, 0x16, 0x9C, 0x6B, 0xC4, 0x65, 0xB0, 0xD6, 0xFF, 0x9C, 0xA3, 0x92, 0x8F, 0xEF, 0x5B, 0x9A, 0xE4, 0xE4, 0x18, 0xFC, 0x15, 0xE8, 0x3E, 0xBE, 0xA0, 0xF8, 0x7F, 0xA9, 0xFF, 0x5E, 0xED, 0x70, 0x05, 0x0D, 0xED, 0x28, 0x49, 0xF4, 0x7B, 0xF9, 0x59, 0xD9, 0x56, 0x85, 0x0C, 0xE9, 0x29, 0x85, 0x1F, 0x0D, 0x81, 0x15, 0xF6, 0x35, 0xB1, 0x05, 0xEE, 0x2E, 0x4E, 0x15, 0xD0, 0x4B, 0x24, 0x54, 0xBF, 0x6F, 0x4F, 0xAD, 0xF0, 0x34, 0xB1, 0x04, 0x03, 0x11, 0x9C, 0xD8, 0xE3, 0xB9, 0x2F, 0xCC, 0x5B }, .big);

    try std.testing.expect(try isProbablyPrime2048(std.testing.io, DH_PRIME_STANDARD, default_rounds));
}

test "Miller-Rabin round rejects composites" {
    try std.testing.expect(millerRabinRound2048(97, 5));
    try std.testing.expect(!millerRabinRound2048(221, 38));
}

test "calculatePrimeNumbers marks primes" {
    const primes = comptime calculatePrimeNumbers(32);

    try std.testing.expect(primes.isSet(2));
    try std.testing.expect(primes.isSet(3));
    try std.testing.expect(primes.isSet(29));
    try std.testing.expect(!primes.isSet(0));
    try std.testing.expect(!primes.isSet(1));
    try std.testing.expect(!primes.isSet(9));
    try std.testing.expect(!primes.isSet(21));
}

test "isProbablyPrime2048 handles small values before entropy" {
    try std.testing.expect(try isProbablyPrime2048(std.Io.failing, 503, default_rounds));
    try std.testing.expect(!try isProbablyPrime2048(std.Io.failing, 9, default_rounds));
    try std.testing.expect(!try isProbablyPrime2048(std.Io.failing, 221, default_rounds));
}
