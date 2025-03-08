const std = @import("std");

pub fn build(b: *std.Build) void {

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const umka_dependency = b.dependency("umka", .{});
    exe_module.addImport("umka", umka_dependency.module("umka"));

    const exe = b.addExecutable(.{
        .name = "example",
        .root_module = exe_module,
    });

    exe.linkLibC();
    // get this from the Umka repository
    exe.addObjectFile(b.path("libumka.a"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
