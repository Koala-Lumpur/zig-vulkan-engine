const engine = @import("engine");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("Memory Leaked");

    const allocator = gpa.allocator();

    const windowTitle = "Zig Engine";
    var game = Game{};
    var engineInstance = try engine.Engine(Game).create(allocator, &game, windowTitle);
    try engineInstance.run();
}

const Game = struct {
    pub fn cleanup(self: *Game) void {
        _ = self;
    }

    pub fn init(self: *Game, engineContext: *engine.EngineContext) void {
        _ = self;
        _ = engineContext;
    }

    pub fn input(self: *Game, engineContext: *engine.EngineContext, deltaSeconds: f32) void {
        _ = self;
        _ = engineContext;
        _ = deltaSeconds;
    }

    pub fn update(self: *Game, engineContext: *engine.EngineContext, deltaSeconds: f32) void {
        _ = self;
        _ = engineContext;
        _ = deltaSeconds;
    }
};
