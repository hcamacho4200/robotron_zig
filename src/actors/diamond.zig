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
    actor_interface: ActorInterface,
    sprite_position: SpritePosition,

    pub fn init(x: f32, y: f32) Diamond {
        return Diamond{
            // .sprite_position = SpritePosition.init(x, y, @as(f32, @floatFromInt(image.width)), @as(f32, @floatFromInt(image.height))),
            .sprite_position = SpritePosition.init(x, y, 50, 50),
            .actor_interface = ActorInterface{ .sprite = SpriteInterface{ .handleDraw = handleDraw, .handleUpdate = handleUpdate } },
        };
    }

    pub fn setPosition(self: *@This(), x: f32, y: f32) void {
        self.x = x;
        self.y = y;
    }
};

pub fn handleDraw(self: *anyopaque) void {
    const diamond: *Diamond = @alignCast(@ptrCast(self));
    // std.debug.print("Diamond draw {} {}\n", .{ self, diamond.sprite_position });
    const x = diamond.sprite_position.x;
    const y = diamond.sprite_position.y;
    rl.DrawTextureV(actor_image.texture, rl.Vector2.init(x, y), rl.WHITE);
}

pub fn handleUpdate(self: *anyopaque) void {
    const diamond: *Diamond = @alignCast(@ptrCast(self));
    std.debug.print("Diamond update {} {}\n", .{ self, diamond.sprite_position });
}
