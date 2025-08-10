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

const ReplaceData = struct {
    []const u8,
    []const u8,
};

/// Trims whitespace and newlines from the beginning and end of a string.
pub inline fn trimWhitespace(in: []const u8) []const u8 {
    return std.mem.trim(u8, std.mem.trim(u8, in, " "), "\n");
}

/// Removes all comments from a string.
/// Comments are considered to be all the text that follows a `//` until the end of the line.
/// The function returns the length of the output string.
pub fn removeTlComments(in: []const u8, out: []u8) !usize {
    var comment = false;

    var i: usize = 0;
    for (0..in.len) |j| {
        if (std.mem.eql(u8, in[j..@min(j + 2, in.len)], "//")) {
            comment = true;
        } else if (in[j] == '\n' and comment) {
            comment = false;
        }

        if (!comment) {
            out[i] = in[j];
            i += 1;
        }
    }

    return i;
}

/// Allows to replace multiple substrings in a string.
/// ReplaceData is a tuple of two strings, the first one is the substring to be replaced and the second one is the replacement.
/// The function returns a new string with all the replacements applied.
fn multi_replace(allocator: std.mem.Allocator, in: []const u8, replacements: []const ReplaceData) ![]const u8 {
    var repl: []const u8 = try allocator.dupe(u8, in);
    for (replacements) |replacement| {
        const repl_do = try std.mem.replaceOwned(u8, allocator, repl, replacement[0], replacement[1]);
        allocator.free(repl);
        repl = repl_do;
    }
    return repl;
}

/// Removes a range of bytes from a string.
fn removeRange(allocator: std.mem.Allocator, in: []const u8, start: usize, end: usize) ![]const u8 {
    const len = in.len;
    if (start >= len) {
        return in;
    }
    if (end >= len) {
        return in[0..start];
    }
    const first = in[0..start];
    const second = in[end..];
    return try std.mem.concat(allocator, u8, &[_][]const u8{ first, second });
}

/// Generate the ID of a constructor from its definition by using Telegram's standard procedure.
pub fn generateIdFromConstructor(allocator: std.mem.Allocator, constructor: []const u8) !u32 {
    var repr = try multi_replace(allocator, constructor, &[_]ReplaceData{ .{ ":bytes ", ": string" }, .{ "?bytes ", "? string" }, .{ "<", " " }, .{ ">", "" }, .{ "{", "" }, .{ "}", "" } });
    defer allocator.free(repr);

    while (std.mem.indexOf(u8, repr, "?true")) |pos| {
        const space = std.mem.lastIndexOf(u8, repr[0..pos], " ") orelse 0;
        const repr_remove = try removeRange(allocator, repr, space, pos + "?true".len);
        allocator.free(repr);
        repr = repr_remove;
    }

    var crc = std.hash.Crc32.init();
    crc.update(repr);
    return crc.final();
}

test "multi_replace" {
    const allocator = std.testing.allocator;

    const input = "a a a a";
    const replacements = [_]ReplaceData{.{ "a", "bb" }};

    const expected = "bb bb bb bb";

    const result = try multi_replace(allocator, input, replacements[0..]);
    defer allocator.free(result);

    try std.testing.expectEqualStrings(expected, result);
}

test "removeRange" {
    const allocator = std.testing.allocator;

    const input = "a x b a";
    const start = 1;
    const end = 5;

    const expected = "a a";

    const result = try removeRange(allocator, input, start, end);
    defer allocator.free(result);

    try std.testing.expectEqualStrings(expected, result);
}

test "generateIdFromConstructor" {
    const allocator = std.testing.allocator;

    try std.testing.expectEqual(0xa43ad8b7, try generateIdFromConstructor(allocator, "rpc_answer_dropped msg_id:long seq_no:int bytes:int = RpcDropAnswer"));
    try std.testing.expectEqual(0x62d6b459, try generateIdFromConstructor(allocator, "msgs_ack msg_ids:Vector<long> = MsgsAck"));
    try std.testing.expectEqual(0xcb9f372d, try generateIdFromConstructor(allocator, "invokeAfterMsg {X:Type} msg_id:long query:!X = X"));
    try std.testing.expectEqual(0x80c99768, try generateIdFromConstructor(allocator, "inputMessagesFilterPhoneCalls flags:# missed:flags.0?true = MessagesFilter"));
}
