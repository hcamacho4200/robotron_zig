// zig fmt: off
pub const Game = struct {
    title: [*c]const u8 = "", 
    screen: struct { 
        width: c_int, 
        height: c_int,
        updated: bool,
        originalHeight: c_int,
        scalingFactor: f32,
    },
    playerFrame: struct {
        x: c_int,
        y: c_int,
        width: c_int,
        height: c_int,
    },
    frameCount: u64 = 0,
    debugInfo: bool,

    pub fn init() Game {
        return Game{ .title = "", 
        .screen = .{ 
            .width = 0, 
            .height = 0, 
            .updated = false, 
            .originalHeight = 0, 
            .scalingFactor = 0 
        }, 
        .playerFrame = .{ 
            .x = 0, 
            .y = 0, 
            .height = 0, 
            .width = 0 
        }, 
        .frameCount = 0,
        .debugInfo = false 
    };
// zig fmt: on
    }
    pub fn updateScreenSize(self: *@This(), width: c_int, height: c_int) void {
        if (self.screen.originalHeight == 0) {
            self.screen.originalHeight = height;
        }

        self.screen.width = width;
        self.screen.height = height;
        self.screen.updated = true;

        if (self.screen.height > self.screen.originalHeight) self.screen.height = self.screen.originalHeight;

        const sh: u32 = @intCast(self.screen.height);
        const oh: u32 = @intCast(self.screen.originalHeight);

        self.screen.scalingFactor = @as(f32, @floatFromInt(sh)) / @as(f32, @floatFromInt(oh));
    }
};
