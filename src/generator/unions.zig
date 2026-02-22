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

        // toTL

        try writer.print(
            \\    pub fn toTL(self: *const {s}) TL {{
            \\        @setEvalBranchQuota(1000000);
            \\        switch (self.*) {{
            \\            inline else => |x| {{
            \\                return @unionInit(TL, base.shortTypeName(@TypeOf(x)), x);
            \\            }},
            \\        }}
            \\    }}
            \\
        , .{box.key_ptr.*});

        // END - toTl

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
                \\                size.* += (@alignOf({s}) - 1);
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
            \\                size.* += base.ensureAligned(size.*, @alignOf(base.unwrapType(@TypeOf(x))));
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
        \\    pub const Enum = std.meta.Tag(TL);
        \\
        \\    ProtoMessageContainer: *const ProtoMessageContainer,
        \\    ProtoRPCResult: *const ProtoRPCResult,
        \\    ProtoRpcError: *const ProtoRpcError,
        \\    Vector: []const TL,
        \\    Int: u32,
        \\    Bytes: []const u8,
        \\    Double: f64,
        \\    Bool: bool,
        \\    Long: u64,
        \\    ProtoFutureSalts: *const ProtoFutureSalts,
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
        \\                size.* += (@alignOf(ProtoMessageContainer) - 1);
        \\                return 4 + ProtoMessageContainer.deserializeSize(in[4..], size);  
        \\            }},
        \\            0xf35c6d01 => {{
        \\                size.* += (@alignOf(ProtoRPCResult) - 1);
        \\                return 4 + ProtoRPCResult.deserializeSize(in[4..], size);  
        \\            }},
        \\            0x2144ca19 => {{
        \\                size.* += (@alignOf(ProtoRpcError) - 1);
        \\                return 4 + ProtoRpcError.deserializeSize(in[4..], size);  
        \\            }},
        \\            0x1cb5c415 => {{
        \\                size.* += (@alignOf(Vector) - 1);
        \\                return 4 + Vector.deserializeSize(in[4..], size);  
        \\            }},
        \\
    , .{});

    for (items.items) |item| {
        try writer.print(
            \\            0x{x} => {{
            \\                size.* += (@alignOf({s}) - 1);
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
        \\            .Int, .Bool => {{
        \\                return 4;
        \\            }},
        \\            .Long, .Double => {{
        \\                return 8;
        \\            }},
        \\            .Bytes, .Vector => {{
        \\                @panic("unsupported");
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
        \\            .Bool => |x| {{
        \\                _ = base.serializeInt(if (x) @as(u32, 0x997275b5) else 0xbc799737, out[0..4]);
        \\                return 4;
        \\            }},
        \\            .ProtoMessageContainer => |x| {{
        \\                _ = base.serializeInt(@as(u32, 0x73F1F8DC), out[0..4]);
        \\                return 4 + x.serialize(out[4..]);
        \\            }},
        \\            .ProtoRPCResult => |x| {{
        \\                _ = base.serializeInt(@as(u32, 0xf35c6d01), out[0..4]);
        \\                return 4 + x.serialize(out[4..]);
        \\            }},
        \\            .ProtoRpcError => |x| {{
        \\                _ = base.serializeInt(@as(u32, 0x2144ca19), out[0..4]);
        \\                return 4 + x.serialize(out[4..]);
        \\            }},
        \\            .Vector, .Bytes, .Double => {{
        \\               unreachable;
        \\            }},
        \\            .ProtoFutureSalts => |x| {{
        \\                _ = base.serializeInt(@as(u32, 0xae500895), out[0..4]);
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

    // identify

    try writer.print(
        \\    pub fn identify(id: u32) ?TL.Enum {{
        \\        @setEvalBranchQuota(1000000);
        \\        switch (id) {{
        \\            0x73F1F8DC => {{
        \\                return .ProtoMessageContainer;
        \\            }},
        \\            0xf35c6d01 => {{
        \\                return .ProtoRPCResult;
        \\            }},
        \\            0x2144ca19 => {{
        \\                return .ProtoRpcError;
        \\            }},
        \\            0x1cb5c415 => {{
        \\                return .Vector;
        \\            }},
        \\            0xae500895 => {{
        \\                return .ProtoFutureSalts;
        \\            }},
        \\
    , .{});

    for (items.items) |item| {
        try writer.print(
            \\            0x{x} => {{
            \\                return .{s};
            \\            }},
            \\
        , .{ item.id, item.name });
    }

    try writer.print(
        \\            else => {{
        \\                return null;
        \\            }},
        \\        }}
        \\
    , .{});

    try writer.print(
        \\    }}
        \\
    , .{});

    // deserializeResultSize

    try writer.print(
        \\    pub fn getDeserializeResultSize(self: *const TL) ?*const (fn (in: []const u8, size: *usize) usize) {{
        \\        switch (self.*) {{
        \\
    , .{});

    for (items.items) |item| {
        if (item.is_function) {
            if (item.use_param) |use_param| {
                try writer.print(
                    \\            .{s} => |x| {{
                    \\                return x.{s}.getDeserializeResultSize();
                    \\            }},
                    \\
                , .{ item.name, use_param });
                continue;
            }
            try writer.print(
                \\            .{s} => {{
                \\                return {s}.deserializeResultSize;
                \\            }},
                \\
            , .{ item.name, item.name });
        }
    }

    try writer.print(
        \\            else => {{
        \\                return null;
        \\            }},
        \\        }}
        \\
    , .{});

    try writer.print(
        \\    }}
        \\
    , .{});

    // END - deserializeResult

    // deserializeResult

    try writer.print(
        \\    pub fn getDeserializeResult(self: *const TL) ?*const (fn (noalias in: []const u8, noalias out: []u8) struct {{TL, usize, usize}}) {{
        \\        switch (self.*) {{
        \\
    , .{});

    for (items.items) |item| {
        if (item.is_function) {
            if (item.use_param) |use_param| {
                try writer.print(
                    \\            .{s} => |x| {{
                    \\                return x.{s}.getDeserializeResult();
                    \\            }},
                    \\
                , .{ item.name, use_param });
                continue;
            }
            try writer.print(
                \\            .{s} => {{
                \\                return {s}.deserializeResult;
                \\            }},
                \\
            , .{ item.name, item.name });
        }
    }

    try writer.print(
        \\            else => {{
        \\                return null;
        \\            }},
        \\        }}
        \\
    , .{});

    try writer.print(
        \\    }}
        \\
    , .{});

    // END - deserializeResult

    // deserialize

    try writer.print(
        \\    pub fn deserialize(noalias in: []const u8, noalias out: []u8) struct {{TL, usize, usize}} {{
        \\        @setEvalBranchQuota(1000000);
        \\        const id = std.mem.readInt(u32, @ptrCast(in[0..4]), std.builtin.Endian.little);
        \\        switch (id) {{
        \\            0x73F1F8DC => {{
        \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(ProtoMessageContainer)));
        \\                const d = ProtoMessageContainer.deserialize(in[4..], @alignCast(out[alignment..]));
        \\                return .{{TL{{.ProtoMessageContainer = d[0]}}, alignment+d[1], 4+d[2]}};
        \\            }},
        \\            0xf35c6d01 => {{
        \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(ProtoRPCResult)));
        \\                const d = ProtoRPCResult.deserialize(in[4..], @alignCast(out[alignment..]));
        \\                return .{{TL{{.ProtoRPCResult = d[0]}}, alignment+d[1], 4+d[2]}};
        \\            }},
        \\            0x2144ca19 => {{
        \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(ProtoRPCResult)));
        \\                const d = ProtoRpcError.deserialize(in[4..], @alignCast(out[alignment..]));
        \\                return .{{TL{{.ProtoRpcError = d[0]}}, alignment+d[1], 4+d[2]}};
        \\            }},
        \\            0xae500895 => {{
        \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(ProtoMessageContainer)));
        \\                const d = ProtoFutureSalts.deserialize(in[4..], @alignCast(out[alignment..]));
        \\                return .{{TL{{.ProtoFutureSalts = d[0]}}, alignment+d[1], 4+d[2]}};
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
        \\            .Long, .Double, .Bool => {{}},
        \\            .Vector => |x| {{
        \\                size.* += base.ensureAligned(size.*, @alignOf([]const TL));
        \\                size.* += x.len * @sizeOf(TL);
        \\                for (x) |item| {{
        \\                    item.cloneSize(size);
        \\                }}
        \\            }},
        \\            .Bytes => |x| {{
        \\              size.* += x.len;
        \\            }},
        \\            inline else => |x| {{
        \\                size.* += base.ensureAligned(size.*, @alignOf(base.unwrapType(@TypeOf(x))));
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
        \\            .Double => |x| {{
        \\                return .{{TL{{.Double = x}}, 0}};
        \\            }},
        \\            .Bool => |x| {{
        \\                return .{{TL{{.Bool = x}}, 0}};
        \\            }},
        \\            .Bytes => |x| {{
        \\                @memcpy(out[0..x.len], x);
        \\                return .{{TL{{.Bytes = out[0..x.len]}}, x.len}};
        \\            }},
        \\            .Vector => |x| {{
        \\                var written: usize = base.ensureAligned(@intFromPtr(out[0..].ptr), @alignOf([]const TL));
        \\                var vector = @as([]TL, @alignCast(std.mem.bytesAsSlice(TL, out[written .. written + (@sizeOf(TL) * x.len)])));
        \\                for (x, 0..) |_, i| {{
        \\                    const cloned = x[i].clone(@alignCast(out[written..]));
        \\                    vector[i] = cloned[0];
        \\                    written += cloned[1];
        \\                }}
        \\                return .{{TL{{.Vector = vector}}, written}};
        \\            }},
        \\            .ProtoMessageContainer => |x| {{
        \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(@TypeOf(x))));
        \\                const cloned = x.clone(@alignCast(out[alignment..]));
        \\                return .{{TL{{.ProtoMessageContainer = cloned[0]}}, alignment+cloned[1]}};
        \\            }},
        \\            .ProtoFutureSalts => |x| {{
        \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(@TypeOf(x))));
        \\                const cloned = x.clone(@alignCast(out[alignment..]));
        \\                return .{{TL{{.ProtoFutureSalts = cloned[0]}}, alignment+cloned[1]}};
        \\            }},
        \\            .ProtoRPCResult => |x| {{
        \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(@TypeOf(x))));
        \\                const cloned = x.clone(@alignCast(out[alignment..]));
        \\                return .{{TL{{.ProtoRPCResult = cloned[0]}}, alignment+cloned[1]}};
        \\            }},
        \\            .ProtoRpcError => |x| {{
        \\                const alignment = base.ensureAligned(@intFromPtr(out.ptr), @alignOf(base.unwrapType(@TypeOf(x))));
        \\                const cloned = x.clone(@alignCast(out[alignment..]));
        \\                return .{{TL{{.ProtoRpcError = cloned[0]}}, alignment+cloned[1]}};
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

    // getDeserializeResultSize()

    try writer.print(
        \\}};
        \\
    , .{});
}
