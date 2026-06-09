const std = @import("std");
const buildzon = @import("./build.zig.zon");
const Translator = @import("translate_c").Translator;
const mem = std.mem;
const process = std.process;

const PythonConfig = struct {
    exe: []const u8,
    include_dir: []const u8,
    platinclude_dir: ?[]const u8,
    ext_suffix: []const u8,
};

fn trimOutput(bytes: []const u8) []const u8 {
    return mem.trim(u8, bytes, &std.ascii.whitespace);
}

fn pythonConfigValue(b: *std.Build, python_exe: []const u8, expr: []const u8) []const u8 {
    return trimOutput(b.run(&.{ python_exe, "-c", expr }));
}

fn detectPythonConfig(b: *std.Build, maybe_python_exe: ?[]const u8) PythonConfig {
    const python_exe = maybe_python_exe orelse b.findProgram(.{ .names = &.{ "python3", "python" } }) orelse
        process.fatal("could not find python3 or python on PATH", .{});

    const include_dir = pythonConfigValue(b, python_exe,
        \\import sysconfig
        \\print(sysconfig.get_path("include") or "")
    );
    const platinclude_dir_raw = pythonConfigValue(b, python_exe,
        \\import sysconfig
        \\print(sysconfig.get_path("platinclude") or "")
    );
    const ext_suffix = pythonConfigValue(b, python_exe,
        \\import sysconfig
        \\print(sysconfig.get_config_var("EXT_SUFFIX") or ".so")
    );

    if (include_dir.len == 0) process.fatal("python include directory could not be detected", .{});
    if (ext_suffix.len == 0) process.fatal("python extension suffix could not be detected", .{});

    return .{
        .exe = python_exe,
        .include_dir = include_dir,
        .platinclude_dir = if (platinclude_dir_raw.len == 0 or mem.eql(u8, platinclude_dir_raw, include_dir)) null else platinclude_dir_raw,
        .ext_suffix = ext_suffix,
    };
}

fn createPythonBindings(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, python_cfg: PythonConfig) *std.Build.Module {
    const translate_c = b.dependency("translate_c", .{});
    const python_wrapper = b.addWriteFiles().add("python_wrapper.h",
        \\#define PY_SSIZE_T_CLEAN
        \\#define Py_LIMITED_API 0x030d0000
        \\#include <Python.h>
        \\
    );
    const python: Translator = .init(translate_c, .{
        .name = "python",
        .c_source_file = python_wrapper,
        .target = target,
        .optimize = optimize,
    });
    python.addSystemIncludePath(b.graph.cwdRelativePath(python_cfg.include_dir));
    if (python_cfg.platinclude_dir) |platinclude_dir| {
        python.addSystemIncludePath(b.graph.cwdRelativePath(platinclude_dir));
    }

    return python.mod;
}

fn createMzprotoOptions(b: *std.Build, enable_sqlite: bool, target_lang: TargetLanguage) *std.Build.Module {
    var options = b.addOptions();
    options.addOption([]const u8, "VERSION", buildzon.version);
    options.addOption(bool, "ENABLE_SQLITE", enable_sqlite);
    options.addOption(TargetLanguage, "TARGET_LANGUAGE", target_lang);
    return options.createModule();
}

fn buildPythonNativeSource(b: *std.Build) std.Build.LazyPath {
    const python_native_generator = b.addExecutable(.{
        .name = "generate_python_native",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/generator/mz/generate_python_native.zig"),
            .target = b.graph.host,
        }),
    });

    const python_native_generator_step = b.addRunArtifact(python_native_generator);
    python_native_generator_step.addFileArg(b.path("./src/generator/schema/mzproto.mz"));
    return python_native_generator_step.addOutputFileArg("mzproto_lib_python.zig");
}

