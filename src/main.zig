const std = @import("std");

const glfw = @cImport({
    @cInclude("GLFW/glfw3.h");
});

const vk = @cImport({
    @cInclude("vulkan/vulkan.h");
});

pub fn main() !void {
    if(glfw.glfwInit() == 0) {
        std.debug.print("failed to init GLFW\n", .{});
        return;
    }

    defer glfw.glfwTerminate();

    glfw.glfwWindowHint(glfw.GLFW_CLIENT_API, glfw.GLFW_NO_API);

    const window = glfw.glfwCreateWindow(800, 600, "Zig Vulkan", null, null);

    if(window == null) {
        std.debug.print("Failed to create window\n", .{});
        return;
    }

    while (glfw.glfwWindowShouldClose(window) == 0) {
        glfw.glfwPollEvents();
    }
}
