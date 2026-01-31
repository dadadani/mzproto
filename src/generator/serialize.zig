const std = @import("std");
const constructors = @import("../parser/constructors.zig");
const utils = @import("./utils.zig");

pub fn generateConstructorSerializeSize(allocator: std.mem.Allocator, constructor: constructors.TLConstructor, constructorName: []const u8, writer: *std.Io.Writer, mtproto: bool) !void {
    _ = mtproto;
    try writer.print(
        \\    pub fn serializeSize(self: *const {s}) usize {{
        \\
    , .{constructorName});

    if (constructor.params.items.len == 0) {
        try writer.print(
            \\        _ = self;
            \\        return 0;
            \\    }}
            \\
        , .{});
        return;
    }

    try writer.print(
        \\        var size: usize = 0;
        \\
    , .{});

    var self_used = false;

    for (constructor.params.items) |param| {
        if (param.type_def) {
            @panic("TODO: type_def");
        }

        switch (param.type.?) {
            .Flags => {
                try writer.print(
                    \\        size += 4; // {s}
                    \\
                , .{utils.safeStrParam(param.name)});
            },
            .Normal => |nrm| {
                if (std.mem.eql(u8, nrm.type.name, "true")) {
                    continue;
                }
                self_used = true;

                var param_name = try std.fmt.allocPrint(allocator, "self.{s}", .{utils.safeStrParam(param.name)});
                defer allocator.free(param_name);

                if (nrm.flag) |_| {
                    try writer.print(
                        \\        if ({s}) |opt_{s}| {{
                        \\
                    , .{ param_name, utils.safeStrParam(param.name) });
                    const new_param_name = try std.fmt.allocPrint(allocator, "opt_{s}", .{utils.safeStrParam(param.name)});
                    allocator.free(param_name);
                    param_name = new_param_name;
                }

                var actual_ty = nrm.type;
                var counter: u32 = 0;
                while (actual_ty.generic_arg) |generic_arg| {
                    if (!std.mem.eql(u8, actual_ty.name, "Vector")) {
                        return utils.TypeToZigError.UnsupportedGenericArgument;
                    }

                    try writer.print(
                        \\        size += 8; // vector id & size
                        \\        for ({s}) |{s}_v{d}| {{
                        \\
                    , .{ param_name, utils.safeStrParam(param.name), counter });

                    const new_param_name = try std.fmt.allocPrint(allocator, "{s}_v{d}", .{ utils.safeStrParam(param.name), counter });
                    allocator.free(param_name);
                    param_name = new_param_name;

                    actual_ty = generic_arg;
                    counter += 1;
                }

                if (std.mem.eql(u8, actual_ty.name, "Bool")) {
                    try writer.print(
                        \\        _ = {s};
                        \\        size += 4; // bool
                        \\
                    , .{param_name});
                } else if (std.mem.eql(u8, actual_ty.name, "string") or std.mem.eql(u8, actual_ty.name, "bytes")) {
                    try writer.print(
                        \\        size += base.strSerializedSize({s});
                        \\
                    , .{param_name});
                } else if (utils.tlPrimitiveName(actual_ty.name)) |_| {
                    try writer.print(
                        \\        size += @sizeOf(@TypeOf({s}));
                        \\
                    , .{param_name});
                } else {
                    try writer.print(
                        \\        size += {s}.serializeSize();
                        \\
                    , .{param_name});
                }

                actual_ty = nrm.type;
                while (actual_ty.generic_arg) |generic_arg| {
                    _ = try writer.write(
                        \\        }
                        \\
                    );

                    actual_ty = generic_arg;
                }

                if (nrm.flag != null) {
                    _ = try writer.write(
                        \\        }
                        \\
                    );
                }
            },
        }
    }

    if (!self_used) {
        try writer.print(
            \\        _ = self;
            \\
        , .{});
    }

    try writer.print(
        \\        return size;
        \\    }}
        \\
    , .{});
}

