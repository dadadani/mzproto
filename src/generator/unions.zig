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
const constructors = @import("../parser/constructors.zig");
const utils = @import("./utils.zig");

pub fn generateBoxedUnions(allocator: std.mem.Allocator, map: *const std.StringArrayHashMap(std.ArrayList(constructors.TLConstructor)), writer: *std.Io.Writer, mtproto: bool) !void {
    var it = map.iterator();

    while (it.next()) |box| {
        try writer.print(
            \\pub const {s} = union(enum) {{
            \\
        , .{box.key_ptr.*});

        for (box.value_ptr.items) |constructor| {
            const name = try utils.normalizeName(allocator, constructor, mtproto);
            defer allocator.free(name);

            try writer.print(
                \\    {s}: *const {s},
                \\
            , .{ name, name });
        }

        // deserializeSize

        try writer.print(
            \\    pub fn deserializeSize(in: []const u8, size: *usize) usize {{
            \\        const id = std.mem.readInt(u32, @ptrCast(in[0..4]), std.builtin.Endian.little);
            \\        switch (id) {{
            \\
        , .{});

        for (box.value_ptr.items) |constructor| {
            const name = try utils.normalizeName(allocator, constructor, mtproto);
            defer allocator.free(name);

            try writer.print(
                \\            0x{x} => {{
                \\                size.* = std.mem.alignForward(usize, size.*, @alignOf({s}));
                \\                return 4 + {s}.deserializeSize(in[4..], size);
                \\            }},
                \\
            , .{ constructor.id, name, name });
        }

        try writer.print(
            \\            else => {{
            \\                // TODO: return an error instead of... this
            \\                unreachable;
            \\            }},
            \\        }}
            \\    }}
            \\
        , .{});

        // END - deserializeSize

        // deserialize

        try writer.print(
            \\    pub fn deserialize(noalias in: []const u8, noalias out: []u8) struct {{{s}, usize, usize}} {{
            \\        @setEvalBranchQuota(1000000);
            \\        const id = std.mem.readInt(u32, @ptrCast(in[0..4]), std.builtin.Endian.little);
            \\        switch (id) {{
            \\
        , .{box.key_ptr.*});

        for (box.value_ptr.items) |item| {
            const name = try utils.normalizeName(allocator, item, mtproto);
            defer allocator.free(name);
            try writer.print(
                \\            0x{x} => {{
                \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType({s})));
                \\                const d = {s}.deserialize(in[4..], @alignCast(out[alignment..]));
                \\                return .{{{s}{{.{s} = d[0]}}, alignment+d[1], 4+d[2]}};
                \\            }},
                \\
            , .{ item.id, name, name, box.key_ptr.*, name });
        }

        try writer.print(
            \\            else => {{
            \\                // TODO: return an error instead of... this
            \\                unreachable;
            \\            }},
            \\        }}
            \\
        , .{});

        try writer.print(
            \\    }}
            \\
        , .{});

        // END - deserialize

        // serializeSize

        try writer.print(
            \\    pub fn serializeSize(self: *const {s}) usize {{
            \\        @setEvalBranchQuota(1000000);
            \\        switch (self.*) {{
            \\            inline else => |x| {{
            \\                return 4 + x.serializeSize();
            \\            }},
            \\        }}
            \\    }}
            \\
        , .{box.key_ptr.*});

        // END - serializeSize

        // serialize

        try writer.print(
            \\    pub fn serialize(self: *const {s}, out: []u8) usize {{
            \\        @setEvalBranchQuota(1000000);
            \\        switch (self.*) {{
            \\
        , .{box.key_ptr.*});

        for (box.value_ptr.items) |constructor| {
            const name = try utils.normalizeName(allocator, constructor, mtproto);
            defer allocator.free(name);

            try writer.print(
                \\            .{s} => |x| {{
                \\                _ = base.serializeInt(@as(u32, 0x{x}), out[0..4]);
                \\                return 4 + x.serialize(out[4..]);
                \\            }},
                \\
            , .{ name, constructor.id });
        }

        try writer.print(
            \\        }}
            \\    }}
            \\
        , .{});

        // END - serialize

        // cloneSize

        try writer.print(
            \\    pub fn cloneSize(self: *const {s}, size: *usize) void {{
            \\        @setEvalBranchQuota(1000000);
            \\        switch (self.*) {{
            \\            inline else => |x| {{
            \\                size.* = std.mem.alignForward(usize, size.*, @alignOf(@TypeOf(x)));
            \\                x.cloneSize(size);
            \\            }},
            \\        }}
            \\    }}
            \\
        , .{box.key_ptr.*});
        // END - cloneSize

        // clone

        try writer.print(
            \\    pub fn clone(self: *const {s}, out: []u8) struct {{{s}, usize}} {{
            \\        @setEvalBranchQuota(1000000);
            \\        switch (self.*) {{
            \\
        , .{ box.key_ptr.*, box.key_ptr.* });

        for (box.value_ptr.items) |constructor| {
            const name = try utils.normalizeName(allocator, constructor, mtproto);
            defer allocator.free(name);
            try writer.print(
                \\            .{s} => |x| {{
                \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(@TypeOf(x))));
                \\                const cloned = x.clone(@alignCast(out[alignment..]));
                \\                return .{{{s}{{.{s} = cloned[0]}}, alignment+cloned[1]}};
                \\            }},
                \\
            , .{ name, box.key_ptr.*, name });
        }

        try writer.print(
            \\        }}
            \\    }}
            \\
        , .{});

        // END - clone

        try writer.print(
            \\}};
            \\
        , .{});
    }
}

