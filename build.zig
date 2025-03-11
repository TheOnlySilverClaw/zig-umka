const std = @import("std");

pub fn build(b: *std.Build) void {

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("binding",.{
        .root_source_file = b.path("src/binding.zig"),
        .target = target,
        .optimize = optimize
    });

    _ = b.addModule("wrapper",.{
        .root_source_file = b.path("src/wrapper.zig"),
        .target = target,
        .optimize = optimize
    });
}
