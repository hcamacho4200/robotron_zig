const std = @import("std");
const expect = @import("std").testing.expect;

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const g = @import("game.zig");
const s = @import("shooting.zig");
const i = @import("./actors/interfaces.zig");

const ActorBump = @import("./actors/image.zig").ActorBump;
const ActorImage = @import("./actors/image.zig").ActorImage;
const ActorDirection = @import("./actors/image.zig").ActorDirection;
const ActorContainer = @import("./actors/image.zig").ActorContainer;

var image_container = ActorContainer.init();
var mask_container = ActorContainer.init();

pub var active_image: *ActorImage = undefined;
var active_mask_image: *ActorImage = undefined;
var player_front_mask_shader: rl.Shader = undefined;

pub var glasses_color_status: g.ColorChangeStatus = undefined;

// Define an enum for player direction
pub const Direction = enum { UP, DOWN, LEFT, RIGHT };

pub const Player = struct {
    name: []const u8,
    position: struct {
        x: f32,
        y: f32,
        valid: bool,
        direction: Direction,
    },
    center: i.SpriteCenter,
    baseSpeed: f32,
    scaledSpeed: f32,
    dimensions: struct { width: f32, height: f32 },
    shootingMaster: s.ShootingMaster,
    actorBump: ActorBump,

    pub fn init() Player {
        image_container.addImage(ActorDirection.DOWN, ActorImage.init("./resources/textures/player-front.png", 4));
        image_container.addImage(ActorDirection.RIGHT, ActorImage.init("./resources/textures/player-right.png", 4));
        image_container.addImage(ActorDirection.LEFT, ActorImage.init("./resources/textures/player-left.png", 4));
        image_container.addImage(ActorDirection.UP, ActorImage.init("./resources/textures/player-back.png", 4));

        mask_container.addImage(ActorDirection.DOWN, ActorImage.init("resources/textures/player-front-mask.png", 1));
        mask_container.addImage(ActorDirection.RIGHT, ActorImage.init("resources/textures/player-right-mask.png", 1));
        mask_container.addImage(ActorDirection.LEFT, ActorImage.init("resources/textures/player-left-mask.png", 1));
        mask_container.addImage(ActorDirection.UP, ActorImage.init("resources/textures/player-back-mask.png", 1));

        active_image = image_container.getImage(ActorDirection.DOWN);
        active_image.actor_mask.dumpMask();

        active_mask_image = mask_container.getImage(ActorDirection.DOWN);
        active_mask_image = mask_container.getImage(ActorDirection.DOWN);
        active_mask_image.actor_mask.dumpMask();

        player_front_mask_shader = rl.LoadShader(null, "resources/shaders/player-down-crop.fs");
        std.debug.print("load player shader {}\n", .{player_front_mask_shader});
        glasses_color_status = g.ColorChangeStatus.init(&[_]g.Color{ g.robotron_red, g.robotron_blue, g.robotron_green }, 7);

        // zig fmt: off
        return Player{ .name = "Robotron", .baseSpeed = 0, .scaledSpeed = 0, .position = .{
            .x = 0,
            .y = 0,
            .valid = false,
            .direction = .DOWN,
        }, .center = i.SpriteCenter.init(0, 0, 0, 0), 
        .dimensions = .{ 
            .width = active_image.width, 
            .height = active_image.height, 
        }, 
        .shootingMaster = s.ShootingMaster.init(), 
        .actorBump = ActorBump.init(4, 5),
        };
    }
// zig fmt: on

    pub fn updatePlayerScale(self: *@This(), height: c_int) void {
        self.scaledSpeed = @as(f32, @floatFromInt(height)) / 3;
        self.shootingMaster.scaledSpeed = @as(f32, @floatFromInt(height)) / 0.5;
    }

    pub fn handlePlayerInput(self: *@This(), game: g.Game, deltaTime: f32) !void {
        // Player Movement
        // zig fmt: off
        var walkingDirection: s.ShootDirection = s.ShootDirection.IDLE;
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_E.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_S.toCInt())) walkingDirection = s.ShootDirection.UP_LEFT 
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_E.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_F.toCInt())) walkingDirection = s.ShootDirection.UP_RIGHT 
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_E.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_D.toCInt())) walkingDirection = s.ShootDirection.IDLE 
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_E.toCInt())) walkingDirection = s.ShootDirection.UP 
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_D.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_S.toCInt())) walkingDirection = s.ShootDirection.DOWN_LEFT 
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_D.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_F.toCInt())) walkingDirection = s.ShootDirection.DOWN_RIGHT 
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_D.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_E.toCInt())) walkingDirection = s.ShootDirection.IDLE 
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_D.toCInt())) walkingDirection = s.ShootDirection.DOWN 
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_S.toCInt())) walkingDirection = s.ShootDirection.LEFT 
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_F.toCInt())) walkingDirection = s.ShootDirection.RIGHT 
        else walkingDirection = s.ShootDirection.IDLE;

        if (walkingDirection != s.ShootDirection.IDLE) {
            self.actorBump.bumpActiveFrame();
            self.updatePlayerPosition(game, walkingDirection, deltaTime);
        }

        // if (rl.IsKeyDown(rl.KeyboardKey.KEY_S.toCInt())) self.updatePlayerPosition(game, Direction.LEFT, deltaTime);
        // if (rl.IsKeyDown(rl.KeyboardKey.KEY_F.toCInt())) self.updatePlayerPosition(game, Direction.RIGHT, deltaTime);
        // if (rl.IsKeyDown(rl.KeyboardKey.KEY_E.toCInt())) self.updatePlayerPosition(game, Direction.UP, deltaTime);
        // if (rl.IsKeyDown(rl.KeyboardKey.KEY_D.toCInt())) self.updatePlayerPosition(game, Direction.DOWN, deltaTime);

        // Player Shooting
        var shootingDirection: s.ShootDirection = s.ShootDirection.IDLE;
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_I.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_J.toCInt())) shootingDirection = s.ShootDirection.UP_LEFT else if (rl.IsKeyDown(rl.KeyboardKey.KEY_I.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_L.toCInt())) shootingDirection = s.ShootDirection.UP_RIGHT else if (rl.IsKeyDown(rl.KeyboardKey.KEY_I.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_K.toCInt())) shootingDirection = s.ShootDirection.IDLE else if (rl.IsKeyDown(rl.KeyboardKey.KEY_I.toCInt())) shootingDirection = s.ShootDirection.UP else if (rl.IsKeyDown(rl.KeyboardKey.KEY_K.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_J.toCInt())) shootingDirection = s.ShootDirection.DOWN_LEFT else if (rl.IsKeyDown(rl.KeyboardKey.KEY_K.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_L.toCInt())) shootingDirection = s.ShootDirection.DOWN_RIGHT else if (rl.IsKeyDown(rl.KeyboardKey.KEY_K.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_I.toCInt())) shootingDirection = s.ShootDirection.IDLE else if (rl.IsKeyDown(rl.KeyboardKey.KEY_K.toCInt())) shootingDirection = s.ShootDirection.DOWN else if (rl.IsKeyDown(rl.KeyboardKey.KEY_J.toCInt())) shootingDirection = s.ShootDirection.LEFT else if (rl.IsKeyDown(rl.KeyboardKey.KEY_L.toCInt())) shootingDirection = s.ShootDirection.RIGHT else shootingDirection = s.ShootDirection.IDLE;
        // zig fmt: on

        if (shootingDirection != s.ShootDirection.IDLE) {
            if (self.shootingMaster.canShoot(shootingDirection)) {
                const shootingDirectionStatus = self.shootingMaster.shootingDirectionStates[@intFromEnum(shootingDirection)];
                std.log.info("shootingDirection {} {d} {} {} ", .{ shootingDirection, std.time.milliTimestamp(), shootingDirectionStatus.timeSinceLastShot, shootingDirectionStatus.numActiveBullets });
                try self.shootingMaster.takeShot(shootingDirection, rl.Vector2.init(self.center.x, self.center.y));
            }
            shootingDirection = s.ShootDirection.IDLE;
        }
    }

    pub fn handlePlayerShots(self: *@This(), game: g.Game, deltaTime: f32) void {
        self.shootingMaster.updateShots(game, deltaTime);
    }

    pub fn drawShots(self: *@This()) void {
        self.shootingMaster.drawShots();
    }

    /// Draw the player
    /// - draw the player
    /// - enable the various shaders
    pub fn draw(self: *@This(), game: g.Game) void {
        const frameRec = active_image.getFrameRect(self.actorBump.activeFrame);
        var new_color: g.Color = undefined;

        rl.DrawRectangleV(game.playerFrame.frameStart, game.playerFrame.frameSize, rl.Color.init(0, 0, 0, 255));
        rl.DrawTextureRec(active_image.texture, frameRec, rl.Vector2.init(self.position.x, self.position.y), rl.WHITE);

        // Setup shader value pass-thru
        new_color = glasses_color_status.getNextColor();
        rl.SetShaderValue(player_front_mask_shader, rl.GetShaderLocation(player_front_mask_shader, "newColor"), &new_color, rl.ShaderUniformDataType.SHADER_UNIFORM_VEC4.toCInt());

        rl.BeginShaderMode(player_front_mask_shader);
        rl.DrawTextureRec(active_mask_image.texture, frameRec, rl.Vector2.init(self.position.x, self.position.y), rl.BLANK);
        rl.EndShaderMode();
    }

    pub fn setPlayerPosition(self: *@This(), x: f32, y: f32) void {
        // Update player position
        self.position.x = x;
        self.position.y = y;

        // Update Player Center.
        self.center.x = self.position.x + self.dimensions.width / 2;
        self.center.y = self.position.y + self.dimensions.height / 2;
    }

    pub fn updatePlayerPosition(self: *@This(), game: g.Game, direction: s.ShootDirection, deltaTime: f32) void {
        const speed = self.scaledSpeed * deltaTime;

        const width: f32 = game.playerFrame.frameStart.x + game.playerFrame.frameSize.x;
        const height: f32 = game.playerFrame.frameStart.y + game.playerFrame.frameSize.y;

        var x = self.position.x;
        var y = self.position.y;

        var actor_direction: ActorDirection = undefined;

        switch (direction) {
            s.ShootDirection.LEFT => {
                const newPosition = self.position.x - speed;
                x = if ((newPosition > game.playerFrame.frameStart.x)) newPosition else game.playerFrame.frameStart.x;
                actor_direction = ActorDirection.LEFT;
            },
            s.ShootDirection.RIGHT => {
                const newPosition = self.position.x + speed;
                x = if ((newPosition + self.dimensions.width < width)) newPosition else width - self.dimensions.width;
                actor_direction = ActorDirection.RIGHT;
            },
            s.ShootDirection.UP => {
                const newPosition = self.position.y - speed;
                y = if ((newPosition > game.playerFrame.frameStart.y)) newPosition else game.playerFrame.frameStart.y;
                actor_direction = ActorDirection.UP;
            },
            s.ShootDirection.DOWN => {
                const newPosition = self.position.y + speed;
                y = if ((newPosition + self.dimensions.height < height)) newPosition else height - self.dimensions.height;
                actor_direction = ActorDirection.DOWN;
            },
            s.ShootDirection.UP_LEFT => {
                const newPosition_y = self.position.y - speed;
                const newPosition_x = self.position.x - speed;
                y = if ((newPosition_y > game.playerFrame.frameStart.y)) newPosition_y else game.playerFrame.frameStart.y;
                x = if ((newPosition_x > game.playerFrame.frameStart.x)) newPosition_x else game.playerFrame.frameStart.x;
                actor_direction = ActorDirection.LEFT;
            },
            s.ShootDirection.UP_RIGHT => {
                const newPosition_y = self.position.y - speed;
                const newPosition_x = self.position.x + speed;
                y = if ((newPosition_y > game.playerFrame.frameStart.y)) newPosition_y else game.playerFrame.frameStart.y;
                x = if ((newPosition_x + self.dimensions.width < width)) newPosition_x else width - self.dimensions.width;
                actor_direction = ActorDirection.RIGHT;
            },
            s.ShootDirection.DOWN_LEFT => {
                const newPosition_y = self.position.y + speed;
                const newPosition_x = self.position.x - speed;
                y = if ((newPosition_y + self.dimensions.height < height)) newPosition_y else height - self.dimensions.height;
                x = if ((newPosition_x > game.playerFrame.frameStart.x)) newPosition_x else game.playerFrame.frameStart.x;
                actor_direction = ActorDirection.LEFT;
            },
            s.ShootDirection.DOWN_RIGHT => {
                const newPosition_y = self.position.y + speed;
                const newPosition_x = self.position.x + speed;
                y = if ((newPosition_y + self.dimensions.height < height)) newPosition_y else height - self.dimensions.height;
                x = if ((newPosition_x + self.dimensions.width < width)) newPosition_x else width - self.dimensions.width;
                actor_direction = ActorDirection.RIGHT;
            },
            else => {},
        }

        active_image = image_container.getImage(actor_direction);
        active_mask_image = mask_container.getImage(actor_direction);
        self.dimensions.width = active_image.width;
        self.dimensions.height = active_image.height;

        std.log.info("{} {d} {d} {d} {d}", .{ direction, self.position.x, self.position.y, x, y });
        self.setPlayerPosition(x, y);
    }
};
