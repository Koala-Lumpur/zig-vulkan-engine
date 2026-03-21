const std = @import("std");
const glfw = @import("zglfw");
const common = @import("common");
const vk = @import("mod.zig");

pub const VulkanContext = struct {
    constants: common.common.Constants,
    vulkanInstance: vk.instance.VulkanInstance,

    pub fn create(allocator: std.mem.Allocator, constants: common.common.Constants) !VulkanContext {
        const vulkanInstance = try vk.instance.VulkanInstance.create(allocator, constants.validation);

        return .{
            .constants = constants,
            .vulkanInstance = vulkanInstance,
        };
    }

    pub fn cleanup(self: *VulkanContext, allocator: std.mem.Allocator) !void {
        try self.vulkanInstance.cleanup(allocator);
    }
};
