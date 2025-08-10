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

pub fn generateConstructorDeserializeSize(allocator: std.mem.Allocator, constructor: constructors.TLConstructor, constructorName: []const u8, writer: *std.io.Writer, mtproto: bool) !void {
    try writer.print(
        \\    pub fn deserializeSize(in: []const u8, size: *usize) usize {{
        \\    
    , .{});

    //_ = constructorName;

    if (constructor.params.items.len == 0) {
        try writer.print(
            \\        _ = in;
            \\        _ = size;
            \\        return 0;
            \\    }}
            \\
        , .{});
        return;
    }

    var inUsed = false;
    var sizeMutated = false;

    var flagsUnusedMap = std.StringHashMap(bool).init(allocator);
    defer flagsUnusedMap.deinit();

    try writer.print(
        \\        size.* += @sizeOf({s});
        \\        var read: usize = 0;
        \\
    , .{constructorName});
    for (constructor.params.items) |item| {
        if (item.type_def) {
            @panic("TODO: type_def");
        }

        switch (item.type.?) {
            .Flags => {
                inUsed = true;
                if (!flagsUnusedMap.contains(item.name)) {
                    try flagsUnusedMap.put(item.name, false);
                }
                try writer.print(
                    \\        const flags_{s} = std.mem.readInt(u32, @ptrCast(in[read..read+4]), .little);
                    \\        read += 4;
                    \\
                , .{item.name});
            },
            .Normal => |nrm| {
                if (std.mem.eql(u8, nrm.type.name, "true")) {
                    continue;
                }

                if (nrm.flag) |flag| {
                    try flagsUnusedMap.put(flag.name, true);
                    try writer.print(
                        \\        if ((flags_{s} & (1 << {d})) != 0) {{
                        \\        
                    , .{ flag.name, flag.index });
                }

                var actual_type = nrm.type;
                var counter: usize = 0;

                while (actual_type.generic_arg) |generic_arg| {
                    counter += 1;
                    if (std.mem.eql(u8, nrm.type.name, "Vector")) {
                        const str_type = try utils.typeToZig(allocator, actual_type, mtproto);
                        defer allocator.free(str_type);
                        inUsed = true;
                        sizeMutated = true;

                        try writer.print(
                            \\        const len_{s}_{d} = base.vectorLen(in[read..], &read);
                            \\        size.* = std.mem.alignForward(usize, size.*, @alignOf(base.unwrapType({s}))) + len_{s}_{d} * @sizeOf(base.unwrapType({s}));
                            \\          
                            \\        for (0..len_{s}_{d}) |_| {{
                            \\
                        , .{ item.name, counter, str_type, item.name, counter, str_type, item.name, counter });
                        actual_type = generic_arg;
                    } else {
                        return utils.TypeToZigError.UnsupportedGenericArgument;
                    }
                }

                if (utils.tlPrimitiveName(actual_type.name)) |primitive| {
                    if (std.mem.eql(u8, primitive, "[]const u8")) {
                        inUsed = true;
                        sizeMutated = true;
                        try writer.print(
                            \\        size.* += base.strDeserializedSize(in[read..], &read);
                            \\
                        , .{});
                    } else if (std.mem.eql(u8, primitive, "bool")) {
                        try writer.print(
                            \\        read += 4;
                            \\
                        , .{});
                    } else {
                        try writer.print(
                            \\        read += @sizeOf({s});
                            \\
                        , .{primitive});
                    }
                } else {
                    if (actual_type.generic_ref) {
                        inUsed = true;
                        sizeMutated = true;
                        try writer.print(
                            \\        read += TL.deserializeSize(in[read..], size);
                            \\
                        , .{});
                    } else {
                        const str_type = try utils.typeToZig(allocator, actual_type, mtproto);
                        defer allocator.free(str_type);
                        inUsed = true;
                        sizeMutated = true;
                        try writer.print(
                            \\        read += {s}.deserializeSize(in[read..], size);
                            \\
                        , .{str_type});
                    }
                }

                actual_type = nrm.type;

                while (actual_type.generic_arg) |generic_arg| {
                    try writer.print(
                        \\        }}
                        \\
                    , .{});
                    actual_type = generic_arg;
                }
                if (nrm.flag != null) {
                    try writer.print(
                        \\        }}
                        \\
                    , .{});
                }

                //std.mem.alignForward(comptime T: type, addr: T, alignment: T)
            },
        }
    }

    var flagsIt = flagsUnusedMap.iterator();

    while (flagsIt.next()) |flags| {
        if (flags.value_ptr.*) {
            continue;
        }
        try writer.print(
            \\        _ = flags_{s};
            \\
        , .{flags.key_ptr.*});
    }

    if (!inUsed) {
        try writer.print(
            \\        _ = in;
            \\
        , .{});
    }

    if (!sizeMutated and 1 == 0) {
        try writer.print(
            \\        size = size;
            \\
        , .{});
    }

    try writer.print(
        \\        return read;
        \\    }}
        \\
    , .{});
}