pub fn generateTLUnion(items: *const std.ArrayList(utils.TlUnionItem), writer: *std.Io.Writer) !void {
    try writer.print(
        \\pub const TL = union(enum) {{
        \\    MessageContainer: *const MessageContainer,
        \\    RPCResult: *const RPCResult,
        \\    Vector: *const Vector,
        \\    Int: u32,
        \\    Long: u64,
        \\
    , .{});

    for (items.items) |item| {
        try writer.print(
            \\    {s}: *const {s},
            \\
        , .{ item.name, item.name });
    }

    // deserializeSize

    try writer.print(
        \\    pub fn deserializeSize(in: []const u8, size: *usize) usize {{
        \\        @setEvalBranchQuota(1000000);
        \\        const id = std.mem.readInt(u32, @ptrCast(in[0..4]), std.builtin.Endian.little);
        \\        switch (id) {{
        \\            0x73F1F8DC => {{
        \\                size.* = std.mem.alignForward(usize, size.*, @alignOf(MessageContainer));
        \\                return 4 + MessageContainer.deserializeSize(in[4..], size);  
        \\            }},
        \\            0xf35c6d01 => {{
        \\                size.* = std.mem.alignForward(usize, size.*, @alignOf(RPCResult));
        \\                return 4 + RPCResult.deserializeSize(in[4..], size);  
        \\            }},
        \\            0x1cb5c415 => {{
        \\                size.* = std.mem.alignForward(usize, size.*, @alignOf(Vector));
        \\                return 4 + Vector.deserializeSize(in[4..], size);  
        \\            }},
        \\
    , .{});

    for (items.items) |item| {
        try writer.print(
            \\            0x{x} => {{
            \\                size.* = std.mem.alignForward(usize, size.*, @alignOf({s}));
            \\                return 4 + {s}.deserializeSize(in[4..], size);
            \\            }},
            \\
        , .{ item.id, item.name, item.name });
    }

    try writer.print(
        \\            else => {{
        \\                // TODO: return an error instead of... this
        \\                unreachable;
        \\            }},
        \\        }}
        \\
    , .{});

    try writer.print(
        \\    }}
        \\
    , .{});

    // END - deserializeSize

    // serializeSize

    try writer.print(
        \\    pub fn serializeSize(self: *const TL) usize {{
        \\        @setEvalBranchQuota(1000000);
        \\        switch (self.*) {{
        \\            .Int => {{
        \\                return 4;
        \\            }},
        \\            .Long => {{
        \\                return 8;
        \\            }},
        \\            inline else => |x| {{
        \\                return 4 + x.serializeSize();
        \\            }},
        \\        }}
        \\    }}
        \\
    , .{});

    // END - serializeSize

    // serialize

    try writer.print(
        \\    pub fn serialize(self: *const TL, out: []u8) usize {{
        \\        @setEvalBranchQuota(1000000);
        \\        switch (self.*) {{
        \\            .Int => |x| {{
        \\                _ = base.serializeInt(x, out[0..4]);
        \\                return 4;
        \\            }},
        \\            .Long => |x| {{
        \\                _ = base.serializeInt(x, out[0..8]);
        \\                return 8;
        \\            }},
        \\            .MessageContainer => |x| {{
        \\                _ = base.serializeInt(@as(u32, 0x73F1F8DC), out[0..4]);
        \\                return 4 + x.serialize(out[4..]);
        \\            }},
        \\            .RPCResult => |x| {{
        \\                _ = base.serializeInt(@as(u32, 0xf35c6d01), out[0..4]);
        \\                return 4 + x.serialize(out[4..]);
        \\            }},
        \\            .Vector => |x| {{
        \\                _ = base.serializeInt(@as(u32, 0x1cb5c415), out[0..4]);
        \\                return 4 + x.serialize(out[4..]);
        \\            }},
        \\
    , .{});

    for (items.items) |item| {
        try writer.print(
            \\            .{s} => |x| {{
            \\                _ = base.serializeInt(@as(u32, 0x{x}), out[0..4]);
            \\                return 4 + x.serialize(out[4..]);
            \\            }},
            \\
        , .{ item.name, item.id });
    }

    try writer.print(
        \\        }}
        \\    }}
        \\
    , .{});

    // END - serialize

    // deserialize

    try writer.print(
        \\    pub fn deserialize(noalias in: []const u8, noalias out: []u8) struct {{TL, usize, usize}} {{
        \\        @setEvalBranchQuota(1000000);
        \\        const id = std.mem.readInt(u32, @ptrCast(in[0..4]), std.builtin.Endian.little);
        \\        switch (id) {{
        \\            0x73F1F8DC => {{
        \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(MessageContainer)));
        \\                const d = MessageContainer.deserialize(in[4..], @alignCast(out[alignment..]));
        \\                return .{{TL{{.MessageContainer = d[0]}}, alignment+d[1], 4+d[2]}};
        \\            }},
        \\            0xf35c6d01 => {{
        \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(RPCResult)));
        \\                const d = RPCResult.deserialize(in[4..], @alignCast(out[alignment..]));
        \\                return .{{TL{{.RPCResult = d[0]}}, alignment+d[1], 4+d[2]}};
        \\            }},
        \\            0x1cb5c415 => {{
        \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(Vector)));
        \\                const d = Vector.deserialize(in[4..], @alignCast(out[alignment..]));
        \\                return .{{TL{{.Vector = d[0]}}, alignment+d[1], 4+d[2]}};
        \\            }},
        \\
    , .{});

    for (items.items) |item| {
        try writer.print(
            \\            0x{x} => {{
            \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType({s})));
            \\                const d = {s}.deserialize(in[4..], @alignCast(out[alignment..]));
            \\                return .{{TL{{.{s} = d[0]}}, alignment+d[1], 4+d[2]}};
            \\            }},
            \\
        , .{ item.id, item.name, item.name, item.name });
    }

    try writer.print(
        \\            else => {{
        \\                // TODO: return an error instead of... this
        \\                unreachable;
        \\            }},
        \\        }}
        \\
    , .{});

    try writer.print(
        \\    }}
        \\
    , .{});

    // END - deserialize

    // cloneSize

    try writer.print(
        \\    pub fn cloneSize(self: *const TL, size: *usize) void {{
        \\        @setEvalBranchQuota(1000000);
        \\        switch (self.*) {{
        \\            .Int => {{}},
        \\            .Long => {{}},
        \\            inline else => |x| {{
        \\                size.* = std.mem.alignForward(usize, size.*, @alignOf(@TypeOf(x)));
        \\                x.cloneSize(size);
        \\            }},
        \\        }}
        \\    }}
        \\
    , .{});
    // END - cloneSize

    // clone

    try writer.print(
        \\    pub fn clone(self: *const TL, out: []u8) struct {{TL, usize}} {{
        \\        @setEvalBranchQuota(1000000);
        \\        switch (self.*) {{
        \\            .Int => |x| {{
        \\                return .{{TL{{.Int = x}}, 0}};
        \\            }},
        \\            .Long => |x| {{
        \\                return .{{TL{{.Long = x}}, 0}};
        \\            }},
        \\            .MessageContainer => |x| {{
        \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(@TypeOf(x))));
        \\                const cloned = x.clone(@alignCast(out[alignment..]));
        \\                return .{{TL{{.MessageContainer = cloned[0]}}, alignment+cloned[1]}};
        \\            }},
        \\            .RPCResult => |x| {{
        \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(@TypeOf(x))));
        \\                const cloned = x.clone(@alignCast(out[alignment..]));
        \\                return .{{TL{{.RPCResult = cloned[0]}}, alignment+cloned[1]}};
        \\            }},
        \\            .Vector => |x| {{
        \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(@TypeOf(x))));
        \\                const cloned = x.clone(@alignCast(out[alignment..]));
        \\                return .{{TL{{.Vector = cloned[0]}}, alignment+cloned[1]}};
        \\            }},
        \\
    , .{});

    for (items.items) |item| {
        try writer.print(
            \\            .{s} => |x| {{
            \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(@TypeOf(x)));
            \\                const cloned = x.clone(@alignCast(out[alignment..]));
            \\                return .{{TL{{.{s} = cloned[0]}}, alignment+cloned[1]}};
            \\            }},
            \\
        , .{ item.name, item.name });
    }

    try writer.print(
        \\        }}
        \\    }}
        \\
    , .{});

    // END - clone

    try writer.print(
        \\}};
        \\
    , .{});
}
