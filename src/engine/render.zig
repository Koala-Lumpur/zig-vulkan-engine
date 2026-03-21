const engine = @import("mod.zig");
const std = @import("std");
const common = @import("common");
const vk = @import("vulkan/mod.zig");

pub const Render = struct {
    vulkanContext: vk.context.VulkanContext,

    pub fn cleanup(self: *Render, allocator: std.mem.Allocator) !void {
        try self.vulkanContext.cleanup(allocator);
    }

    pub fn create(allocator: std.mem.Allocator, constants: common.common.Constants) !Render {
        const vulkanContext = try vk.context.VulkanContext.create(allocator, constants);
        return .{
            .vulkanContext = vulkanContext,
        };
    }

    pub fn render(self: *Render, engineContext: *engine.EngineContext) !void {
        _ = self;
        _ = engineContext;
    }
};
