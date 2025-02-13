const std = @import("std");

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const ActorInterface = @import("interfaces.zig").ActorInterface;
const ActorImage = @import("image.zig").ActorImage;
const SpriteInterface = @import("interfaces.zig").SpriteInterface;
const SpritePosition = @import("interfaces.zig").SpritePosition;

pub var actor_image: ActorImage = undefined;

pub const Diamond = struct {
    sprite_position: SpritePosition,

    pub fn init(x: f32, y: f32) Diamond {
        return Diamond{
            .sprite_position = SpritePosition.init(x, y, 50, 50),
        };
    }

    pub fn setPosition(self: *@This(), x: f32, y: f32) void {
        self.x = x;
        self.y = y;
    }

    pub fn handleDraw(self: Diamond) void {
        // std.debug.print("Diamond draw {} {}\n", .{ self, diamond.sprite_position });
        const x = self.sprite_position.x;
        const y = self.sprite_position.y;
        rl.DrawTextureV(actor_image.texture, rl.Vector2.init(x, y), rl.WHITE);
    }

    pub fn handleUpdate(self: *@This()) void {
        std.debug.print("Diamond update {} {}\n", .{ self, self.sprite_position });
    }
};
