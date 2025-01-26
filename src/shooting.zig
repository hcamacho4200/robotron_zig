const std = @import("std");
const expect = std.testing.expect;

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
    previous: rl.Vector2,
    active: bool,

    pub fn init(direction: ShootDirection, origin: rl.Vector2) Shot {
        return Shot{ .origin = origin, .drawStart = origin, .drawEnd = origin, .direction = direction, .previous = origin, .active = true };
    }

    pub fn init_inactive(direction: ShootDirection, origin: rl.Vector2) Shot {
        return Shot{ .origin = origin, .drawStart = origin, .drawEnd = origin, .direction = direction, .previous = origin, .active = false };
    }
};

pub const ShootingMaster = struct {
    shootingDirectionStates: [8]ShootingDirectionState,
    shots: [50]Shot,
    minShotTime: u64,
    maxActiveShotsPer: u32,
    scaledSpeed: f32,
    // distance the end must travel before the tail is drawn.
    minDistanceForTail: f32,
    shotLength: f32,

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
        shootingMaster.minDistanceForTail = 38.7;
        shootingMaster.shotLength = 50;

        return shootingMaster;
    }

    pub fn buildShotDirection(self: *@This(), direction: ShootDirection) rl.Vector2 {
        _ = self;

        var offset_x: f32 = undefined;
        var offset_y: f32 = undefined;

        switch (direction) {
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
        return rl.Vector2.init(offset_x, offset_y);
    }

    /// Compute Shot Direction from two vectors
    /// - used to find the direction needed to travse from the start to the end of a shot
    pub fn computeShotDirection(start: rl.Vector2, end: rl.Vector2) rl.Vector2 {
        const x = start.x - end.x;
        const y = start.y - end.y;
        var offset_x: f32 = undefined;
        var offset_y: f32 = undefined;

        if (x < 0) offset_x = -1 else if (x > 0) offset_x = 1 else offset_x = 0;
        if (y < 0) offset_y = -1 else if (y > 0) offset_y = 1 else offset_y = 0;

        return rl.Vector2.init(offset_x, offset_y);
    }

    test "computeShotDirection" {
        var actual: rl.Vector2 = undefined;

        // check up and to the left
        actual = computeShotDirection(rl.Vector2.init(50, 50), rl.Vector2.init(60, 60));
        try expect(actual.x == -1 and actual.y == -1);

        // check down and to the left
        actual = computeShotDirection(rl.Vector2.init(50, 70), rl.Vector2.init(60, 60));
        try expect(actual.x == -1 and actual.y == 1);

        // check up and to the right
        actual = computeShotDirection(rl.Vector2.init(70, 50), rl.Vector2.init(60, 60));
        try expect(actual.x == 1 and actual.y == -1);

        // check down and to the right
        actual = computeShotDirection(rl.Vector2.init(70, 70), rl.Vector2.init(60, 60));
        try expect(actual.x == 1 and actual.y == 1);

        // check to the left
        actual = computeShotDirection(rl.Vector2.init(50, 60), rl.Vector2.init(60, 60));
        try expect(actual.x == -1 and actual.y == 0);

        // check to the right
        actual = computeShotDirection(rl.Vector2.init(70, 60), rl.Vector2.init(60, 60));
        try expect(actual.x == 1 and actual.y == 0);

        // check to the up
        actual = computeShotDirection(rl.Vector2.init(60, 50), rl.Vector2.init(60, 60));
        try expect(actual.x == 0 and actual.y == -1);

        // check to the down
        actual = computeShotDirection(rl.Vector2.init(60, 70), rl.Vector2.init(60, 60));
        try expect(actual.x == 0 and actual.y == 1);

        // check to the equal
        actual = computeShotDirection(rl.Vector2.init(60, 60), rl.Vector2.init(60, 60));
        try expect(actual.x == 0 and actual.y == 0);
    }

    /// Detect If Actor is Shot
    /// - determine is actor rect overlaps shot start and end
    /// - if in the overlap, check the path in the overlap if a shot hits a pixel.
    pub fn detectIfActorShot(self: *@This(), actor_rect: u.Rectangle) bool {
        for (self.shots[0..]) |*shot| {
            const shot_rect = u.Rectangle.init(shot.drawEnd.x, shot.drawEnd.y, shot.previous.x, shot.previous.y);
            const overlap = u.isOverLappingRectangles(actor_rect, shot_rect);
            const shot_offset = self.buildShotDirection(shot.direction);

            if (overlap) |overlap_rect| {
                _ = overlap_rect;
                var shot_test_x = shot.previous.x;
                var shot_test_y = shot.previous.y;

                while (true) {
                    // test shot

                    shot_test_x += shot_offset.x;
                    shot_test_y += shot_offset.y;

                    if (shot_test_x == shot.drawEnd.x and shot_test_y == shot.drawEnd.y) break;
                }
            }
        }
    }

    /// Update Shots
    /// - loop through all the shots
    /// - determine if active
    /// - determine distance from origin
    /// - determine length to draw
    /// - develop start and end vectors
    /// - drawlineEx from start to end.
    pub fn updateShots(self: *@This(), game: g.Game, deltaTime: f32) void {
        for (self.shots[0..]) |*shot| {
            if (shot.active) {
                const speed = self.scaledSpeed * deltaTime;
                const shotDirectionV = self.buildShotDirection(shot.direction);
                const offsetV2 = rl.Vector2.init(shotDirectionV.x * speed, shotDirectionV.y * speed);
                var remove: bool = false;

                shot.previous = shot.drawEnd;
                shot.drawEnd = u.vector2Add(shot.drawEnd, offsetV2);
                const playerFrameDimensions: rl.Vector4 = .{
                    .x = game.playerFrame.frameStart.x,
                    .y = game.playerFrame.frameStart.y,
                    .z = game.playerFrame.frameStart.x + game.playerFrame.frameSize.x,
                    .w = game.playerFrame.frameStart.y + game.playerFrame.frameSize.y,
                };

                if (shot.drawEnd.x < playerFrameDimensions.x or shot.drawEnd.x > playerFrameDimensions.z) remove = true;
                if (shot.drawEnd.y < playerFrameDimensions.y or shot.drawEnd.y > playerFrameDimensions.w) remove = true;

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

    /// Handle drawing shots to the screen
    /// - loop through all the shots
    /// - consider only active shots
    /// - compute the distance thus traveled from the origin and enable drawing only for those shots that have traveled minDistance
    /// - determine if the tail needs to be truncated, otherwise draw at shotLength
    pub fn drawShots(self: *@This()) void {
        for (self.shots[0..]) |*shot| {
            if (shot.active) {
                var adjShotLength: f32 = undefined;
                const distanceFromOrigin = u.calculateDistance(shot.drawEnd, shot.origin);
                if (distanceFromOrigin > self.minDistanceForTail) {
                    adjShotLength = if (distanceFromOrigin - self.minDistanceForTail < self.shotLength)
                        distanceFromOrigin - self.minDistanceForTail
                    else
                        self.shotLength;
                }
                shot.drawStart = u.calculatePointOnLine(shot.drawEnd, shot.origin, adjShotLength);
                rl.DrawLineEx(shot.drawStart, shot.drawEnd, 2, rl.Color.init(255, 255, 255, 255));
            }
        }
    }
};
