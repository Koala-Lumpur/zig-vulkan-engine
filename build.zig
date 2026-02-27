const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    const mod = b.addModule("engine", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target
    });

    const exe = b.addExecutable(.{
        .name = "engine",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zig_vulkan_engine", .module = mod },
            },
        }),
    });

    const vulkan_sdk = std.process.getEnvVarOwned(b.allocator, "VULKAN_SDK") catch |err| {
        if (err == error.EnvironmentVariableNotFound) {
            // Just a warning, so ZLS doesn't crash
            std.debug.print("Warning: VULKAN_SDK not found. Autocompletion may fail.\n", .{});
            return; // Or provide a hardcoded fallback path here
        }
        return err;
    };

    const vulkan_include_str = try std.fmt.allocPrint(
        b.allocator,
        "{s}/include",
        .{vulkan_sdk},
    );

    const vulkan_lib_str = try std.fmt.allocPrint(
        b.allocator,
        "{s}/lib",
        .{vulkan_sdk},
    );

    exe.addIncludePath(.{ .cwd_relative = vulkan_include_str });
    exe.addLibraryPath(.{ .cwd_relative = vulkan_lib_str });

    const vk_lib_name =
        if (target.result.os.tag == .windows)
            "vulkan-1"
        else
            "vulkan";

    exe.linkSystemLibrary(vk_lib_name);

    exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
    exe.linkSystemLibrary("glfw");

    b.installArtifact(exe);

    const run_step = b.step("run", "Runs The App");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());
}
