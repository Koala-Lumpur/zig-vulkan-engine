const engine = @import("mod.zig");
const std = @import("std");
const common = @import("common");
const glfw = @import("zglfw");
const vk = @import("vulkan/mod.zig");

pub const Render = struct {
    vulkanContext: vk.VulkanContext,

    pub fn cleanup(self: *Render, allocator: std.mem.Allocator) !void {
        try self.vulkanContext.vulkanDevice.wait();

        try self.vulkanContext.cleanup(allocator);
    }

    pub fn create(allocator: std.mem.Allocator, constants: common.common.Constants, window: *glfw.Window) !Render {
        const vulkanContext = try vk.VulkanContext.create(allocator, constants, window);

        return .{
            .vulkanContext = vulkanContext,
        };
    }

    pub fn render(self: *Render, engineContext: *engine.EngineContext) !void {
        _ = self;
        _ = engineContext;
    }
};
