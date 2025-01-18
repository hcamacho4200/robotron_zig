const std = @import("std");
const rlzb = @import("raylib-zig-bindings");

pub fn build(b: *std.Build) !void {
    // Default zig setup
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "robotron_zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Adding rlzb binding files for us to use in the main.zig file.
    const bindings = b.dependency("raylib-zig-bindings", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("rlzb", bindings.module("raylib-zig-bindings"));

    // Compiling raylib with main.zig
    // You can select which raylib C file to add in the third parameter
    var setup = try rlzb.Setup.init(b, .{ .cwd_relative = "raylib/src" }, .{});
    defer setup.deinit();

    // This line copy the raygui.h file into raylib/src to build with it.
    try setup.addRayguiToRaylibSrc(b, .{ .cwd_relative = "raygui/src/raygui.h" });

    // If you have some raylib's C #define requirements that need to be at build time.
    // You can set them here:
    // setup.setRayguiOptions(b, exe, .{});
    // setup.setRCameraOptions(b, exe, .{});
    // setup.setRlglOptions(b, exe, .{});

    // Note:
    // Some target needs specific opengl api version (RlglOption).
    // For example linux .platform = DRM requires opengl_es2
    // If you do not uncomment the setup.setRlglOptions above.
    // It will add it automatically when linking.

    // Build specific for platform.
    switch (target.result.os.tag) {
        .windows => try setup.linkWindows(b, exe),
        .macos => try setup.linkMacos(b, exe),
        .linux => try setup.linkLinux(b, exe, .{ .platform = .DESKTOP, .backend = .X11 }),
        else => @panic("Unsupported os"),
    }

    // Add everything to the exe.
    setup.finalize(b, exe);

    // Default zig build run command setup
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    var tests = b.addTest(.{
        .name = "robotron_test_zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    tests.root_module.addImport("rlzb", bindings.module("raylib-zig-bindings"));
    switch (target.result.os.tag) {
        .windows => try setup.linkWindows(b, tests),
        .macos => try setup.linkMacos(b, tests),
        .linux => try setup.linkLinux(b, tests, .{ .platform = .DESKTOP, .backend = .X11 }),
        else => @panic("Unsupported os"),
    }
    setup.finalize(b, tests);
    b.installArtifact(tests);
    setup.setRayguiOptions(b, tests, .{});

    const test_step = b.step("test", "Tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);

    // var src_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/zls.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });
    // src_tests.addModule("rlzb", bindings.module("raylib-zig-bindings"));
    // test_step.dependOn(&b.addRunArtifact(src_tests).step);

    // // Creates a step for unit testing. This only builds the test executable
    // // but does not run it.
    // const exe_unit_tests = b.addTest(.{
    //     .name = "robotron_test_zig",
    //     .root_source_file = b.path("src/main.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    // exe_unit_tests.root_module.addImport("rlzb", bindings.module("raylib-zig-bindings"));

    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // // Similar to creating the run step earlier, this exposes a `test` step to
    // // the `zig build --help` menu, providing a way for the user to request
    // // running the unit tests.
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_exe_unit_tests.step);
}
