const std = @import("std");

pub fn generateTypes(b: *std.Build, target: std.Build.ResolvedTarget) *std.Build.Step {
    const generator_exe = b.addExecutable(.{
        .name = "generator",
        .root_source_file = b.path("./src/generate.zig"),
        .target = target,
        .optimize = std.builtin.OptimizeMode.Debug,
    });

    //b.installArtifact(generator_exe);

    const run_exe = b.addRunArtifact(generator_exe);
    run_exe.cwd = b.path("./src/generator/");

    const generate_tl_step = b.step("generate_tl", "Generate the TL objects");
    generate_tl_step.dependOn(&run_exe.step);

    return generate_tl_step;
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Generate the TL code

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    var apiFileExists = true;
    std.fs.cwd().access(b.path("src/lib/tl/api.zig").getPath2(b, null), .{}) catch |err| {
        apiFileExists = if (err == error.FileNotFound) false else true;
    };
    const generator = generateTypes(b, target);

    const tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
    });

    const test_step = b.step("test", "Run unit tests");
    const run_tests = b.addRunArtifact(tests);
    if (!apiFileExists) {
        run_tests.step.dependOn(generator);
    }
    test_step.dependOn(&run_tests.step);

    const dev_exe = b.addExecutable(.{
        .name = "dev",
        .root_source_file = b.path("src/dev_remove_later.zig"),
        .target = target,
        .optimize = optimize,
    });

    const libxev = b.lazyDependency("libxev", .{ .target = target, .optimize = optimize });
    if (libxev) |xev| {
        dev_exe.root_module.addImport("xev", xev.module("xev"));

        const dev_step = b.step("dev", "Run dev shit");
        const run_dev = b.addRunArtifact(dev_exe);
        b.installArtifact(dev_exe);

        dev_step.dependOn(&run_dev.step);
    }
}
