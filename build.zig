const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-engine",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const vulkan_headers = b.dependency("vulkan_headers", .{});
    const vulkan = b.dependency("vulkan", .{
        .registry = vulkan_headers.path("registry/vk.xml"),
    }).module("vulkan-zig");
    exe.root_module.addImport("vulkan", vulkan);

    const zglfw = b.dependency("zglfw", .{
        .target = target,
        .optimize = optimize,
        .import_vulkan = true,
    });

    const zglfw_mod = zglfw.module("root");
    zglfw_mod.addImport("vulkan", vulkan);
    exe.root_module.addImport("zglfw", zglfw_mod);

    if (target.result.os.tag != .emscripten) {
        exe.linkLibrary(zglfw.artifact("glfw"));
    }

    const common = b.addModule("common", .{ .root_source_file = b.path("src/engine/common/mod.zig") });
    exe.root_module.addImport("common", common);

    const engine = b.addModule("engine", .{ .root_source_file = b.path("src/engine/mod.zig") });
    engine.addImport("common", common);
    engine.addImport("zglfw", zglfw_mod);
    engine.addImport("vulkan", vulkan);
    exe.root_module.addImport("engine", engine);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
