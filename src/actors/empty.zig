const std = @import("std");

const g = @import("../game.zig");

const SpritePosition = @import("interfaces.zig").SpritePosition;

pub const Empty = struct {
    sprite_position: SpritePosition,

    pub fn init(x: f32, y: f32) Empty {
        return Empty{
            .sprite_position = SpritePosition.init(x, y, 50, 50),
        };
    }

    pub fn handleDraw(self: Empty) void {
        _ = self;
    }

    pub fn handleUpdate(self: Empty, game: g.Game, delta_time: f32) void {
        _ = game;
        std.debug.print("Empty update {} {} {}\n", .{ self, self.sprite_position, delta_time });
    }
};
