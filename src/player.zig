const g = @import("game.zig");
const p = @import("player.zig");

// Define an enum for player direction
pub const Direction = enum { UP, DOWN, LEFT, RIGHT };

// zig fmt: off
pub const Player = struct { 
    name: []const u8, 
    position: struct { 
        x: f32, 
        y: f32,
        valid: bool, 
    }, 
    baseSpeed: f32,
    scaledSpeed: f32, 
    dimensions: struct { 
        width: f32, 
        height: f32 
    },
    pub fn init() Player {
        return Player { 
            .name = "Robotron", 
            .baseSpeed = 0,
            .scaledSpeed = 0, 
            .position = .{ 
                .x = 0, 
                .y = 0,
                .valid = false, 
            }, 
            .dimensions = .{ 
                .width = 20, 
                .height = 40 
            } 
        };
    }

    pub fn updatePlayerScale(self: *@This(), height: c_int) void {
        self.scaledSpeed = @as(f32, @floatFromInt(height)) / 3;
    }
};
// zig fmt: on

pub fn updatePlayerPosition(player: p.Player, game: g.Game, direction: Direction, deltaTime: f32) f32 {
    const speed = player.scaledSpeed * deltaTime;
    const width: f32 = game.playerFrame.frameSize.x;
    const height: f32 = game.playerFrame.frameSize.y;

    var oldPosition: f32 = undefined;

    switch (direction) {
        Direction.LEFT => {
            oldPosition = player.position.x;
            const newPosition = player.position.x - speed;
            if (newPosition > game.playerFrame.frameStart.x) return newPosition;
        },
        Direction.RIGHT => {
            oldPosition = player.position.x;
            const newPosition = player.position.x + speed;
            if (newPosition + player.dimensions.width < width) return newPosition;
        },
        Direction.UP => {
            oldPosition = player.position.y;
            const newPosition = player.position.y - speed;
            if (newPosition > game.playerFrame.frameStart.y) return newPosition;
        },
        Direction.DOWN => {
            oldPosition = player.position.y;
            const newPosition = player.position.y + speed;
            if (newPosition + player.dimensions.height < height) return newPosition;
        },
    }
    return oldPosition;
}
