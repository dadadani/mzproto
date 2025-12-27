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
const Error = @import("../transport.zig").Error;

const Abridged = @This();

const Mode = enum { SingleByte, FullBytes, Payload };

writer: *std.Io.Writer,
reader: *std.Io.Reader,

mode: Mode = .SingleByte,
len: usize = 0,

pub fn init(writer: *std.Io.Writer, reader: *std.Io.Reader) !Abridged {
    var self = Abridged{
        .reader = reader,
        .writer = writer,
    };
    try self.writer.writeByte(0xef);
    try self.writer.flush();
    return self;
}

pub fn recvLen(self: *Abridged) !usize {
    switch (self.mode) {
        .SingleByte => {
            var lenB: [1]u8 = undefined;

            try self.reader.readSliceAll(&lenB);
            if (lenB[0] >= 127) {
                self.mode = .FullBytes;
                return self.recvLen();
            }
            self.mode = .Payload;
            self.len = (@as(usize, lenB[0]) * 4);
            return self.len;
        },
        .FullBytes => {
            var len: [4]u8 = .{0} ** 4;
            try self.reader.readSliceAll(len[0..3]);
            self.len = @as(usize, std.mem.readInt(u32, &len, .little)) * 4;
            self.mode = .Payload;
            return self.len;
        },
        .Payload => {
            return self.len;
        },
    }
}

pub fn recv(self: *Abridged, buf: []u8) !usize {
    switch (self.mode) {
        .SingleByte, .FullBytes => {
            return Error.LengthNotRead;
        },
        .Payload => {
            const len_dest = @min(buf.len, self.len);
            try self.reader.readSliceAll(buf[0..len_dest]);
            self.len -= len_dest;
            if (self.len <= 0) {
                self.mode = .SingleByte;
            }
            return len_dest;
        },
    }
}

pub fn write(self: *Abridged, buf: []const u8) !void {
    const len = @as(u8, @intCast(buf.len / 4));

    if (len < 0x7F) {
        _ = try self.writer.writeVec(&.{ &.{len}, buf });
        try self.writer.flush();
    } else {
        var buf_dest: [4]u8 = undefined;
        std.mem.writeInt(u32, &buf_dest, @as(u32, len), .little);
        _ = try self.writer.writeVec(&.{ &.{0x7F}, buf_dest[0..3], buf });
        try self.writer.flush();
    }
}

pub fn writeVec(self: *Abridged, buf: []const []const u8) !void {
    var len: usize = 0;
    for (buf) |i| {
        len += i.len;
    }
    len = len / 4;

    if (len < 0x7F) {
        try self.writer.writeByte(@intCast(len));
        _ = try self.writer.writeVec(buf);
        try self.writer.flush();
    } else {
        var buf_dest: [4]u8 = undefined;
        std.mem.writeInt(u32, &buf_dest, @as(u32, @intCast(len)), .little);
        try self.writer.writeByte(0x7F);
        _ = try self.writer.write(buf_dest[0..3]);
        _ = try self.writer.writeVec(buf);
        try self.writer.flush();
    }
}
