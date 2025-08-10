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

const RandomState = struct {
    state: u64 = 0xDEADBEEFCAFEBABE,

    pub fn next(self: *RandomState) u64 {
        var x = self.state;
        x ^= x >> 12;
        x ^= x << 25;
        x ^= x >> 27;
        self.state = x;
        return x *% 0x2545F4914F6CDD1D;
    }
};

inline fn pqAddMul(c: u64, a: u64, b: u64, pq: u64) u64 {
    var res: u128 = c;
    res += @as(u128, a) * @as(u128, b);
    return @intCast(res % pq);
}

pub fn factorize(pq: u64) ?struct { u64, u64 } {
    const p = factors(pq);

    if (p <= 1 or pq % p != 0) {
        @branchHint(.unlikely);
        return null;
    }

    const q = pq / p;

    return .{ p, q };
}

pub fn factors(pq: u64) u64 {
    var random = RandomState{};

    var y = random.next() % (pq - 1) + 1;
    const c = random.next() % (pq - 1) + 1;

    const m: u64 = 128;

    var g: u64 = 1;
    var r: u64 = 1;
    var q: u64 = 1;
    var x: u64 = 0;
    var ys: u64 = 0;

    while (g == 1) {
        x = y;
        for (0..r) |_| {
            y = pqAddMul(c, y, y, pq);
        }
        var k: u64 = 0;
        while (k < r and g == 1) {
            ys = y;
            const iterations = @min(m, r - k);
            for (0..iterations) |_| {
                y = pqAddMul(c, y, y, pq);
                const diff = if (x > y) (x - y) else (y - x);
                q = pqAddMul(0, q, diff, pq);
            }
            g = std.math.gcd(q, pq);
            k += iterations;
        }
        r *= 2;
    }

    if (g == pq) {
        @branchHint(.unlikely);
        g = 1;
        y = ys;
        while (g == 1) {
            y = pqAddMul(c, y, y, pq);
            g = std.math.gcd(if (x > y) x - y else y - x, pq);
        }
    }

    if (g > 1 and g < pq) {
        @branchHint(.likely);
        const other = pq / g;
        return @min(g, other);
    }
    return 1;
}

test "factorize 1" {
    const pq = factorize(1470626929934143021).?;
    try std.testing.expect(pq[0] == 1206429347);
    try std.testing.expect(pq[1] == 1218991343);
}

test "factorize 2" {
    const pq = factorize(2363612107535801713).?;
    try std.testing.expect(pq[0] == 1518968219);
    try std.testing.expect(pq[1] == 1556064227);
}

test "factorize 3" {
    const pq = factorize(2804275833720261793).?;
    try std.testing.expect(pq[0] == 1555252417);
    try std.testing.expect(pq[1] == 1803100129);
}