fn buildPythonExtension(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, mzproto_internal: *std.Build.Module, mzproto_bridge: *std.Build.Module, python_mod: *std.Build.Module, python_cfg: PythonConfig, native_source: std.Build.LazyPath) *std.Build.Step.InstallArtifact {
    const extension_module = b.createModule(.{
        .root_source_file = native_source,
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "python", .module = python_mod },
            .{ .name = "mzproto_internal", .module = mzproto_internal },
            .{ .name = "mzproto_bridge", .module = mzproto_bridge },
        },
    });
    const python_ext = b.addLibrary(.{
        .name = "mzproto_native",
        .root_module = extension_module,
        .linkage = .dynamic,
        .version = null,
    });
    python_ext.linker_allow_shlib_undefined = true;
    return b.addInstallArtifact(python_ext, .{
        .dest_sub_path = b.fmt("mzproto/_native{s}", .{python_cfg.ext_suffix}),
        .dylib_symlinks = false,
        .h_dir = .disabled,
    });
}

fn buildPythonPackage(b: *std.Build) std.Build.LazyPath {
    const python_generator = b.addExecutable(.{
        .name = "generate_python",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/generator/mz/generate_python.zig"),
            .target = b.graph.host,
        }),
    });

    const python_generator_step = b.addRunArtifact(python_generator);
    python_generator_step.addFileArg(b.path("./src/generator/schema/mzproto.mz"));
    return python_generator_step.addOutputFileArg("__init__.py");
}

const TargetLanguage = enum {
    zig,
    python,
};

fn buildBridge(b: *std.Build, lang: TargetLanguage) std.Build.LazyPath {
    const src_path = switch (lang) {
        .python => b.path("./src/generator/mz/generate_python_bridge.zig"),
        .zig => b.path("./src/generator/mz/generate_zig_bridge.zig"),
    };

    const bridge_generator = b.addExecutable(.{
        .name = "bridge_generator",
        .root_module = b.createModule(.{
            .root_source_file = src_path,
            .target = b.graph.host,
        }),
    });

    const bridge_generator_step = b.addRunArtifact(bridge_generator);

    const filename = b.fmt("mz_bridge_{s}.zig", .{@tagName(lang)});
    defer b.allocator.free(filename);

    bridge_generator_step.addFileArg(b.path("./src/generator/schema/mzproto.mz"));
    const bridge_path = bridge_generator_step.addOutputFileArg(filename);
    return bridge_path;
}

fn buildTl(b: *std.Build) std.Build.LazyPath {
    const tl_generator = b.addExecutable(.{
        .name = "generate_tl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("./src/generator/main.zig"),
            .target = b.graph.host,
        }),
    });

    const tl_generator_step = b.addRunArtifact(tl_generator);
    const tl_api_path = tl_generator_step.addOutputFileArg("tl_api.zig");
    tl_generator_step.addFileArg(b.path("./src/generator/schema/api.tl"));
    tl_generator_step.addFileArg(b.path("./src/generator/schema/mtproto.tl"));
    return tl_api_path;
}

fn buildZigApi(b: *std.Build) std.Build.LazyPath {
    const api_gen = b.addExecutable(.{
        .name = "zig_api_generator",
        .root_module = b.createModule(.{
            .root_source_file = b.path("./src/generator/mz/generate_zig_api.zig"),
            .target = b.graph.host,
        }),
    });

    const api_step = b.addRunArtifact(api_gen);

    api_step.addFileArg(b.path("./src/generator/schema/mzproto.mz"));
    const api_path = api_step.addOutputFileArg("mzproto_public_api.zig");
    return api_path;
}

