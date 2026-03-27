const vk = @import("mod.zig");
const vulkan = @import("vulkan");

pub const VulkanImageViewData = struct {
    aspectMask: vulkan.ImageAspectFlags = vulkan.ImageAspectFlags { .color_bit = true },
    baseArrayLayer: u32 = 0,
    baseMipLevel: u32 = 0,
    format: vulkan.Format,
    layerCount: u32 = 1,
    levelCount:u32 = 1,
    viewType: vulkan.ImageViewType = .@"2d",
};

pub const VulkanImageView = struct {
    format: vulkan.Format,
    image: vulkan.Image,
    view: vulkan.ImageView,

    pub fn create(
        vulkanDevice: vk.VulkanDevice,
        image: vulkan.Image,
        imageViewData: VulkanImageViewData,
    ) !VulkanImageView {
        const createInfo = vulkan.ImageViewCreateInfo {
            .image = image,
            .view_type = imageViewData.viewType,
            .format = imageViewData.format,
            .components = .{ .r = .identity, .g = .identity, .b = .identity, .a = .identity },
            .subresource_range = .{
                .aspect_mask = imageViewData.aspectMask,
                .base_mip_level = imageViewData.baseMipLevel,
                .level_count = imageViewData.levelCount,
                .base_array_layer = imageViewData.baseArrayLayer,
                .layer_count = imageViewData.layerCount,
            },
            .p_next = null,
        };
        const imageView = try vulkanDevice.deviceProxy.createImageView(&createInfo, null);

        return .{
            .format = imageViewData.format,
            .image = image,
            .view = imageView,
        };
    }

    pub fn cleanup(self: *VulkanImageView, vulkanDevice: vk.VulkanDevice) void {
        vulkanDevice.deviceProxy.destroyImageView(self.view, null);
        self.view = .null_handle;
    }
};
