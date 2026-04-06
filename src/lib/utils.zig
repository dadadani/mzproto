const std = @import("std");
pub const DcId = packed struct(i32) {
    id: u29,
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
        writer.print("[dc{s}", .{self.id});
        if (self.testmode) {
            writer.write(" testmode");
        }
        if (self.media) {
            writer.write(" media");
        }

        writer.write("]");

        writer.flush();
    }
};
