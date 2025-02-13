const std = @import("std");

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const ActorInterface = @import("interfaces.zig").ActorInterface;
const ActorImage = @import("image.zig").ActorImage;
const ActorDirection = @import("image.zig").ActorDirection;
const ActorContainer = @import("image.zig").ActorContainer;

const SpriteInterface = @import("interfaces.zig").SpriteInterface;
const SpritePosition = @import("interfaces.zig").SpritePosition;

var global_init = false;

var image_container = ActorContainer.init();
var mask_container = ActorContainer.init();

var active_image: ActorImage = undefined;
var active_mask_image: ActorImage = undefined;

pub const Grunt = struct {
    sprite_position: SpritePosition,

    pub fn init(x: f32, y: f32) Grunt {
        if (!global_init) {
            image_container.addImage(ActorDirection.DOWN, ActorImage.init("./resources/textures/grunt.png"));

            active_image = image_container.getImage(ActorDirection.DOWN);
            active_image.actor_mask.dumpMask();

            global_init = true;
        }

        return Grunt{
            // .sprite_position = SpritePosition.init(x, y, @as(f32, @floatFromInt(image.width)), @as(f32, @floatFromInt(image.height))),
            .sprite_position = SpritePosition.init(x, y, 50, 50),
        };
    }

    pub fn setPosition(self: *@This(), x: f32, y: f32) void {
        self.x = x;
        self.y = y;
    }

    pub fn handleDraw(self: Grunt) void {
        const x = self.sprite_position.x;
        const y = self.sprite_position.y;
        rl.DrawTextureV(active_image.texture, rl.Vector2.init(x, y), rl.WHITE);
    }

    pub fn handleUpdate(self: Grunt) void {
        std.debug.print("Diamond update {} {}\n", .{ self, self.sprite_position });
    }
};
