const std = @import("std");

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const g = @import("../game.zig");

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
    playfield_height: f32,
    scaled_speed: [4]f32 = undefined,

    pub fn init(x: f32, y: f32, playfield_height: f32) Grunt {
        if (!global_init) {
            image_container.addImage(ActorDirection.DOWN, ActorImage.init("./resources/textures/grunt.png"));

            active_image = image_container.getImage(ActorDirection.DOWN);
            active_image.actor_mask.dumpMask();

            global_init = true;
        }

        var new_grunt = Grunt{
            .sprite_position = SpritePosition.init(x, y, 50, 50),
            .playfield_height = playfield_height,
        };
        new_grunt.scaled_speed[0] = playfield_height / 10;
        return new_grunt;
    }

    pub fn setPosition(self: *Grunt, x: f32, y: f32) void {
        self.sprite_position.x = x;
        self.sprite_position.y = y;
    }

    pub fn handleDraw(self: Grunt) void {
        const x = self.sprite_position.x;
        const y = self.sprite_position.y;
        rl.DrawTextureV(active_image.texture, rl.Vector2.init(x, y), rl.WHITE);
    }

    pub fn handleUpdate(self: *Grunt, game: g.Game, delta_time: f32) void {
        _ = game;
        // set new position based on delta time
        const speed = self.scaled_speed[0] * delta_time;
        // const width: f32 = game.playerFrame.frameStart.x + game.playerFrame.frameSize.x;
        // const height: f32 = game.playerFrame.frameStart.y + game.playerFrame.frameSize.y;

        const newPosition_x = self.sprite_position.x - speed;
        const newPosition_y = self.sprite_position.y;

        self.setPosition(newPosition_x, newPosition_y);
    }
};
