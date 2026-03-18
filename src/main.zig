const engine = @import("engine");
const glfw = @import("zglfw");
const std = @import("std");

pub fn main() !void {
   try glfw.init();
   defer glfw.terminate();

   const window = try glfw.createWindow(600, 600, "Zig Engine", null, null);
   defer glfw.destroyWindow(window);

   while(!window.shouldClose()) {
       glfw.pollEvents();
       window.swapBuffers();
   }
}
