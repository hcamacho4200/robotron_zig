const std = @import("std");

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const g = @import("../game.zig");
const p = @import("../player.zig");
const u = @import("../util.zig");

const ActorInterface = @import("interfaces.zig").ActorInterface;
const ActorBump = @import("image.zig").ActorBump;
const ActorImage = @import("image.zig").ActorImage;
const ActorDirection = @import("image.zig").ActorDirection;
const ActorContainer = @import("image.zig").ActorContainer;

const SpriteInterface = @import("interfaces.zig").SpriteInterface;
const SpritePosition = @import("interfaces.zig").SpritePosition;

var global_init = false;

var image_container = ActorContainer.init();
var mask_container = ActorContainer.init();
var mask_shader: rl.Shader = undefined;

pub var active_image: *ActorImage = undefined;
var active_mask_image: *ActorImage = undefined;

pub var color_status: g.ColorChangeStatus = undefined;

// Establish Random Number Seed
var rng = std.Random.Xoshiro256.init(1234);

pub const Grunt = struct {
    sprite_position: SpritePosition,
    playfield_height: f32,
    scaled_speed: [4]f32 = undefined,
    frame_count: f32,
    frames_before_move: f32,
    delta_time_total: f32,
    actor_bump: ActorBump,

    pub fn init(x: f32, y: f32, playfield_height: f32) Grunt {
        if (!global_init) {
            image_container.addImage(ActorDirection.DOWN, ActorImage.init("./resources/textures/grunt.png", 4));
            mask_container.addImage(ActorDirection.DOWN, ActorImage.init("./resources/textures/grunt-mask.png", 1));

            active_image = image_container.getImage(ActorDirection.DOWN);
            active_image.actor_mask.dumpMask();

            active_mask_image = mask_container.getImage(ActorDirection.DOWN);
            active_mask_image.actor_mask.dumpMask();

            mask_shader = rl.LoadShader(null, "resources/shaders/player-down-crop.fs");
            color_status = g.ColorChangeStatus.init(&[_]g.Color{ g.robotron_red, g.robotron_blue, g.robotron_green }, 250);

            global_init = true;
        }

        const frame_count_random = @as(f32, @floatFromInt(u.generateRandomIntInRange(&rng, 1, 20)));

        var new_grunt = Grunt{ .sprite_position = SpritePosition.init(x, y, 50, 50), .playfield_height = playfield_height, .frame_count = frame_count_random, .frames_before_move = 20, .delta_time_total = 0, .actor_bump = ActorBump.init(4, 0) };
        // var new_grunt = Grunt{ .sprite_position = SpritePosition.init(x, y, 50, 50), .playfield_height = playfield_height, .frame_count = frame_count_random, .frames_before_move = 5, .delta_time_total = 0, .actor_bump = ActorBump.init(4, 0) };
        // var new_grunt = Grunt{ .sprite_position = SpritePosition.init(x, y, 50, 50), .playfield_height = playfield_height, .frame_count = frame_count_random, .frames_before_move = 1, .delta_time_total = 0, .actor_bump = ActorBump.init(4, 0) };
        new_grunt.scaled_speed[0] = playfield_height / 97;
        return new_grunt;
    }

    pub fn setPosition(self: *Grunt, x: f32, y: f32) void {
        self.sprite_position.setPosition(x, y);
    }

    pub fn handleDraw(self: Grunt) void {
        const frameRec = active_image.getFrameRect(self.actor_bump.activeFrame);
        var new_color: g.Color = undefined;

        rl.DrawTextureRec(active_image.texture, frameRec, rl.Vector2.init(self.sprite_position.x, self.sprite_position.y), rl.WHITE);

        // Setup shader value pass-thru
        new_color = color_status.getNextColor();
        rl.SetShaderValue(mask_shader, rl.GetShaderLocation(mask_shader, "newColor"), &new_color, rl.ShaderUniformDataType.SHADER_UNIFORM_VEC4.toCInt());

        rl.BeginShaderMode(mask_shader);
        rl.DrawTextureRec(active_mask_image.texture, frameRec, rl.Vector2.init(self.sprite_position.x, self.sprite_position.y), rl.BLANK);
        rl.EndShaderMode();
    }

    pub fn handleUpdate(self: *Grunt, game: g.Game, player: p.Player, delta_time: f32) void {
        _ = game;
        if (self.frame_count < self.frames_before_move) {
            self.frame_count += 1;
            self.delta_time_total += delta_time;
            return;
        }

        self.actor_bump.bumpActiveFrame();

        self.frame_count = 0;

        // determine the direction from grunt the player is
        const direction = u.findDirectionTo(self.sprite_position.center.toVector2(), player.center.toVector2());

        // set new position based on delta time
        const speed = self.scaled_speed[0];
        const newPosition_x = self.sprite_position.x + (speed * direction.x);
        const newPosition_y = self.sprite_position.y + (speed * direction.y);

        self.setPosition(newPosition_x, newPosition_y);
        self.delta_time_total = 0;
    }
};
