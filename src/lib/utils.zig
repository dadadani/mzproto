const std = @import("std");
pub const DcId = packed struct(i32) {
    id: u8,
    _: u21 = 0,
    testmode: bool = false,
    valid: bool = true, // used in storage backends to make sure the preferred dc is set, keep always true
    media: bool = false,

    pub inline fn int(self: DcId) i32 {
        return @as(i32, @bitCast(self));
    }

    pub fn format(
        self: DcId,
        writer: *std.Io.Writer,
    ) !void {
        try writer.print("[dc{d}", .{self.id});
        if (self.testmode) {
            _ = try writer.write(" testmode");
        }
        if (self.media) {
            _ = try writer.write(" media");
        }

        _ = try writer.write("]");

        try writer.flush();
    }
};
