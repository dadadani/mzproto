const std = @import("std");

pub fn add(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const parser = b.createModule(.{ .root_source_file = b.path("src/generator/tl/root.zig"), .target = b.graph.host });
    const generator = b.addExecutable(.{ .name = "tlgen", .root_module = b.createModule(.{
        .root_source_file = b.path("src/generator/tlgen/main.zig"),
        .target = b.graph.host,
        .imports = &.{.{ .name = "tl_parser", .module = parser }},
    }) });
    b.step("tlgen", "Build and install the standalone tlgen generator").dependOn(&b.addInstallArtifact(generator, .{}).step);
    const base = b.createModule(.{ .root_source_file = b.path("src/tlbase.zig"), .target = target, .optimize = optimize });
    const tests = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/generator/tlgen/tests.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "tl_base", .module = base }},
    }) });
    const inputs = .{
        .{ "storage", "storage", &[_][]const u8{"src/generator/tlgen/storage.tl"} },
        .{ "storage_v1", "storage", &[_][]const u8{"src/generator/tlgen/storage_v1.tl"} },
        .{ "telegram", "telegram", &[_][]const u8{"src/generator/tlgen/telegram.tl"} },
        .{ "tl", "telegram", &[_][]const u8{ "src/generator/schema/api.tl", "src/generator/schema/mtproto.tl" } },
    };
    const generation_step = b.step("generate-tlgen", "Generate the TL codec modules");
    inline for (inputs) |input| {
        const run = b.addRunArtifact(generator);
        run.addArg(input[1]);
        const output = run.addOutputFileArg(input[0] ++ ".zig");
        for (input[2]) |path| run.addFileArg(b.path(path));
        tests.root_module.addImport(input[0], b.createModule(.{ .root_source_file = output, .target = target, .optimize = optimize, .imports = &.{.{ .name = "tl_base", .module = base }} }));
        generation_step.dependOn(&run.step);
    }
    const step = b.step("test-tlgen", "Test tlgen cursors and generated Telegram/storage codecs");
    step.dependOn(&b.addRunArtifact(tests).step);
    const generator_tests = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/generator/tlgen/generate_tests.zig"),
        .target = b.graph.host,
        .imports = &.{.{ .name = "tl_parser", .module = parser }},
    }) });
    step.dependOn(&b.addRunArtifact(generator_tests).step);
}
