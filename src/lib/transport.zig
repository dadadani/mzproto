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

const Abridged = @import("transport/abridged.zig");

const std = @import("std");

pub const Error = error{ LengthNotRead, LengthAlreadyConsumed };

pub const Transports = enum {
    Abridged,
};

pub const Transport = union(Transports) {
    Abridged: Abridged,

    pub fn init(transport_mode: Transports, writer: *std.Io.Writer, reader: *std.Io.Reader) !Transport {
        switch (transport_mode) {
            .Abridged => {
                return .{ .Abridged = try Abridged.init(writer, reader) };
            },
        }
    }

    pub fn recvLen(self: *Transport) !usize {
        return switch (self.*) {
            .Abridged => self.Abridged.recvLen(),
        };
    }

    pub fn recv(self: *Transport, buf: []u8) !usize {
        return switch (self.*) {
            .Abridged => self.Abridged.recv(buf),
        };
    }

    pub fn write(self: *Transport, buf: []const u8) !void {
        return switch (self.*) {
            .Abridged => self.Abridged.write(buf),
        };
    }

    pub fn writeVec(self: *Transport, buf: []const []const u8) !void {
        return switch (self.*) {
            .Abridged => self.Abridged.writeVec(buf),
        };
    }
};
