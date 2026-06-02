const mz = @import("mzproto");

fn sum(self: *const mz.TestSub1) mz.Result(i32) {
    return .{ .ok = self.a + self.b };
}

fn sum2(self: *const mz.TestSub1, c: i32) mz.Result(i32) {
    return .{ .ok = self.a + self.b + c };
}

pub const Methods = .{
    .sum = sum,
    .sum2 = sum2,
};
