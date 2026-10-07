const std = @import("std");
const tl = @import("tl_parser");
const generate = @import("generate.zig").generate;

pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();
    const args = try init.minimal.args.toSlice(a);

    if (args.len < 4) return error.ExpectedDialectOutputAndSchemas;
    const dialect = std.meta.stringToEnum(@import("generate.zig").Dialect, args[1]) orelse return error.InvalidDialect;
    var combined: std.ArrayList(u8) = .empty;

    for (args[3..]) |path| {
        const file = try std.Io.Dir.cwd().openFile(init.io, path, .{});
        defer file.close(init.io);
        var reader = file.reader(init.io, &.{});
        const data = try reader.interface.readAlloc(a, (try file.stat(init.io)).size);
        try combined.appendSlice(a, "\n---types---\n");
        try combined.appendSlice(a, data);
    }

    var diagnostic: ?tl.Diagnostic = null;
    errdefer if (diagnostic) |d| {
        const loc = d.location(combined.items);
        std.debug.print("schema:{d}:{d}: {s}\n", .{ loc.line, loc.column, d.message });
    };

    var syntax = try tl.parse(a, combined.items, &diagnostic);
    defer syntax.deinit();
    // ok

    var schema = try tl.analyze(a, &syntax, &diagnostic);
    defer schema.deinit();
    const file = try std.Io.Dir.cwd().createFile(init.io, args[2], .{});
    defer file.close(init.io);
    var writer = file.writer(init.io, &.{});
    if (dialect == .telegram) {
        var lines = std.mem.splitScalar(u8, combined.items, '\n');
        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t\r");
            if (std.mem.startsWith(u8, trimmed, "//")) {
                if (std.mem.indexOf(u8, trimmed, "LAYER")) |pos| {
                    const layer = try std.fmt.parseInt(u32, std.mem.trim(u8, trimmed[pos + 5 ..], " \t\r"), 10);
                    try writer.interface.print("pub const LAYER_VERSION: u32 = {d};\n", .{layer});
                }
            }
        }
    }
    try generate(a, &schema, dialect, &writer.interface);
    try writer.interface.flush();
}