// Although this function looks imperative, it does not perform the build
// directly and instead it mutates the build graph (`b`) that will be then
// executed by an external runner. The functions in `std.Build` implement a DSL
// for defining build steps and express dependencies between them, allowing the
// build runner to parallelize the build automatically (and the cache system to
// know when a step doesn't need to be re-run).
pub fn build(b: *std.Build) void {
    // Standard target options allow the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    // It's also possible to define more custom flags to toggle optional features
    // of this build script using `b.option()`. All defined flags (including
    // target and optimize options) will be listed when running `zig build --help`
    // in this directory.

    const sqlite = b.dependency("sqlite", .{
        .optimize = optimize,
        .target = target,
    });

    _ = sqlite;

    const enable_sqlite = b.option(bool, "enable-sqlite", "Whether the sqlite storage backend should be enabled or not (default: true)") orelse false;

    const target_lang = b.option(TargetLanguage, "target-language", "Select the language that mzproto should target (default: zig)") orelse TargetLanguage.zig;

    const python_exe = b.option([]const u8, "python-exe", "(Only for Python target) Path of the Python interpreter used to build the extension") orelse null;

    const options_module = createMzprotoOptions(b, enable_sqlite, target_lang);

    // First of all, we generate the tl api from the .tl scheme. This is the same for all languages we target.
    const tl_base = b.addModule("tl_base", .{
        .root_source_file = b.path("./src/tl_base.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tl = b.addModule("tl", .{
        .root_source_file = buildTl(b),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "tl_base", .module = tl_base },
        },
    });

    // The bridge api is an intermediary api that sits between zig and the target language,
    //  allowing us to mantain a single codebase for all the available methods
    const bridge = b.addModule("mzproto_bridge", .{
        .root_source_file = buildBridge(b, target_lang),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "mzproto_options", .module = options_module },
        },
    });

    // The "internal api", this accepts bridge types
    const internal_api = b.addModule("mzproto_internal", .{
        .root_source_file = b.path("src/bridged_api.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            //  .{ .name = "sqlite", .module = sqlite.module("sqlite") },
            .{ .name = "mzproto_options", .module = options_module },
            .{ .name = "tl_base", .module = tl_base },
            .{ .name = "tl", .module = tl },
            .{ .name = "mzproto_bridge", .module = bridge },
        },
    });
    internal_api.addIncludePath(b.path("./src/lib/crypto/"));
    internal_api.addCSourceFile(.{
        .file = b.path("./src/lib/crypto/pq.c"),
    });

    bridge.addImport("mzproto_internal", internal_api);

    // now, depending on the language that we want to target, we need to change some things...
    switch (target_lang) {
        .python => {
            // Detect the python environment in our host
            const python_cfg = detectPythonConfig(b, python_exe);
            const python_module = createPythonBindings(b, target, optimize, python_cfg);

            bridge.addImport("python", python_module);

            const python_step = b.default_step;

            const python_package = buildPythonPackage(b);
            const install_python_package = b.addInstallLibFile(python_package, "mzproto/__init__.py");
            const install_python_methods = b.addInstallLibFile(b.path("src/py/mzproto/_methods.py"), "mzproto/_methods.py");
            const python_native_source = buildPythonNativeSource(b);

            const install_python = buildPythonExtension(b, target, optimize, internal_api, bridge, python_module, python_cfg, python_native_source);
            python_step.dependOn(&install_python_package.step);
            python_step.dependOn(&install_python_methods.step);
            python_step.dependOn(&install_python.step);
        },
        .zig => {
            const public_api = b.addModule("mzproto", .{
                .root_source_file = buildZigApi(b),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "mzproto_bridge", .module = bridge },
                    .{ .name = "mzproto_internal", .module = internal_api },
                },
            });

            public_api.addAnonymousImport("mzproto_internal_methods", .{
                .root_source_file = b.path("./src/methods_api.zig"),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "mzproto", .module = public_api },
                },
            });

            bridge.addImport("mzproto", public_api);

        

            const dev_exe = b.addExecutable(.{
                .name = "dev",
                .root_module = b.createModule(.{
                    .root_source_file = b.path("src/dev_remove_later.zig"),
                    .target = target,
                    .optimize = optimize,
                    .imports = &.{
                        .{ .name = "mzproto", .module = public_api },
                    },
                }),
            });


            const install_dev = b.addInstallArtifact(dev_exe, .{});
            b.default_step.dependOn(&install_dev.step);
        },
    }
}
