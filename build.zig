const std = @import("std");
const builtin = @import("builtin");

// TODO: Delete this once Zig checks minimum_zig_version in build.zig.zon
fn ensureZigVersion() error{ZigIsTooOld}!void {
    const min_zig_version = std.SemanticVersion{ .major = 0, .minor = 15, .patch = 2 };

    var installed_ver = builtin.zig_version;
    installed_ver.build = null;

    if (installed_ver.order(min_zig_version) == .lt) {
        std.log.err(
            "\n" ++
                \\---------------------------------------------------------------------------
                \\
                \\Installed Zig compiler version is too old.
                \\
                \\Min. required version: {any}
                \\Installed version: {any}
                \\
                \\Please install newer version and try again.
                \\Latest version can be found here: https://ziglang.org/download/
                \\
                \\---------------------------------------------------------------------------
                \\
            ,
            .{ min_zig_version, installed_ver },
        );
        return error.ZigIsTooOld;
    }
}
pub fn build(b: *std.Build) void {
    ensureZigVersion() catch return;

    const target = b.standardTargetOptions(.{
        .whitelist = &.{
            std.Target.Query{
                .os_tag = .windows,
                .cpu_arch = .x86_64,
            },
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    const win32 = b.addModule("win32", .{
        .root_source_file = b.path("src/win32/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const gta_ppl = b.addModule("gta_ppl", .{
        .root_source_file = b.path("src/lib/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "win32", .module = win32 },
        },
    });

    const build_opts = b.addOptions();
    build_opts.addOption([]const u8, "version", "2.0.0");
    gta_ppl.addImport("build", build_opts.createModule());

    const clap = b.dependency("clap", .{});
    const chameleon = b.dependency("chameleon", .{});

    const exe = b.addExecutable(.{
        .name = "gta-ppl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "gta_ppl", .module = gta_ppl },
                .{ .name = "clap", .module = clap.module("clap") },
                .{ .name = "chameleon", .module = chameleon.module("chameleon") },
            },
        }),
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = gta_ppl,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
