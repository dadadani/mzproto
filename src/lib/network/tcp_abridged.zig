const std = @import("std");

pub const IncomingDataCallback = *const fn ([]u8, *const anyopaque) void;

const TcpAbridged = struct {
    allocator: std.mem.Allocator,

    read_status: enum { ReadingLength, ReadingLengthExtended, ReadingBody },

    read_buf: []u8,
    read_len_net: usize,

    extended_len_buf: [4]u8 = undefined,
    extended_len_read: u4 = 0,

    user_data: *const anyopaque,
    incoming_data_callback: IncomingDataCallback,

    pub fn init(allocator: std.mem.Allocator, incoming_data_callback: IncomingDataCallback, user_data: *const anyopaque) TcpAbridged {
        return .{ .allocator = allocator, .read_status = .ReadingLength, .extended_len_read = 0, .read_buf = &[_]u8{}, .incoming_data_callback = incoming_data_callback, .user_data = user_data, .read_len_net = 0 };
    }

    pub fn put(self: *TcpAbridged, src: []const u8) !void {
        if (src.len == 0) {
            return;
        }
        switch (self.read_status) {
            .ReadingLength => {
                if (src[0] == 0) {
                    return;
                }
                if (src[0] == 0x7F) {
                    self.read_status = .ReadingLengthExtended;
                    self.extended_len_buf[3] = 0;
                    self.extended_len_read = 0;

                    const remaining = src[1..];

                    if (remaining.len > 0) {
                        try self.put(remaining);
                    }
                } else {
                    self.read_buf = try self.allocator.alloc(u8, @as(usize, src[0]) * 4);
                    self.read_status = .ReadingBody;

                    const remaining = src[1..];

                    if (remaining.len > 0) {
                        try self.put(remaining);
                    }
                }
            },
            .ReadingLengthExtended => {
                if (self.extended_len_read < 3) {
                    self.extended_len_buf[self.extended_len_read] = src[0];
                    self.extended_len_read += 1;

                    if (src.len > 1) {
                        try self.put(src[1..]);
                    }
                } else {
                    self.read_buf = try self.allocator.alloc(u8, std.mem.readInt(u32, &self.extended_len_buf, .little) * 4);
                    self.read_status = .ReadingBody;
                    self.extended_len_read = 0;

                    try self.put(src);
                }
            },
            .ReadingBody => {
                const incoming = src[0..@min(src.len, self.read_buf.len - self.read_len_net)];
                const dest = self.read_buf[self.read_len_net..@min(self.read_len_net + incoming.len, self.read_buf.len)];

                @memcpy(dest, incoming);

                self.read_len_net += incoming.len;

                if (self.read_len_net == self.read_buf.len) {
                    self.incoming_data_callback(self.read_buf, self.user_data);
                    self.read_status = .ReadingLength;
                    self.read_len_net = 0;
                    self.allocator.free(self.read_buf);
                    self.read_buf = &[_]u8{};
                }

                if (src[incoming.len..].len > 0) {
                    try self.put(src[incoming.len..]);
                }
            },
        }
    }

    pub fn suggestedReadSize(self: *TcpAbridged) u32 {
        switch (self.read_status) {
            .ReadingLength => return 1,
            .ReadingLengthExtended => return 4 - (self.extended_len_read - 1),
            .ReadingBody => return self.read_buf.len - self.read_len_net,
        }
    }

    pub fn deinit(self: *TcpAbridged) void {
        if (self.read_buf.len > 0) {
            self.allocator.free(self.read_buf);
        }
    }
};

pub fn incomingData(data: []u8, user_data: *const anyopaque) void {
    _ = user_data;
    std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4, 5, 6, 7, 8 }, data) catch |x| {
        std.debug.panic("{}", .{x});
    };
}

test "test read" {
    const allocator = std.testing.allocator;

    var tcp_abriged = TcpAbridged.init(allocator, incomingData, &null);
    defer tcp_abriged.deinit();

    try tcp_abriged.put(&[_]u8{ 2, 1 });

    try tcp_abriged.put(&[_]u8{ 2, 3, 4, 5, 6, 7, 8, 2, 1, 2 });

    try tcp_abriged.put(&[_]u8{ 3, 4, 5, 6, 7, 8 });

    try tcp_abriged.put(&[_]u8{ 0x7F, 0x02, 0x00, 0x00, 1, 2, 3, 4, 5, 6, 7, 8 });
}
