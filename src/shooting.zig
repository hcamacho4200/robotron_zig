const std = @import("std");

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const g = @import("game.zig");
const u = @import("util.zig");

pub const ShootDirection = enum { UP, DOWN, LEFT, RIGHT, UP_LEFT, UP_RIGHT, DOWN_LEFT, DOWN_RIGHT, IDLE };

pub const ShootingDirectionState = struct {
    direction: ShootDirection,
    numActiveBullets: u32,
    timeSinceLastShot: i64,

    pub fn init(direction: ShootDirection) ShootingDirectionState {
        return ShootingDirectionState{ .direction = direction, .numActiveBullets = 0, .timeSinceLastShot = -1 };
    }
};

pub const Shot = struct {
    origin: rl.Vector2,
    drawStart: rl.Vector2,
    drawEnd: rl.Vector2,
    direction: ShootDirection,
    active: bool,

    pub fn init(direction: ShootDirection, origin: rl.Vector2) Shot {
        return Shot{ .origin = origin, .drawStart = origin, .drawEnd = origin, .direction = direction, .active = true };
    }

    pub fn init_inactive(direction: ShootDirection, origin: rl.Vector2) Shot {
        return Shot{ .origin = origin, .drawStart = origin, .drawEnd = origin, .direction = direction, .active = false };
    }
};

pub const ShootingMaster = struct {
    shootingDirectionStates: [8]ShootingDirectionState,
    shots: [50]Shot,
    minShotTime: u64,
    maxActiveShotsPer: u32,
    scaledSpeed: f32,

    pub fn init() ShootingMaster {

        // Manually initialize each bullet state
        var shootingMaster: ShootingMaster = undefined;
        shootingMaster.shootingDirectionStates[0] = ShootingDirectionState.init(ShootDirection.UP);
        shootingMaster.shootingDirectionStates[1] = ShootingDirectionState.init(ShootDirection.DOWN);
        shootingMaster.shootingDirectionStates[2] = ShootingDirectionState.init(ShootDirection.LEFT);
        shootingMaster.shootingDirectionStates[3] = ShootingDirectionState.init(ShootDirection.RIGHT);
        shootingMaster.shootingDirectionStates[4] = ShootingDirectionState.init(ShootDirection.UP_LEFT);
        shootingMaster.shootingDirectionStates[5] = ShootingDirectionState.init(ShootDirection.UP_RIGHT);
        shootingMaster.shootingDirectionStates[6] = ShootingDirectionState.init(ShootDirection.DOWN_LEFT);
        shootingMaster.shootingDirectionStates[7] = ShootingDirectionState.init(ShootDirection.DOWN_RIGHT);

        // initialize all the possible bullets to an array, idle, marking them inactive
        var initializeShots: [50]Shot = undefined;
        for (initializeShots[0..]) |*shot| {
            shot.* = Shot.init_inactive(ShootDirection.IDLE, rl.Vector2.init(0, 0));
        }
        shootingMaster.shots = initializeShots;

        shootingMaster.minShotTime = 100;
        shootingMaster.maxActiveShotsPer = 4;

        return shootingMaster;
    }

    /// Update Shots
    /// - loop through all the shots
    /// - determine if active
    /// - determine distance from origin
    /// - determine length to draw
    /// - develop start and end vectors
    /// - drawlineEx from start to end.
    pub fn updateShots(self: *@This(), game: g.Game, deltaTime: f32) void {
        var offset_x: f32 = undefined;
        var offset_y: f32 = undefined;

        for (self.shots[0..]) |*shot| {
            switch (shot.direction) {
                .UP => {
                    offset_x = 0;
                    offset_y = -1;
                },
                .UP_LEFT => {
                    offset_x = -1;
                    offset_y = -1;
                },
                .UP_RIGHT => {
                    offset_x = 1;
                    offset_y = -1;
                },
                .DOWN => {
                    offset_x = 0;
                    offset_y = 1;
                },
                .DOWN_LEFT => {
                    offset_x = -1;
                    offset_y = 1;
                },
                .DOWN_RIGHT => {
                    offset_x = 1;
                    offset_y = 1;
                },
                .LEFT => {
                    offset_x = -1;
                    offset_y = 0;
                },
                .RIGHT => {
                    offset_x = 1;
                    offset_y = 0;
                },
                .IDLE => {},
            }
            if (shot.active) {
                const speed = self.scaledSpeed * deltaTime;
                const offsetV2 = rl.Vector2.init(offset_x * speed, offset_y * speed);
                var remove: bool = false;

                shot.drawEnd = u.vector2Add(shot.drawEnd, offsetV2);
                if (shot.drawEnd.x < 0 or shot.drawEnd.x > @as(f32, @floatFromInt(game.screen.width))) remove = true;
                if (shot.drawEnd.y < 0 or shot.drawEnd.y > @as(f32, @floatFromInt(game.screen.height))) remove = true;

                if (remove) {
                    shot.active = false;
                    self.shootingDirectionStates[@intFromEnum(shot.direction)].numActiveBullets -= 1;
                    const activeShots = self.shootingDirectionStates[@intFromEnum(shot.direction)].numActiveBullets;
                    std.log.info("removing shot {} {}", .{ activeShots, shot });
                }
            }
        }
    }

    /// Determine if the player can shoot in a particular direction
    /// - check to see if enough time has moved on
    /// - check to see if shot slots are available
    /// - return true to allowed, else false.
    pub fn canShoot(self: *@This(), direction: ShootDirection) bool {
        // get the shotStatus for the direction
        const shotStatus = self.shootingDirectionStates[@intFromEnum(direction)];
        const currentTime = std.time.milliTimestamp();
        const lastShotTime = shotStatus.timeSinceLastShot;

        if ((currentTime - lastShotTime > self.minShotTime) or lastShotTime == -1) {
            if (shotStatus.numActiveBullets < self.maxActiveShotsPer) {
                return true;
            }
        }

        return false;
    }

    pub fn takeShot(self: *@This(), direction: ShootDirection, origin: rl.Vector2) !void {
        self.shootingDirectionStates[@intFromEnum(direction)].numActiveBullets += 1;
        self.shootingDirectionStates[@intFromEnum(direction)].timeSinceLastShot = std.time.milliTimestamp();

        for (self.shots[0..]) |*shot| {
            if (!shot.active) {
                const activeShots = self.shootingDirectionStates[@intFromEnum(direction)].numActiveBullets;
                shot.* = Shot.init(direction, origin);
                std.log.info("added shot {} {}", .{ activeShots, shot });
                return;
            }
        }
        std.log.info("unable to shoot", .{});
    }

    pub fn drawShots(self: *@This()) void {
        for (self.shots[0..]) |*shot| {
            if (shot.active) {
                const shotCenter = rl.Vector2.init(shot.drawEnd.x, shot.drawEnd.y);
                rl.DrawCircleV(shotCenter, 10, rl.Color.init(255, 255, 255, 255));
            }
        }
    }
};
