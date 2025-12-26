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
const types = @import("../parser/types.zig");
const TLParameterType = @import("../parser/parameters_type.zig").TLParameterType;
const TLType = @import("../parser/types.zig").TLType;

/// Finds the layer version from a TL schema file.
///
/// The file should contain a comment like `//LAYER #`.
pub fn findLayer(io: std.Io, filename: []const u8) !?i32 {
    const LAYER_DEF = "LAYER";
    const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();

    var buffer: [2048]u8 = undefined;

    var reader = file.reader(io, &buffer);

    // TODO: check this thing. idk if it's the ideal thing do to, I don't understand the new i/o api right now
    while (try reader.interface.takeDelimiter('\n')) |layer| {
        if (std.mem.startsWith(u8, layer, "//")) {
            if (std.mem.indexOf(u8, layer, LAYER_DEF)) |pos| {
                return try std.fmt.parseInt(i32, std.mem.trim(u8, layer[pos + LAYER_DEF.len ..], " "), 10);
            }
        }
    }
    return null;
}

pub fn normalizeName(allocator: std.mem.Allocator, def: anytype, mtproto: bool) ![]u8 {
    var list = std.ArrayList(u8){};
    defer list.deinit(allocator);

    if (mtproto) {
        _ = try list.appendSlice(allocator, "Proto");
    }
    for (def.namespaces.items) |namespace| {
        _ = try list.append(allocator, std.ascii.toUpper(namespace[0]));
        _ = try list.appendSlice(allocator, namespace[1..]);
    }

    var i: usize = 0;
    var make_upper = true;
    for (def.name) |c| {
        if (c == '_') {
            make_upper = true;
            continue;
        }
        if (i == 0 or make_upper) {
            _ = try list.append(allocator, std.ascii.toUpper(c));
            make_upper = false;
        } else {
            _ = try list.append(allocator, c);
        }
        i += 1;
    }

    return list.toOwnedSlice(allocator);
}

pub fn safeStrParam(in: []const u8) []const u8 {
    if (std.mem.eql(u8, in, "test")) {
        return "is_test";
    }
    if (std.mem.eql(u8, in, "error")) {
        return "error_desc";
    }
    return in;
}

pub const TypeToZigError = error{ UnsupportedFlagType, UnsupportedNamespacesInType, UnsupportedGenericArgument, UnsupportedNestedGenericArguments, UnsupportedTrueTypeVariant, UnsupportedGenericReferenceVariant };

fn strTypeToZig(allocator: std.mem.Allocator, ty: *const types.TLType, mtproto: bool) ![]u8 {
    if (std.mem.eql(u8, ty.name, "string") or std.mem.eql(u8, ty.name, "bytes")) {
        return try allocator.dupe(u8, "[]const u8");
    }

    if (std.mem.eql(u8, ty.name, "int")) {
        return try allocator.dupe(u8, "u32");
    }

    if (std.mem.eql(u8, ty.name, "long")) {
        return try allocator.dupe(u8, "u64");
    }

    if (std.mem.eql(u8, ty.name, "double")) {
        return try allocator.dupe(u8, "f64");
    }

    if (std.mem.eql(u8, ty.name, "int128")) {
        return try allocator.dupe(u8, "u128");
    }

    if (std.mem.eql(u8, ty.name, "int256")) {
        return try allocator.dupe(u8, "u256");
    }

    if (std.mem.eql(u8, ty.name, "Bool")) {
        return try allocator.dupe(u8, "bool");
    }

    const normalized = try normalizeName(allocator, ty, mtproto);
    defer allocator.free(normalized);

    return try std.fmt.allocPrint(allocator, "I{s}", .{normalized});
}

pub fn parameterTypeToZig(allocator: std.mem.Allocator, in: TLParameterType, mtproto: bool) ![]u8 {
    if (in == .Flags) {
        return TypeToZigError.UnsupportedFlagType;
    }

    const normal = in.Normal;

    if (std.mem.eql(u8, normal.type.name, "true")) {
        if (in.Normal.flag == null) {
            return TypeToZigError.UnsupportedTrueTypeVariant;
        }
    }

    if (normal.type.generic_ref) {
        if (normal.flag != null) {
            return TypeToZigError.UnsupportedGenericReferenceVariant;
        }
    }

    const str_type = try typeToZig(allocator, normal.type, mtproto);
    defer allocator.free(str_type);

    return std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ if (normal.flag != null and !std.mem.eql(u8, normal.type.name, "true")) "?" else "", str_type, if (normal.flag != null and !std.mem.eql(u8, normal.type.name, "true")) " = null" else "" });
}

pub fn typeToZig(allocator: std.mem.Allocator, in: *const TLType, mtproto: bool) ![]u8 {
    if (in.generic_arg) |generic_arg| {
        if (!std.mem.eql(u8, in.name, "Vector")) {
            return TypeToZigError.UnsupportedGenericArgument;
        }
        const ty = try typeToZig(allocator, generic_arg, mtproto);
        defer allocator.free(ty);

        return std.fmt.allocPrint(allocator, "[]const {s}", .{ty});
    }

    if (std.mem.eql(u8, in.name, "true")) {
        if (in.generic_arg != null) {
            return TypeToZigError.UnsupportedTrueTypeVariant;
        }

        return allocator.dupe(u8, "bool = false");
    }

    if (in.generic_ref) {
        if (in.generic_arg != null) {
            return TypeToZigError.UnsupportedGenericReferenceVariant;
        }

        return allocator.dupe(u8, "TL");
    }

    const strType = try strTypeToZig(allocator, in, mtproto);

    return strType;
}

pub fn tlPrimitiveName(name: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, name, "int")) {
        return "u32";
    } else if (std.mem.eql(u8, name, "long")) {
        return "u64";
    } else if (std.mem.eql(u8, name, "string") or std.mem.eql(u8, name, "bytes")) {
        return "[]const u8";
    } else if (std.mem.eql(u8, name, "double")) {
        return "f64";
    } else if (std.mem.eql(u8, name, "int128")) {
        return "u128";
    } else if (std.mem.eql(u8, name, "int256")) {
        return "u256";
    } else if (std.mem.eql(u8, name, "Bool")) {
        return "bool";
    } else {
        return null;
    }
}

pub const TlUnionItem = struct {
    name: []u8,
    id: u32,
};
