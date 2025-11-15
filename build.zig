const std = @import("std");
const log = std.log;
const fs = std.fs;

pub fn build(b: *std.Build) void {

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const binding = b.addModule("binding", .{
        .root_source_file = b.path("src/binding.zig"),
        .target = target,
        .optimize = optimize
    });

    const wrapper = b.addModule("wrapper",.{
        .root_source_file = b.path("src/wrapper.zig"),
        .target = target,
        .optimize = optimize
    });

    wrapper.addImport("c", binding);
}