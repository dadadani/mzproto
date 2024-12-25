const std = @import("std");

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

    const generator_exe = b.addExecutable(.{
        .name = "generator",
        .root_source_file = b.path("./src/generate.zig"),
        .target = target,
        .optimize = optimize,
    });

    //b.installArtifact(generator_exe);

    const run_exe = b.addRunArtifact(generator_exe);
    run_exe.cwd = b.path("./src/generator/");

    const generate_tl_step = b.step("generate_tl", "Generate the TL objects");
    generate_tl_step.dependOn(&run_exe.step);
}
