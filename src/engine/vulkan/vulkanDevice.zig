const std = @import("std");
const vulkan = @import("vulkan");
const vk = @import("mod.zig");

const log = std.log.scoped(.vk);

pub const VulkanDevice = struct {
    deviceProxy: vulkan.DeviceProxy,
 
    pub fn create(
        allocator: std.mem.Allocator, 
        vulkanInstance: vk.VulkanInstance,
        vulkanPhysicalDevice: vk.VulkanPhysicalDevice
    ) !VulkanDevice {
        
        var extensions = try std.ArrayList([*:0]const u8).initCapacity(allocator, 0);
        defer extensions.deinit(allocator);
        try extensions.append(allocator, vulkan.extensions.khr_swapchain.name);

        const extensionProperties = try vulkanInstance.instanceProxy.enumerateDeviceExtensionPropertiesAlloc(
            vulkanPhysicalDevice.physicalDevice, null, allocator
        );
        defer allocator.free(extensionProperties);

        for (extensionProperties) |prop| {
            const name = std.mem.sliceTo(&prop.extension_name, 0);
            if (std.mem.eql(u8, name, "VK_KHR_portability_subset")) {
                try extensions.append(allocator, "VK_KHR_portability_subset");
                break;
            }
        }

        const priority = [_]f32{0};
        const queueCreateInfo = [_]vulkan.DeviceQueueCreateInfo {
            .{
                .queue_family_index = vulkanPhysicalDevice.queuesInfo.graphics_family,
                .queue_count = 1,
                .p_queue_priorities = &priority,
            },
            .{
                .queue_family_index = vulkanPhysicalDevice.queuesInfo.present_family,
                .queue_count = 1,
                .p_queue_priorities = &priority,
            },
        };

        const queueCount: u32 = if (vulkanPhysicalDevice.queuesInfo.graphics_family == vulkanPhysicalDevice.queuesInfo.present_family)
            1
        else
            2;

        const features13 = vulkan.PhysicalDeviceVulkan13Features {
            .dynamic_rendering = vulkan.Bool32.true,
            .synchronization_2 = vulkan.Bool32.true,
        };
        const features12 = vulkan.PhysicalDeviceVulkan12Features {
            .p_next = @constCast(&features13),
        };
        const features = vulkan.PhysicalDeviceFeatures {
            .sampler_anisotropy = vulkanPhysicalDevice.features.sampler_anisotropy,
        };

        const deviceCreateInfo: vulkan.DeviceCreateInfo = .{
            .queue_create_info_count = queueCount,
            .p_next = @ptrCast(&features12),
            .p_queue_create_infos = &queueCreateInfo,
            .enabled_extension_count = @intCast(extensions.items.len),
            .pp_enabled_extension_names = extensions.items.ptr,
            .p_enabled_features = @ptrCast(&features),
        };
        const device = try vulkanInstance.instanceProxy.createDevice(vulkanPhysicalDevice.physicalDevice, &deviceCreateInfo, null);

        const vulkanDevice = try allocator.create(vulkan.DeviceWrapper);
        vulkanDevice.* = vulkan.DeviceWrapper.load(device, vulkanInstance.instanceProxy.wrapper.dispatch.vkGetDeviceProcAddr.?);
        const deviceProxy = vulkan.DeviceProxy.init(device, vulkanDevice);

        return .{ .deviceProxy = deviceProxy };
    } 

    pub fn cleanup(self: *VulkanDevice, allocator: std.mem.Allocator) void {
        log.debug("Destroying Vulkan Device", .{});
        self.deviceProxy.destroyDevice(null);
        allocator.destroy(self.deviceProxy.wrapper);
    }

    pub fn wait(self: *VulkanDevice) !void {
        try self.deviceProxy.deviceWaitIdle();
    }
};
