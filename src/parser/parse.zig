const std = @import("std");

const constructor = @import("./constructors.zig");
const sections = @import("./sections.zig");
const utils = @import("./utils.zig");

const DEFINITION_SEPARATOR = ";";
const FUNCTIONS_SEPARATOR = "---functions---";
const TYPES_SEPARATOR = "---types---";

pub const ParseError = error{ UnknownSectionType, EmptyData };

pub const TlIterator = struct {
    data: []const u8,
    index: usize,
    section: sections.TLSection,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, data: []const u8) !TlIterator {
        var no_comments_data = try allocator.alloc(u8, data.len);
        errdefer allocator.free(no_comments_data);
        const new_len = try utils.removeTlComments(data, no_comments_data);
        if (new_len == 0) {
            return ParseError.EmptyData;
        }
        no_comments_data = try allocator.realloc(no_comments_data, new_len);

        return .{ .data = no_comments_data, .index = 0, .section = sections.TLSection.Types, .allocator = allocator };
    }

    pub fn deinit(self: *TlIterator) void {
        self.allocator.free(self.data);
    }

    /// Parses the next constructor from the input data.
    ///
    /// The returned object must be freed by the caller when it is no longer needed.
    /// Returns null if there are no more constructors.
    pub fn next(self: *TlIterator) !?constructor.TLConstructor {
        const cn = while (true) {
            if (self.index >= self.data.len) {
                return null;
            }

            const end = end: {
                if (std.mem.indexOf(u8, self.data[self.index..], DEFINITION_SEPARATOR)) |pos| {
                    break :end self.index + pos;
                }
                break :end self.data.len;
            };
            const trm = utils.trimWhitespace(self.data[self.index..end]);
            self.index = end + DEFINITION_SEPARATOR.len;

            if (trm.len != 0) {
                break trm;
            }
        };

        const parse = try parse: {
            if (std.mem.startsWith(u8, cn, "---")) {
                if (std.mem.startsWith(u8, cn, FUNCTIONS_SEPARATOR)) {
                    self.section = sections.TLSection.Functions;
                    return self.next();
                    //break :parse utils.trimWhitespace(std.mem.trimLeft(u8, self.data[self.index..], FUNCTIONS_SEPARATOR));
                } else if (std.mem.startsWith(u8, cn, TYPES_SEPARATOR)) {
                    self.section = sections.TLSection.Types;
                    return self.next();
                    //break :parse utils.trimWhitespace(std.mem.trimLeft(u8, self.data[self.index..], TYPES_SEPARATOR));
                } else {
                    break :parse ParseError.UnknownSectionType;
                }
            }
            break :parse cn;
        };

        return try constructor.TLConstructor.parse(self.allocator, parse, self.section);
    }
};

test "parse constructor" {
    const allocator = std.testing.allocator;
    const data = "//tesst\n    inputFileASD#fa4f0bb5      id:long     parts:int    name:string =    InputFile   ;";
    var iterator = try TlIterator.init(allocator, data);
    defer iterator.deinit();

    const c = try iterator.next();
    if (c) |cc| {
        std.debug.print("{s}\n", .{cc.name});

        defer cc.deinit();
    } else {
        std.debug.print("no constructor\n", .{});
    }
}
