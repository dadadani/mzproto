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
const parser = @import("../parser/parse.zig");
const findLayer = @import("utils.zig").findLayer;
const tlPrimitiveName = @import("utils.zig").tlPrimitiveName;
const typeToZig = @import("utils.zig").typeToZig;
const normalizeName = @import("utils.zig").normalizeName;
const generateDef = @import("./defs.zig").generateDef;
const TlUnionItem = @import("utils.zig").TlUnionItem;
const TypeToZigError = @import("./utils.zig").TypeToZigError;
const GeneratorError = error{UnableToFindLayerVersion};

const unions = @import("unions.zig");

fn parseFile(allocator: std.mem.Allocator, filename: []const u8) !std.ArrayList(constructors.TLConstructor) {
    var definitions = std.ArrayList(constructors.TLConstructor){};
    errdefer {
        for (definitions.items) |*definition| {
            definition.deinit();
        }
        definitions.deinit(allocator);
    }

    const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();

    const stat = try file.stat();

    const data = try allocator.alloc(u8, stat.size);

    std.debug.assert(try file.read(data) == stat.size);
    defer allocator.free(data);

    var iterator = try parser.TlIterator.init(allocator, data);
    defer iterator.deinit();
    while (try iterator.next()) |constructor| {
        try definitions.append(allocator, constructor);
    }
    return definitions;
}

pub fn boilerplate(io: std.Io, writer: *std.Io.Writer) !void {
    if (try findLayer(io, "schema/api.tl")) |layer| {
        _ = try writer.print(
            \\//! Provides low-level, zero-allocation bindings for the Telegram (TL) API schema.
            \\//! This module contains all the data types and functions needed to serialize and
            \\//! deserialize objects for communication with the Telegram servers.
            \\//!
            \\//! Warning: This is an auto-generated file.
            \\//! Do not edit it directly, as your changes will be overwritten by the generator.
            \\//!
            \\
            \\const base = @import("base.zig");
            \\const std = @import("std");
            \\
            \\pub const LAYER_VERSION = {d};
            \\
            \\pub const MessageContainer = base.MessageContainer(TL);
            \\pub const ProtoMessage = base.ProtoMessage(TL);
            \\pub const RPCResult = base.RPCResult(TL);
            \\pub const Vector = base.Vector(TL);
            \\
            \\
        , .{layer});
    } else {
        return GeneratorError.UnableToFindLayerVersion;
    }
}

fn registerBoxedMap(allocator: std.mem.Allocator, map: *std.StringArrayHashMap(std.ArrayList(constructors.TLConstructor)), cons: std.ArrayList(constructors.TLConstructor), mtproto: bool) !void {
    for (cons.items) |constructor| {
        if (constructor.category == .Functions) {
            continue;
        }
        if (constructor.type.generic_arg != null) {
            return TypeToZigError.UnsupportedGenericArgument;
        }

        if (tlPrimitiveName(constructor.type.name) == null) {
            const name = try typeToZig(allocator, constructor.type, mtproto);
            var keep = false;
            defer {
                if (!keep) {
                    allocator.free(name);
                }
            }

            if (!map.contains(name)) {
                try map.put(name, std.ArrayList(constructors.TLConstructor){});
                keep = true;
            }

            const list = map.getPtr(name).?;
            try list.append(allocator, constructor);
        }
    }
}

fn parseAndGenerateFile(allocator: std.mem.Allocator, filename: []const u8, writer: *std.Io.Writer, tl_union_list: *std.ArrayList(TlUnionItem), mtproto: bool) !void {
    var defs = try parseFile(allocator, filename);
    defer {
        for (defs.items) |*item| {
            item.deinit();
        }
        defs.deinit(allocator);
    }

    var boxed_map = std.StringArrayHashMap(std.ArrayList(constructors.TLConstructor)).init(allocator);
    defer {
        var iterator = boxed_map.iterator();
        while (iterator.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            entry.value_ptr.deinit(allocator);
        }
        boxed_map.deinit();
    }

    try registerBoxedMap(allocator, &boxed_map, defs, mtproto);
    try unions.generateBoxedUnions(allocator, &boxed_map, writer, mtproto);

    std.log.info("Generating code for {s}...", .{filename});
    for (defs.items) |def| {
        {
            const name = try normalizeName(allocator, def, mtproto);
            errdefer allocator.free(name);

            try tl_union_list.append(allocator, .{ .name = name, .id = def.id });
        }

        try generateDef(allocator, def, writer, mtproto);
    }
}

pub fn main() !void {

    // open the file to write the schema
    const file = try std.fs.cwd().createFile("./src/lib/tl/api.zig", .{});
    defer file.close();

    var writer = file.writer(&.{});

    var allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = allocator.deinit();

    var io = std.Io.Threaded.init(allocator.allocator());
    defer io.deinit();

    try boilerplate(io.io(), &writer.interface);

    var tl_union_list = std.ArrayList(TlUnionItem){};
    defer {
        for (tl_union_list.items) |item| {
            allocator.allocator().free(item.name);
        }
        tl_union_list.deinit(allocator.allocator());
    }

    try parseAndGenerateFile(allocator.allocator(), "./schema/api.tl", &writer.interface, &tl_union_list, false);
    try parseAndGenerateFile(allocator.allocator(), "./schema/mtproto.tl", &writer.interface, &tl_union_list, true);

    try unions.generateTLUnion(&tl_union_list, &writer.interface);
}
