const std = @import("std");
pub const DcId = packed struct(i32) {
    id: u8,
    _: u20 = 0,
    cdn: bool = false,
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
        if (self.cdn) {
            _ = try writer.write(" cdn");
        }
        _ = try writer.write("]");

        try writer.flush();
    }
};

pub fn detectMigrateError(err_message: []const u8) ?u8 {
    if (std.mem.startsWith(u8, err_message, "FILE_MIGRATE_")) {
        return std.fmt.parseInt(u8, err_message["FILE_MIGRATE_".len..], 10) catch @panic("unexpected fail convert dc");
    }

    if (std.mem.startsWith(u8, err_message, "NETWORK_MIGRATE_")) {
        return std.fmt.parseInt(u8, err_message["NETWORK_MIGRATE_".len..], 10) catch @panic("unexpected fail convert dc");
    }

    if (std.mem.startsWith(u8, err_message, "PHONE_MIGRATE_")) {
        return std.fmt.parseInt(u8, err_message["PHONE_MIGRATE_".len..], 10) catch @panic("unexpected fail convert dc");
    }

    if (std.mem.startsWith(u8, err_message, "STATS_MIGRATE_")) {
        return std.fmt.parseInt(u8, err_message["STATS_MIGRATE_".len..], 10) catch @panic("unexpected fail convert dc");
    }

    if (std.mem.startsWith(u8, err_message, "USER_MIGRATE_")) {
        return std.fmt.parseInt(u8, err_message["USER_MIGRATE_".len..], 10) catch @panic("unexpected fail convert dc");
    }
    return null;
}
