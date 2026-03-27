const vulkan = @import("vulkan");
const vk = @import("mod.zig");

pub const VulkanQueue = struct {
    handle: vulkan.Queue,
    family: u32,

    pub fn create(vulkanContext: *const vk.VulkanContext, family: u32) VulkanQueue {
        return .{
            .handle = vulkanContext.vulkanDevice.deviceProxy.getDeviceQueue(family, 0),
            .family = family,
        };
    }
};
