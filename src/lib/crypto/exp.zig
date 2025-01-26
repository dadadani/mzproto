fn bitLength(num: u4096) u12 {
    var result: u12 = 0;
    var n = num;
    while (n != 0) : (n >>= 1) {
        result += 1;
    }
    return result;
}


// A very dumb implementation of the Barrett reduction algorithm.
// At least, it's somewhat better than doing the modular exponentiation without any reduction.
const BarrettContext = struct {
    modulus: u4096,
    mu: u4096,
    k: u12,

    pub fn init(num: u4096) BarrettContext {
        const mu = (@as(u8192, 1) << (2 * @as(u13, bitLength(num)))) / num;
        return .{
            .modulus = num,
            .k = bitLength(num),
            .mu = @intCast(mu),
        };
    }
};

pub fn barrettMul(a: u4096, b: u4096, ctx: *const BarrettContext) u4096 {
    const x = a * b;

    const q = ((x >> ctx.k) * ctx.mu) >> ctx.k;

    var r = x - q * ctx.modulus;

    while (r >= ctx.modulus) {
        r -= ctx.modulus;
    }

    return r;
}

pub fn modpow(nn: u2048, ee: u2048, mm: u2048) u4096 {
    if (mm == 1) {
        return 0;
    }

    var n: u4096 = nn;
    var e: u4096 = ee;
    var result: u4096 = 1;
    const ctx = BarrettContext.init(mm);

    n = barrettMul(n, 1, &ctx); // n = n % mm
    while (e > 0) {
        if (e % 2 == 1) {
            result = barrettMul(result, n, &ctx); // result = (result * n) % mm
        }

        e >>= 1;
        n = barrettMul(n, n, &ctx); // n = (n * n) % mm
    }
    return result;
}
