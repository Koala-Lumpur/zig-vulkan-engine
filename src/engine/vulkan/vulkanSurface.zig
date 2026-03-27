const std = @import("std");
const glfw = @import("zglfw");
const vulkan = @import("vulkan");
const vk = @import("mod.zig");

const log = std.log.scoped(.vk);

pub const VulkanSurface = struct {
    surface: vulkan.SurfaceKHR,

    pub fn cleanup(self: *VulkanSurface, vulkanInstance: vk.VulkanInstance) void {
        vulkanInstance.instanceProxy.destroySurfaceKHR(self.surface, null);
    }

    pub fn create(window: *glfw.Window, vulkanInstance: vk.VulkanInstance) !VulkanSurface {
        var surface: vulkan.SurfaceKHR = undefined;

        const rawInstance: vulkan.Instance = vulkanInstance.instanceProxy.handle;

        glfw.createWindowSurface(rawInstance, window, null, &surface) catch |err| {
            log.err("Failed to create Vulkan surface: {}", .{err});
            return err;
        };

        return .{ .surface = surface };
    }

    pub fn getSurfaceCapabilities(
        self: *const VulkanSurface, 
        vulkanInstance: vk.VulkanInstance,
        vulkanPhysicalDevice: vk.VulkanPhysicalDevice
        ) !vulkan.SurfaceCapabilitiesKHR {
        return try vulkanInstance.instanceProxy.getPhysicalDeviceSurfaceCapabilitiesKHR(vulkanPhysicalDevice.physicalDevice, self.surface);
    }

    pub fn getSurfaceFormat(
        self: *const VulkanSurface, 
        allocator: std.mem.Allocator,
        vulkanInstance: vk.VulkanInstance,
        vulkanPhysicalDevice: vk.VulkanPhysicalDevice
        ) !vulkan.SurfaceFormatKHR {
        const preferred = vulkan.SurfaceFormatKHR {
            .format = .b8g8r8a8_srgb,
            .color_space = .srgb_nonlinear_khr,
        };

        const surfaceFormats = try vulkanInstance.instanceProxy.getPhysicalDeviceSurfaceFormatsAllocKHR(
            vulkanPhysicalDevice.physicalDevice, 
            self.surface, 
            allocator,
        );
        defer allocator.free(surfaceFormats);

        for (surfaceFormats) |surfaceFormat| {
            if (std.mem.eql(surfaceFormat, preferred)) {
                return preferred;
            }
        }

        if (surfaceFormats.len == 0) {
            return error.NoSurfaceFormats;
        }

        return surfaceFormats[0];
    }
};
