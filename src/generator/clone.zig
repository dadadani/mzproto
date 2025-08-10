const std = @import("std");
const constructors = @import("../parser/constructors.zig");
const utils = @import("./utils.zig");

pub fn generateConstructorCloneSize(allocator: std.mem.Allocator, constructor: constructors.TLConstructor, constructorName: []const u8, writer: *std.io.Writer, mtproto: bool) !void {
    try writer.print(
        \\    pub fn cloneSize(self: *const {s}, size: *usize) void {{
        \\    
    , .{constructorName});

    if (constructor.params.items.len == 0) {
        try writer.print(
            \\        _ = self;
            \\        size.* += @sizeOf({s});
            \\    }}
            \\
        , .{constructorName});
        return;
    }

    var selfUsed = false;

    try writer.print(
        \\        size.* += @sizeOf({s});
        \\
    , .{constructorName});

    for (constructor.params.items) |item| {
        if (item.type_def) {
            @panic("TODO: type_def");
        }

        var used = true;

        switch (item.type.?) {
            .Flags => {},
            .Normal => |nrm| {
                if (std.mem.eql(u8, nrm.type.name, "true")) {
                    continue;
                }

                var param_name = try std.fmt.allocPrint(allocator, "self.{s}", .{utils.safeStrParam(item.name)});
                defer allocator.free(param_name);

                if (nrm.flag != null) {
                    selfUsed = true;
                    used = false;
                    try writer.print(
                        \\        if (self.{s}) |opt_{s}| {{
                        \\        
                    , .{ utils.safeStrParam(item.name), utils.safeStrParam(item.name) });

                    const new_name = try std.fmt.allocPrint(allocator, "opt_{s}", .{utils.safeStrParam(item.name)});
                    allocator.free(param_name);
                    param_name = new_name;
                }

                var actual_type = nrm.type;
                var counter: usize = 0;

                while (actual_type.generic_arg) |generic_arg| {
                    counter += 1;
                    if (std.mem.eql(u8, nrm.type.name, "Vector")) {
                        const str_type = try utils.typeToZig(allocator, actual_type, mtproto);
                        defer allocator.free(str_type);
                        //  inUsed = true;
                        //sizeMutated = true;
                        selfUsed = true;
                        used = false;
                        try writer.print(
                            \\        size.* = std.mem.alignForward(usize, size.*, @alignOf(base.unwrapType({s}))) + {s}.len * @sizeOf(base.unwrapType({s}));
                            \\          
                            \\        for ({s}) |i{s}_{d}| {{
                            \\
                        , .{ str_type, param_name, str_type, param_name, utils.safeStrParam(item.name), counter });

                        const new_name = try std.fmt.allocPrint(allocator, "i{s}_{d}", .{ utils.safeStrParam(item.name), counter });
                        allocator.free(param_name);
                        param_name = new_name;

                        actual_type = generic_arg;
                    } else {
                        return utils.TypeToZigError.UnsupportedGenericArgument;
                    }
                }

                if (utils.tlPrimitiveName(actual_type.name)) |primitive| {
                    if (std.mem.eql(u8, primitive, "[]const u8")) {
                        selfUsed = true;
                        used = true;
                        try writer.print(
                            \\        size.* += {s}.len;
                            \\
                        , .{param_name});
                    }
                } else {
                    selfUsed = true;
                    used = true;
                    try writer.print(
                        \\        {s}.cloneSize(size);
                        \\
                    , .{param_name});
                }

                actual_type = nrm.type;

                if (!used) {
                    try writer.print(
                        \\        _ = {s};
                        \\
                    , .{param_name});
                }

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
            },
        }
    }

    if (!selfUsed) {
        try writer.print(
            \\        _ = self;
            \\
        , .{});
    }

    try writer.print(
        \\    }}
        \\
    , .{});
}

pub fn generateConstructorClone(allocator: std.mem.Allocator, constructor: constructors.TLConstructor, constructorName: []const u8, writer: *std.io.Writer, mtproto: bool) !void {
    try writer.print(
        \\    pub fn clone(self: *const {s}, out: []align(@alignOf({s})) u8) struct {{*{s}, usize}} {{
        \\
    , .{ constructorName, constructorName, constructorName });

    if (constructor.params.items.len == 0) {
        try writer.print(
            \\        _ = self;
            \\        return .{{@ptrCast(@alignCast(out[0..@sizeOf({s})].ptr)), @sizeOf({s})}};
            \\    }}
            \\
        , .{ constructorName, constructorName });
        return;
    }

    var writtenMutated = false;

    try writer.print(
        \\        var written: usize = @sizeOf({s});
        \\        const self_out: *{s} = @ptrCast(@alignCast(out[0..@sizeOf({s})]));
        \\        @memcpy(out[0..@sizeOf({s})], @as([*]const u8, @ptrCast(self))[0..@sizeOf({s})]);
        \\
    , .{ constructorName, constructorName, constructorName, constructorName, constructorName });

    for (constructor.params.items) |item| {
        if (item.type_def) {
            @panic("TODO: type_def");
        }

        switch (item.type.?) {
            .Flags => {},
            .Normal => |nrm| {
                if (std.mem.eql(u8, nrm.type.name, "true")) {
                    continue;
                }

                var used = true;

                var param_name = try std.fmt.allocPrint(allocator, "self.{s}", .{utils.safeStrParam(item.name)});
                defer allocator.free(param_name);

                var out_param_name = try std.fmt.allocPrint(allocator, "self_out.{s}", .{utils.safeStrParam(item.name)});
                defer allocator.free(out_param_name);

                var vector_last_i = try allocator.dupe(u8, "");
                defer allocator.free(vector_last_i);

                var vector_i_used = false;

                if (nrm.flag != null) {
                    used = false;
                    try writer.print(
                        \\        if (self.{s}) |opt_{s}| {{
                        \\        
                    , .{ utils.safeStrParam(item.name), utils.safeStrParam(item.name) });

                    const new_name = try std.fmt.allocPrint(allocator, "opt_{s}", .{utils.safeStrParam(item.name)});
                    allocator.free(param_name);
                    param_name = new_name;
                }

                var actual_type = nrm.type;
                var counter: usize = 0;

                while (actual_type.generic_arg) |generic_arg| {
                    counter += 1;
                    if (std.mem.eql(u8, nrm.type.name, "Vector")) {
                        const str_type = try utils.typeToZig(allocator, actual_type, mtproto);
                        defer allocator.free(str_type);
                        used = true;
                        writtenMutated = true;

                        try writer.print(
                            \\        const v_{s}_{d} = v: {{
                            \\            const sliced = base.bytesToSlice(out[written..], {s}.len, base.unwrapType({s}));
                            \\            written += sliced[1];
                            \\            break :v sliced[0];
                            \\        }};
                            \\        {s} = v_{s}_{d};
                            \\        @memcpy(v_{s}_{d}, {s});
                            \\          
                            \\        for (0..{s}.len) |i_{s}_{d}| {{
                            \\
                        , .{
                            utils.safeStrParam(item.name), counter, // v_{s}_{d} = v
                            param_name, // {s}.len
                            str_type, //base.unwrapType({s}));
                            out_param_name, //{s} =
                            utils.safeStrParam(item.name), counter, //  = v_{s}_{d};
                            utils.safeStrParam(item.name), counter, //@memcpy(v_{s}_{d},
                            param_name, //  , {s});
                            param_name, // for (0..{s}.len)
                            utils.safeStrParam(item.name), counter, //|i_{s}_{d}| {{
                        });

                        //.{ str_type, param_name, str_type, param_name, utils.safeStrParam(item.name), counter });

                        const new_name = try std.fmt.allocPrint(allocator, "{s}[i_{s}_{d}]", .{ param_name, utils.safeStrParam(item.name), counter });
                        allocator.free(param_name);
                        param_name = new_name;

                        const new_i = try std.fmt.allocPrint(allocator, "i_{s}_{d}", .{ utils.safeStrParam(item.name), counter });
                        allocator.free(vector_last_i);
                        vector_last_i = new_i;

                        if (counter == 1) {
                            const new_out_name = try std.fmt.allocPrint(allocator, "v_{s}_{d}[i_{s}_{d}]", .{ utils.safeStrParam(item.name), counter, utils.safeStrParam(item.name), counter });
                            allocator.free(out_param_name);
                            out_param_name = new_out_name;
                        } else {
                            // This should probably work even with nested vectors, but I am too lazy right now to make sure
                            @panic("TODO: implement nested vectors");
                        }

                        actual_type = generic_arg;
                    } else {
                        return utils.TypeToZigError.UnsupportedGenericArgument;
                    }
                }

                if (utils.tlPrimitiveName(actual_type.name)) |primitive| {
                    if (std.mem.eql(u8, primitive, "[]const u8")) {
                        vector_i_used = true;
                        used = true;
                        writtenMutated = true;
                        try writer.print(
                            \\        @memcpy(out[written..written+{s}.len], {s});
                            \\        {s} = out[written..written+{s}.len];
                            \\        written += {s}.len;
                            \\
                        , .{ param_name, param_name, out_param_name, param_name, param_name });
                    }
                } else {
                    vector_i_used = true;
                    used = true;
                    writtenMutated = true;
                    try writer.print(
                        \\        {{
                        \\            const cloned = {s}.clone(out[written..]);
                        \\            {s} = cloned[0];
                        \\            written += cloned[1];
                        \\        }}
                        \\
                    , .{ param_name, out_param_name });
                }
                actual_type = nrm.type;

                if (!used) {
                    try writer.print(
                        \\        _ = {s};
                        \\
                    , .{param_name});
                }

                if (!vector_i_used and vector_last_i.len > 0) {
                    try writer.print(
                        \\        _ = {s};
                        \\
                    , .{vector_last_i});
                }

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
            },
        }
    }

    if (!writtenMutated) {
        try writer.print(
            \\        written = written;
            \\
        , .{});
    }

    try writer.print(
        \\        return .{{self_out, written}};
        \\    }}
        \\
    , .{});
}