pub fn generateConstructorSerialize(allocator: std.mem.Allocator, constructor: constructors.TLConstructor, constructorName: []const u8, writer: *std.Io.Writer, mtproto: bool) !void {
    _ = mtproto;
    try writer.print(
        \\    pub fn serialize(self: *const {s}, out: []u8) usize {{
        \\
    , .{constructorName});

    if (constructor.params.items.len == 0) {
        try writer.print(
            \\        _ = self;
            \\        _ = out;
            \\        return 0;
            \\    }}
            \\
        , .{});
        return;
    }

    try writer.print(
        \\        var written: usize = 0;
        \\
    , .{});

    for (constructor.params.items) |param| {
        if (param.type_def) {
            @panic("TODO: type_def");
        }

        switch (param.type.?) {
            .Flags => {
                try writer.print(
                    \\        var flags_{s}: usize = 0;
                    \\
                , .{utils.safeStrParam(param.name)});
                var used = false;

                for (constructor.params.items) |sub_param| {
                    switch (sub_param.type.?) {
                        .Normal => |nrm| {
                            if (nrm.flag) |flag| {
                                if (std.mem.eql(u8, flag.name, utils.safeStrParam(param.name))) {
                                    used = true;
                                    if (std.mem.eql(u8, nrm.type.name, "true")) {
                                        try writer.print(
                                            \\        if (self.{s}) {{
                                            \\            flags_{s} = flags_{s} | 1 << {d};
                                            \\        }}
                                            \\
                                        , .{ utils.safeStrParam(sub_param.name), utils.safeStrParam(param.name), utils.safeStrParam(param.name), flag.index });
                                    } else {
                                        try writer.print(
                                            \\        if (self.{s} != null) {{
                                            \\            flags_{s} = flags_{s} | 1 << {d};
                                            \\        }}
                                            \\
                                        , .{ utils.safeStrParam(sub_param.name), utils.safeStrParam(param.name), utils.safeStrParam(param.name), flag.index });
                                    }
                                }
                            }
                        },
                        else => {},
                    }
                }

                if (!used) {
                    try writer.print(
                        \\        flags_{s} = flags_{s};
                        \\
                    , .{ utils.safeStrParam(param.name), utils.safeStrParam(param.name) });
                }

                try writer.print(
                    \\        written += base.serializeInt(flags_{s}, out[written..written+4]);
                    \\
                , .{utils.safeStrParam(param.name)});
            },
            .Normal => |nrm| {
                if (std.mem.eql(u8, nrm.type.name, "true")) {
                    continue;
                }

                var param_name = try std.fmt.allocPrint(allocator, "self.{s}", .{utils.safeStrParam(param.name)});
                defer allocator.free(param_name);

                if (nrm.flag) |_| {
                    try writer.print(
                        \\        if ({s}) |opt_{s}| {{
                        \\
                    , .{ param_name, utils.safeStrParam(param.name) });
                    const new_param_name = try std.fmt.allocPrint(allocator, "opt_{s}", .{utils.safeStrParam(param.name)});
                    allocator.free(param_name);
                    param_name = new_param_name;
                }

                var actual_ty = nrm.type;
                var counter: u32 = 0;
                while (actual_ty.generic_arg) |generic_arg| {
                    if (!std.mem.eql(u8, actual_ty.name, "Vector")) {
                        return utils.TypeToZigError.UnsupportedGenericArgument;
                    }

                    try writer.print(
                        \\        written += base.serializeInt(@as(u32, 0x1cb5c415), out[written..written+4]);
                        \\        written += base.serializeInt(@as(u32, @intCast({s}.len)), out[written..written+4]);
                        \\        for ({s}) |{s}_v{d}| {{
                        \\
                    , .{ param_name, param_name, utils.safeStrParam(param.name), counter });

                    const new_param_name = try std.fmt.allocPrint(allocator, "{s}_v{d}", .{ utils.safeStrParam(param.name), counter });
                    allocator.free(param_name);
                    param_name = new_param_name;

                    actual_ty = generic_arg;
                    counter += 1;
                }

                if (std.mem.eql(u8, actual_ty.name, "Bool")) {
                    try writer.print(
                        \\        written += base.serializeInt(if ({s}) @as(u32, 0x997275b5) else @as(u32, 0xbc799737), out[written..written+4]);
                        \\
                    , .{param_name});
                } else if (std.mem.eql(u8, actual_ty.name, "string") or std.mem.eql(u8, actual_ty.name, "bytes")) {
                    try writer.print(
                        \\        written += base.serializeString({s}, out[written..]);
                        \\
                    , .{param_name});
                } else if (utils.tlPrimitiveName(actual_ty.name)) |_| {
                    try writer.print(
                        \\        written += base.serializeInt({s}, out[written..]);
                        \\
                    , .{param_name});
                } else {
                    try writer.print(
                        \\        written += {s}.serialize(out[written..]);
                        \\
                    , .{param_name});
                }

                actual_ty = nrm.type;
                while (actual_ty.generic_arg) |generic_arg| {
                    _ = try writer.write(
                        \\        }
                        \\
                    );

                    actual_ty = generic_arg;
                }

                if (nrm.flag != null) {
                    _ = try writer.write(
                        \\        }
                        \\
                    );
                }
            },
        }
    }

    try writer.print(
        \\        return written;
        \\    }}
        \\
    , .{});
}
