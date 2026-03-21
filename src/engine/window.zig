const std = @import("std");
const glfw = @import("zglfw");

const log = std.log.scoped(.window);

pub const MouseState = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    deltaX: f32 = 0.0,
    deltaY: f32 = 0.0,
};

const Size = struct {
    width: usize,
    height: usize,
};

pub const Window = struct {
    window: *glfw.Window,
    mouseState: MouseState,
    closed: bool,
    resized: bool,

    pub fn create(windowTitle: [:0]const u8) !Window {
        log.debug("Creating window", .{});

        try glfw.init();
        
        if (!glfw.isVulkanSupported()) {
            const err = error.VulkanNotSupported;
            std.log.err("Vulkan appears to not be supported: {s}", .{@errorName(err)});
            return err;
        }

        const window = try glfw.createWindow(800, 800, windowTitle, null, null);

        log.debug("Created window", .{});

        return .{
            .window = window,
            .closed = false,
            .mouseState = .{},
            .resized = false,
        };
    }

    pub fn cleanup(self: *Window) !void {
        log.debug("Destroying window", .{});
        self.window.destroy();
        glfw.terminate();
    }

    pub fn getSize(self: *Window) !Size {
        const resolution = try self.window.getSize();
        return Size { .width = resolution[0], .height = resolution[1] };
    }

    pub fn isKeyPressed(self: *Window, keyCode: u8) bool {
        const state = self.window.getKey(keyCode);
        return state == glfw.GLFW_PRESS;
    }

    pub fn pollEvents(self: *Window) !void {
        self.resized = false;
        self.mouseState.deltaX = 0.0;
        self.mouseState.deltaY = 0.0;

        glfw.pollEvents();

        self.closed = self.window.shouldClose();

        const cursorPosition = self.window.getCursorPos();
        const x = @as(f32, @floatCast(cursorPosition[0]));
        const y = @as(f32, @floatCast(cursorPosition[1]));

        self.mouseState.deltaX = x - self.mouseState.x;
        self.mouseState.deltaY = y - self.mouseState.y;

        self.mouseState.x = x;
        self.mouseState.y = y;
    }
};
