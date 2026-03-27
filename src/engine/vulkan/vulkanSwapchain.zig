const std = @import("std");
const glfw = @import("zglfw");
const vulkan = @import("vulkan");
const vk = @import("mod.zig");

const log = std.log.scoped(.vk);

pub const AcquireResult = union(enum) {
    ok: u32,
    recreate,
};

pub const VulkanSwapchain = struct {
    extent: vulkan.Extent2D,
    imageViews: []vk.VulkanImageView,
    surfaceFormat: vulkan.SurfaceFormatKHR,
    handle: vulkan.SwapchainKHR,
    vsync: bool,

    pub fn create(
        allocator: std.mem.Allocator,
        window: *glfw.Window,
        instance: vk.VulkanInstance,
        physicalDevice: vk.VulkanPhysicalDevice,
        device: vk.VulkanDevice,
        surface: vk.VulkanSurface,
        requiredImages: u32,
        vsync: bool,
    ) !VulkanSwapchain {
        const surfaceCapabilities = try surface.getSurfaceCapabilities(instance, physicalDevice);
        const imageCount = calculateNumberOfImages(surfaceCapabilities, requiredImages);
        const extent = try calculateExtent(window, surfaceCapabilities);
        const surfaceFormat = try surface.getSurfaceFormat(allocator, instance, physicalDevice);
        const presentMode = try calculatePresentMode(allocator, instance, physicalDevice, surface.surface, vsync);

        const sameFamily = 
            physicalDevice.queuesInfo.graphics_family ==
            physicalDevice.queuesInfo.present_family;

        const queueFamilyInfo = [_]u32 {
            physicalDevice.queuesInfo.graphics_family,
            physicalDevice.queuesInfo.present_family,
        };

        const swapchain_info = vulkan.SwapchainCreateInfoKHR {
            .surface = surface.surface,
            .min_image_count = imageCount,
            .image_format = surfaceFormat.format,
            .image_color_space = surfaceFormat.color_space,
            .image_extent = extent,
            .image_array_layers = 1,
            .image_usage = .{
                .color_attachment_bit = true,
            },
            .image_sharing_mode = if (sameFamily) .exclusive else .concurrent,
            .queue_family_index_count = if (sameFamily) 0 else queueFamilyInfo.len,
            .p_queue_family_indices = if (sameFamily) null else &queueFamilyInfo,
            .pre_transform = surfaceCapabilities.current_transform,
            .composite_alpha = .{ .opaque_bit_khr = true },
            .present_mode = presentMode,
            .clipped = vulkan.Bool32.true,
            .old_swapchain = .null_handle,
        };

        const handle = try device.deviceProxy.createSwapchainKHR(&swapchain_info, null);

        const imageViews = try createImageViews(
            allocator,
            device,
            handle,
            surfaceFormat.format,
        );

        log.debug(
            "VulkanSwapchain created: {d} image, extent {d}x{d}, present mode {any}",
            .{ imageViews.len, extent.width, extent.height, presentMode },
        );

        return .{
            .extent = extent,
            .imageViews = imageViews,
            .surfaceFormat = surfaceFormat,
            .handle = handle,
            .vsync = vsync,
        };
    }

    pub fn cleanup(self: *const VulkanSwapchain, allocator: std.mem.Allocator, device: vk.VulkanDevice) void {
        for (self.imageViews) |*imageView| {
            imageView.cleanup(device);
        }
        allocator.free(self.imageViews);
        device.deviceProxy.destroySwapchainKHR(self.handle, null);
    }

    fn calculatePresentMode(
        allocator: std.mem.Allocator,
        instance: vk.VulkanInstance,
        physicalDevice: vk.VulkanPhysicalDevice,
        surface: vulkan.SurfaceKHR,
        vsync: bool,
    ) !vulkan.PresentModeKHR {
        const modes = try instance.instanceProxy.getPhysicalDeviceSurfacePresentModesAllocKHR(
            physicalDevice.physicalDevice, 
            surface,
            allocator,
        );
        defer allocator.free(modes);

        if(!vsync) {
            for (modes) |mode| {
                if (mode == .mailbox_khr) return mode;
            }
            for (modes) |mode| {
                if (mode == .immediate_khr) return mode;
            }
        }

        return .fifo_khr;
    }

    fn calculateNumberOfImages(surfaceCapabilities: vulkan.SurfaceCapabilitiesKHR, requested: u32) u32 {
        var count = if (requested > 0) requested else surfaceCapabilities.min_image_count + 1;

        if (count < surfaceCapabilities.min_image_count) {
            count = surfaceCapabilities.min_image_count;
        }

        if (surfaceCapabilities.max_image_count > 0 and count > surfaceCapabilities.max_image_count) {
            count = surfaceCapabilities.max_image_count;
        }

        return count;
    }

    fn calculateExtent(window: *glfw.Window, surfaceCapabilities: vulkan.SurfaceCapabilitiesKHR) !vulkan.Extent2D {
        if (surfaceCapabilities.current_extent.width != std.math.maxInt(u32)) {
            return surfaceCapabilities.current_extent;
        }

        const size = window.getSize();

        return .{
            .width = std.math.clamp(
                @as(u32, @intCast(size[0])),
                surfaceCapabilities.min_image_extent.width,
                surfaceCapabilities.max_image_extent.width,
            ),
            .height = std.math.clamp(
                @as(u32, @intCast(size[1])),
                surfaceCapabilities.min_image_extent.height,
                surfaceCapabilities.max_image_extent.height,
            ),
        };
    }

    fn createImageViews(
        allocator: std.mem.Allocator,
        device: vk.VulkanDevice,
        swapchain: vulkan.SwapchainKHR,
        format: vulkan.Format,
    ) ![]vk.VulkanImageView {
        const images = try device.deviceProxy.getSwapchainImagesAllocKHR(swapchain, allocator);
        defer allocator.free(images);

        const views = try allocator.alloc(vk.VulkanImageView, images.len);

        const imageViewData = vk.VulkanImageViewData {
            .format = format,
        };

        for(images, 0..) |image, i| {
            views[i] = try vk.VulkanImageView.create(device, image, imageViewData);
        }

        return views;
    }
};
