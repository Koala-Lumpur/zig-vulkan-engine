const std = @import("std");
const vulkan = @import("vulkan");
const common = @import("common");
const vk = @import("mod.zig");

const log = std.log.scoped(.vk);
const requiredExtensions = [_][*:0]const u8{vulkan.extensions.khr_swapchain.name};

const QueuesInfo = struct {
    graphics_family: u32,
    present_family: u32,
};

pub const VulkanPhysicalDevice = struct {
    features: vulkan.PhysicalDeviceFeatures,
    physicalDevice: vulkan.PhysicalDevice,
    properties: vulkan.PhysicalDeviceProperties,
    queuesInfo: QueuesInfo,
    memoryProperties: vulkan.PhysicalDeviceMemoryProperties,

    pub fn create(
        allocator: std.mem.Allocator, 
        constants: common.common.Constants,
        instance: vulkan.InstanceProxy, 
        vulkanSurface: vk.VulkanSurface
    ) !VulkanPhysicalDevice {
        
        const physicalDevices = try instance.enumeratePhysicalDevicesAlloc(allocator);
        defer allocator.free(physicalDevices);

        var list = try std.ArrayList(VulkanPhysicalDevice).initCapacity(allocator, 1);
        defer list.deinit(allocator);

        for (physicalDevices) |physicalDevice| {
            const properties = instance.getPhysicalDeviceProperties(physicalDevice);
            const memoryProperties = instance.getPhysicalDeviceMemoryProperties(physicalDevice);
            const features = instance.getPhysicalDeviceFeatures(physicalDevice);
            log.debug("Checking [{s}] physical device", .{properties.device_name});

            if (!try checkExtensionSupport(instance, physicalDevice, allocator)) {
                continue;
            }

            if (try hasGraphicsQueue(instance, physicalDevice, vulkanSurface, allocator)) |queuesInfo| {
                const vulkanPhysicalDevice = VulkanPhysicalDevice {
                    .features = features,
                    .physicalDevice = physicalDevice,
                    .properties = properties,
                    .queuesInfo = queuesInfo,
                    .memoryProperties = memoryProperties,
                };
                const name_slice = std.mem.sliceTo(&vulkanPhysicalDevice.properties.device_name, 0);
                if (std.mem.eql(u8, constants.gpu, name_slice)) {
                    try list.insert(allocator, 0, vulkanPhysicalDevice);
                    break;
                }

                if (properties.device_type == vulkan.PhysicalDeviceType.discrete_gpu) {
                    try list.insert(allocator, 0, vulkanPhysicalDevice);
                } else {
                    try list.append(allocator, vulkanPhysicalDevice);
                }
            }
        }
        if (list.items.len == 0) {
            return error.NoSuitablePhysicalDevice;
        }
        const result = list.items[0];

        log.debug("Selected [{s}] physical device", .{result.properties.device_name});
        return result;
    }

    fn checkExtensionSupport(
        instance: vulkan.InstanceProxy,
        physicalDevice: vulkan.PhysicalDevice,
        allocator: std.mem.Allocator,
    ) !bool {
        const extensionProperties = try instance.enumerateDeviceExtensionPropertiesAlloc(physicalDevice, null, allocator);
        defer allocator.free(extensionProperties);

        for (requiredExtensions) |extension| {
            for (extensionProperties) |properties| {
                if (std.mem.eql(u8, std.mem.span(extension), std.mem.sliceTo(&properties.extension_name, 0))) {
                    break;
                }
            } else {
                return false;
            }
        }

        return true;
    }

    fn hasGraphicsQueue(
        instance: vulkan.InstanceProxy,
        physicalDevice: vulkan.PhysicalDevice,
        vulkanSurface: vk.VulkanSurface,
        allocator: std.mem.Allocator,
    ) !?QueuesInfo {
        const families = try instance.getPhysicalDeviceQueueFamilyPropertiesAlloc(physicalDevice, allocator);
        defer allocator.free(families);

        var graphics_family: ?u32 = null;
        var present_family: ?u32 = null;

        const surfaceKhr = vulkanSurface.surface;

        for (families, 0..) |properties, i| {
            const family: u32 = @intCast(i);

            if(graphics_family == null and properties.queue_count > 0 and properties.queue_flags.graphics_bit) {
                graphics_family = family;
            }

            if(present_family == null and properties.queue_count > 0 and
                (try instance.getPhysicalDeviceSurfaceSupportKHR(physicalDevice, family, surfaceKhr)) == vulkan.Bool32.true)
            {
                present_family = family;
            }
        }

        if (graphics_family != null and present_family != null) {
            return QueuesInfo {
                .graphics_family = graphics_family.?,
                .present_family = present_family.?,
            };
        }

        return null;
    }
};