pub fn generateConstructorDeserialize(allocator: std.mem.Allocator, constructor: constructors.TLConstructor, constructorName: []const u8, writer: *std.io.Writer, mtproto: bool) !void {
    try writer.print(
        \\    pub fn deserialize(noalias in: []const u8, noalias out: []align(@alignOf({s})) u8) struct {{*{s}, usize, usize}} {{
        \\
    , .{ constructorName, constructorName });

    if (constructor.params.items.len == 0) {
        try writer.print(
            \\        _ = in;
            \\        return .{{@as(*{s}, @alignCast(@ptrCast(out[0..@sizeOf({s})].ptr))), @sizeOf({s}), 0}};
            \\    }}
            \\
        , .{ constructorName, constructorName, constructorName });
        return;
    }

    var flagsUnusedMap = std.StringHashMap(bool).init(allocator);
    defer flagsUnusedMap.deinit();

    var writtenMutated = false;

    try writer.print(
        \\        var written: usize = @sizeOf({s});
        \\        const self = @as(*{s}, @ptrCast(@alignCast(out[0..@sizeOf({s})])));
        \\        var read: usize = 0;
        \\
    , .{ constructorName, constructorName, constructorName });

    for (constructor.params.items) |item| {
        if (item.type_def) {
            @panic("TODO: type_def");
        }

        switch (item.type.?) {
            .Flags => {
                if (!flagsUnusedMap.contains(item.name)) {
                    try flagsUnusedMap.put(item.name, false);
                }
                try writer.print(
                    \\        const flags_{s} = std.mem.readInt(u32, @ptrCast(in[read..read+4]), .little);
                    \\        read += 4;
                    \\
                , .{utils.safeStrParam(item.name)});
            },
            .Normal => |nrm| {
                if (std.mem.eql(u8, nrm.type.name, "true")) {
                    if (nrm.flag) |flag| {
                        try flagsUnusedMap.put(flag.name, true);
                        try writer.print(
                            \\        self.{s} = (flags_{s} & (1 << {d})) != 0;
                            \\
                        , .{ utils.safeStrParam(item.name), flag.name, flag.index });
                        continue;
                    } else {
                        return utils.TypeToZigError.UnsupportedTrueTypeVariant;
                    }
                }

                var param_name = try std.fmt.allocPrint(allocator, "self.{s}", .{utils.safeStrParam(item.name)});
                defer allocator.free(param_name);

                if (nrm.flag) |flag| {
                    try flagsUnusedMap.put(flag.name, true);
                    try writer.print(
                        \\        if ((flags_{s} & (1 << {d})) != 0) {{
                        \\        
                    , .{ flag.name, flag.index });
                }

                var actual_type = nrm.type;
                var counter: usize = 1;

                while (actual_type.generic_arg) |generic_arg| {
                    if (std.mem.eql(u8, nrm.type.name, "Vector")) {
                        const str_type = try utils.typeToZig(allocator, actual_type, mtproto);
                        defer allocator.free(str_type);
                        writtenMutated = true;

                        try writer.print(
                            \\        const len_{s}_{d} = base.vectorLen(in[read..], &read);
                            \\        const v_{s}_{d} = v: {{
                            \\            const sliced = base.bytesToSlice(out[written..], len_{s}_{d}, base.unwrapType({s}));
                            \\            written += sliced[1];
                            \\            break :v sliced[0];
                            \\        }};
                            \\        {s} = v_{s}_{d};
                            \\          
                            \\        for (0..len_{s}_{d}) |i_{s}_{d}| {{
                            \\
                        , .{
                            utils.safeStrParam(item.name), counter, //len_{s}_{d}
                            utils.safeStrParam(item.name), counter, //v_{s}_{d}
                            utils.safeStrParam(item.name), counter, //en..], len_{s}_{d}, bas
                            str_type, //rapType({s}));
                            param_name, //{s} =
                            utils.safeStrParam(item.name), counter, //= v_{s}_{d};
                            utils.safeStrParam(item.name), counter, //for (0..len_{s}_{d})
                            utils.safeStrParam(item.name), counter, //|i_{s}_{d}| {{
                        });

                        if (counter == 1) {
                            const slice_name = try std.fmt.allocPrint(allocator, "v_{s}_{d}[i_{s}_{d}]", .{ utils.safeStrParam(item.name), counter, utils.safeStrParam(item.name), counter });
                            allocator.free(param_name);
                            param_name = slice_name;
                        } else {
                            @panic("TODO: implement nested vectors");
                        }

                        actual_type = generic_arg;
                        counter += 1;
                    } else {
                        return utils.TypeToZigError.UnsupportedGenericArgument;
                    }
                }

                if (utils.tlPrimitiveName(actual_type.name)) |primitive| {
                    if (std.mem.eql(u8, primitive, "[]const u8")) {
                        writtenMutated = true;
                        try writer.print(
                            \\        {{
                            \\            const d = base.deserializeString(in[read..], out[written..]);
                            \\            {s} = out[written..written+d[0]];
                            \\            written += d[0];
                            \\            read += d[1];
                            \\        }}
                        , .{param_name});
                    } else if (std.mem.eql(u8, primitive, "bool")) {
                        try writer.print(
                            \\        {{
                            \\            const d = std.mem.readInt(u32, @ptrCast(in[read..read+4]), std.builtin.Endian.little);
                            \\            read += 4;
                            \\            if (d == 0x997275b5) {{
                            \\                {s} = true;
                            \\            }} else if (d == 0x997275b5) {{
                            \\                {s} = false;
                            \\            }} else {{
                            \\                unreachable; // TODO: use something else     
                            \\            }}
                            \\            
                            \\        }}
                            \\
                        , .{ param_name, param_name });
                    } else if (std.mem.eql(u8, primitive, "f64")) {
                        try writer.print(
                            \\        {{
                            \\            const d = std.mem.readInt(u64, @ptrCast(in[read..read+@sizeOf(u64)]), std.builtin.Endian.little);
                            \\            read += @sizeOf(f64);
                            \\            {s} = @bitCast(d);
                            \\        }}
                            \\
                        , .{param_name});
                    } else {
                        try writer.print(
                            \\        {{
                            \\            const d = std.mem.readInt({s}, @ptrCast(in[read..read+@sizeOf({s})]), std.builtin.Endian.little);
                            \\            read += @sizeOf({s});
                            \\            {s} = d;
                            \\        }}
                            \\
                        , .{ primitive, primitive, primitive, param_name });
                    }
                } else {
                    const str_type = try utils.typeToZig(allocator, actual_type, mtproto);
                    defer allocator.free(str_type);
                    writtenMutated = true;
                    try writer.print(
                        \\        {{
                        \\            const d = base.unwrapType({s}).deserialize(in[read..], out[written..]);
                        \\            {s} = d[0];
                        \\            written += d[1];
                        \\            read += d[2];
                        \\        }}
                        \\
                    , .{ str_type, param_name });
                }

                actual_type = nrm.type;

                while (actual_type.generic_arg) |generic_arg| {
                    try writer.print(
                        \\        }}
                        \\
                    , .{});
                    actual_type = generic_arg;
                }
                if (nrm.flag != null) {
                    try writer.print(
                        \\        }} else {{
                        \\            self.{s} = null;
                        \\        }}
                        \\
                    , .{utils.safeStrParam(item.name)});
                }
            }, //std.mem.readInt(T, bytes, std.builtin.Endian.little)
        }
    }

    var flagsIt = flagsUnusedMap.iterator();

    while (flagsIt.next()) |flags| {
        if (flags.value_ptr.*) {
            continue;
        }
        try writer.print(
            \\        _ = flags_{s};
            \\
        , .{flags.key_ptr.*});
    }

    if (!writtenMutated) {
        try writer.print(
            \\        written = written;
            \\
        , .{});
    }

    try writer.print(
        \\        return .{{self, written, read}};
        \\    }}
        \\
    , .{});
}
