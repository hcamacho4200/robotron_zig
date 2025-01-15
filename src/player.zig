const std = @import("std");

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const g = @import("game.zig");
const s = @import("shooting.zig");
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
    shootingMaster: s.ShootingMaster,

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
            },
            .shootingMaster = s.ShootingMaster.init() 
        };
    }

    pub fn updatePlayerScale(self: *@This(), height: c_int) void {
        self.scaledSpeed = @as(f32, @floatFromInt(height)) / 3;
        self.shootingMaster.scaledSpeed = @as(f32, @floatFromInt(height)) / 0.25;
    }

    pub fn handlePlayerInput(self: *@This(), game: g.Game, deltaTime: f32) !void {
        // Player Movement
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_S.toCInt())) self.position.x = self.updatePlayerPosition(game, p.Direction.LEFT, deltaTime);
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_F.toCInt())) self.position.x = self.updatePlayerPosition(game, p.Direction.RIGHT, deltaTime);
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_E.toCInt())) self.position.y = self.updatePlayerPosition(game, p.Direction.UP, deltaTime);
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_D.toCInt())) self.position.y = self.updatePlayerPosition(game, p.Direction.DOWN, deltaTime);

        // Player Shooting
        var shootingDirection: s.ShootDirection = s.ShootDirection.IDLE;
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_I.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_J.toCInt())) shootingDirection = s.ShootDirection.UP_LEFT
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_I.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_L.toCInt())) shootingDirection = s.ShootDirection.UP_RIGHT
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_I.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_K.toCInt())) shootingDirection = s.ShootDirection.IDLE
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_I.toCInt())) shootingDirection = s.ShootDirection.UP
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_K.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_J.toCInt())) shootingDirection = s.ShootDirection.DOWN_LEFT
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_K.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_L.toCInt())) shootingDirection = s.ShootDirection.DOWN_RIGHT
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_K.toCInt()) and rl.IsKeyDown(rl.KeyboardKey.KEY_I.toCInt())) shootingDirection = s.ShootDirection.IDLE
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_K.toCInt())) shootingDirection = s.ShootDirection.DOWN
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_J.toCInt())) shootingDirection = s.ShootDirection.LEFT
        else if (rl.IsKeyDown(rl.KeyboardKey.KEY_L.toCInt())) shootingDirection = s.ShootDirection.RIGHT
        else shootingDirection = s.ShootDirection.IDLE;

        if (shootingDirection != s.ShootDirection.IDLE) {
            if (self.shootingMaster.canShoot(shootingDirection)) {
                const shootingDirectionStatus = self.shootingMaster.shootingDirectionStates[@intFromEnum(shootingDirection)]; 
                std.log.info("shootingDirection {} {d} {} {} ", .{
                    shootingDirection, 
                    std.time.milliTimestamp(), 
                    shootingDirectionStatus.timeSinceLastShot, 
                    shootingDirectionStatus.numActiveBullets
                });
                try self.shootingMaster.takeShot(shootingDirection, rl.Vector2.init(self.position.x, self.position.y));
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

    pub fn updatePlayerPosition(self: *@This(), game: g.Game, direction: Direction, deltaTime: f32) f32 {
        const speed = self.scaledSpeed * deltaTime;
        const width: f32 = game.playerFrame.frameStart.x + game.playerFrame.frameSize.x;
        const height: f32 = game.playerFrame.frameStart.y + game.playerFrame.frameSize.y;

        var newPosition: f32 = undefined;
        switch (direction) {
            Direction.LEFT => {
                newPosition = self.position.x - speed;
                if (!(newPosition > game.playerFrame.frameStart.x)) newPosition = game.playerFrame.frameStart.x;
            },
            Direction.RIGHT => {
                newPosition = self.position.x + speed;
                if (!(newPosition + self.dimensions.width < width)) newPosition = width - self.dimensions.width;
            },
            Direction.UP => {
                newPosition = self.position.y - speed;
                if (!(newPosition > game.playerFrame.frameStart.y)) newPosition = game.playerFrame.frameStart.y;
            },
            Direction.DOWN => {
                newPosition = self.position.y + speed;
                if (!(newPosition + self.dimensions.height < height)) newPosition = height - self.dimensions.height;
            },
        }
        return newPosition;
    }
};
// zig fmt: on
