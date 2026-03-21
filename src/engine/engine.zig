const common = @import("common");
const engine = @import("mod.zig");
const std = @import("std");

pub const EngineContext = struct {
    allocator: std.mem.Allocator,
    constants: common.common.Constants,
    window: engine.window.Window,

    pub fn cleanup(self: *EngineContext) !void {
        try self.window.cleanup();
        self.constants.cleanup(self.allocator);
    }
};

pub fn Engine(comptime GameLogic: type) type {
    return struct {
        engineContext: EngineContext,
        gameLogic: *GameLogic,
        render: engine.render.Render,

        fn cleanup(self: *Engine(GameLogic)) !void {
            self.gameLogic.cleanup();
            try self.render.cleanup(self.engineContext.allocator);
            try self.engineContext.cleanup();
        }

        pub fn create(allocator: std.mem.Allocator, gameLogic: *GameLogic, windowTitle: [:0]const u8) !Engine(GameLogic) {
            const engineContext = EngineContext {
                .allocator = allocator,
                .constants = try common.common.Constants.load(allocator),
                .window = try engine.window.Window.create(windowTitle),
            };

            const render = try engine.render.Render.create();

            return .{
                .engineContext = engineContext,
                .gameLogic = gameLogic,
                .render = render,
            };
        }

        fn init(self: *Engine(GameLogic)) !void {
            self.gameLogic.init(&self.engineContext);
        }

        pub fn run(self: *Engine(GameLogic)) !void {
            try self.init();

            var timer = try std.time.Timer.start();
            var lastTime = timer.read();
            var updateTime = lastTime;
            var deltaUpdate: f32 = 0.0;
            const timeUpdate: f32 = 1.0 / self.engineContext.constants.updatesPerSecond;

            while (!self.engineContext.window.closed) {
                const now = timer.read();
                const deltaNs = now - lastTime;
                const deltaSeconds = @as(f32, @floatFromInt(deltaNs)) / 1_000_000_000.0;
                deltaUpdate += deltaSeconds / timeUpdate;

                try self.engineContext.window.pollEvents();

                self.gameLogic.input(&self.engineContext, deltaSeconds);

                if (deltaUpdate >= 1) {
                    const difUpdateSeconds = @as(f32, @floatFromInt(now - updateTime)) / 1_000_000_000.0;
                    self.gameLogic.update(&self.engineContext, difUpdateSeconds);
                    deltaUpdate -= 1;
                    updateTime = now;
                }

                try self.render.render(&self.engineContext);

                lastTime = now;
            }

            try self.cleanup();
        }
    };
}
