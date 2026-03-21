const std = @import("std");

pub const Constants = struct {
    updatesPerSecond: f32,

    pub fn load(allocator: std.mem.Allocator) !Constants {
        _ = allocator;

        const constants = Constants {
            .updatesPerSecond = 40,
        };

        return constants;
    }

    pub fn cleanup(self: *Constants, allocator: std.mem.Allocator) void {
        _ = self;
        _ = allocator;
    }
};
