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

const std = @import("std");

// Special thanks to gramme.rs for the initial implementation of this function

pub fn factorize(pq: u64) struct { u64, u64 } {
    const ATTEMPTS = [5]u64{ 43, 47, 53, 59, 61 };
    for (ATTEMPTS) |attempt| {
        const c = attempt * (pq / 103);
        const p, const q = factorizeWithParam(pq, c);

        if (pq != 1) {
            return .{ p, q };
        }
    }
    @panic("Failed to factorize pq");
}

fn absSub(a: u128, b: u128) u128 {
    return @max(a, b) - @min(a, b);
}

fn modPow(nn: u128, ee: u128, m: u128) u128 {
    if (m == 1) {
        return 0;
    }
    var n = nn;
    var e = ee;

    var result: u128 = 1;
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

fn factorizeWithParam(pq: u64, c: u64) struct { u64, u64 } {
    if (pq % 2 == 0) {
        return .{ 2, pq / 2 };
    }

    var y: u128 = 3 * (pq / 7);
    const m = 7 * (pq / 13);
    var g: u128 = 1;
    var r: u128 = 1;
    var q: u128 = 1;
    var x: u128 = 0;
    var ys: u128 = 0;

    var i: u128 = 0;

    while (g == 1) {
        x = y;

        i = 0;
        while (i < r) {
            y = (modPow(y, 2, pq) + c) % pq;
            i += 1;
        }

        var k: u128 = 0;
        while (k < r and g == 1) {
            ys = y;
            for (0..@min(m, (r - k))) |_| {
                y = (modPow(y, 2, pq) + c) % pq;
                q = (q * absSub(x, y)) % pq;
            }

            g = std.math.gcd(q, pq);
            k += m;
        }

        r *= 2;
    }

    if (g == pq) {
        while (true) {
            ys = (modPow(ys, 2, pq) + c) % pq;
            g = std.math.gcd(absSub(x, ys), pq);
            if (g > 1) {
                break;
            }
        }
    }

    const p: u64 = @intCast(g);
    const qq: u64 = @intCast(pq / g);
    return .{ @min(p, qq), @max(p, qq) };
}

test "factorize 1" {
    const pq = factorize(1470626929934143021);
    try std.testing.expect(pq[0] == 1206429347);
    try std.testing.expect(pq[1] == 1218991343);
}

test "factorize 2" {
    const pq = factorize(2363612107535801713);
    try std.testing.expect(pq[0] == 1518968219);
    try std.testing.expect(pq[1] == 1556064227);
}

test "factorize 3" {
    const pq = factorize(2804275833720261793);
    try std.testing.expect(pq[0] == 1555252417);
    try std.testing.expect(pq[1] == 1803100129);
}
