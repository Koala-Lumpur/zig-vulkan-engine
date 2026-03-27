const std = @import("std");
const glfw = @import("zglfw");
const common = @import("common");
const vk = @import("mod.zig");

pub const VulkanContext = struct {
    constants: common.common.Constants,
    vulkanInstance: vk.VulkanInstance,
    vulkanDevice: vk.VulkanDevice,
    vulkanPhysicalDevice: vk.VulkanPhysicalDevice,
    vulkanSurface: vk.VulkanSurface,

    pub fn create(
        allocator: std.mem.Allocator,
        constants: common.common.Constants, 
        window: *glfw.Window 
        ) !VulkanContext {
        const vulkanInstance = try vk.VulkanInstance.create(allocator, constants.validation);
        const vulkanSurface = try vk.VulkanSurface.create(window, vulkanInstance);
        const vulkanPhysicalDevice = try vk.VulkanPhysicalDevice.create(
            allocator, 
            constants, 
            vulkanInstance.instanceProxy, 
            vulkanSurface,
        );
        const vulkanDevice = try vk.VulkanDevice.create(allocator, vulkanInstance, vulkanPhysicalDevice);

        return .{
            .constants = constants,
            .vulkanInstance = vulkanInstance,
            .vulkanDevice = vulkanDevice,
            .vulkanPhysicalDevice = vulkanPhysicalDevice,
            .vulkanSurface = vulkanSurface,
        };
    }

    pub fn cleanup(self: *VulkanContext, allocator: std.mem.Allocator) !void {
        self.vulkanDevice.cleanup(allocator);
        self.vulkanSurface.cleanup(self.vulkanInstance);
        try self.vulkanInstance.cleanup(allocator);
    }
};
