const std = @import("std");

pub const Constants = struct {
    gpu: []const u8,
    updatesPerSecond: f32,
    validation: bool,
    swapchainImages: u8,
    vsync: bool,

    pub fn load(allocator: std.mem.Allocator) !Constants {
        const constants = Constants{
            .gpu = try allocator.dupe(u8, ""),
            .updatesPerSecond = 40,
            .validation = true,
            .swapchainImages = 3,
            .vsync = true,
        };

        return constants;
    }

    pub fn cleanup(self: *Constants, allocator: std.mem.Allocator) void {
        allocator.free(self.gpu);
    }
};
