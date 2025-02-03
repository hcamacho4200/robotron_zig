const std = @import("std");
const expect = std.testing.expect;

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const a = @import("actor_master.zig");
const a_diamond = @import("actors/diamond.zig");
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

pub const ShotStatus = enum {
    ACTIVE, // fully active, end is being advanced
    REMOVING, // end is stopped, and start is being advanced until caught up with end
    IDLE, // shot is idle no longer being rendered
};

pub const Shot = struct {
    origin: rl.Vector2,
    drawStart: rl.Vector2,
    drawEnd: rl.Vector2,
    direction: ShootDirection,
    previous: rl.Vector2,
    active: ShotStatus,

    pub fn init(direction: ShootDirection, origin: rl.Vector2) Shot {
        return Shot{ .origin = origin, .drawStart = origin, .drawEnd = origin, .direction = direction, .previous = origin, .active = ShotStatus.ACTIVE };
    }

    pub fn init_inactive(direction: ShootDirection, origin: rl.Vector2) Shot {
        return Shot{ .origin = origin, .drawStart = origin, .drawEnd = origin, .direction = direction, .previous = origin, .active = ShotStatus.IDLE };
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
    pub fn detectIfActorShot(self: *@This(), actor_rect: u.Rectangle, actor_mask: [*]u8) bool {
        for (self.shots[0..]) |*shot| {
            const shot_rect = u.Rectangle.init_with_coords(shot.drawEnd.x, shot.drawEnd.y, shot.previous.x, shot.previous.y);
            const overlap = u.isOverLappingRectangles(actor_rect, shot_rect);
            const shot_offset = self.buildShotDirection(shot.direction);

            if (overlap) |overlap_rect| {
                const overlap_rect_x = @as(usize, @intFromFloat(overlap_rect.x));
                const overlap_rect_y = @as(usize, @intFromFloat(overlap_rect.y));
                const actor_rect_y = @as(usize, @intFromFloat(actor_rect.y));
                const actor_rect_x = @as(usize, @intFromFloat(actor_rect.x));
                const actor_rect_width = @as(usize, @intFromFloat(actor_rect.width));

                var shot_test_x = @as(usize, @intFromFloat(shot.previous.x));
                var shot_test_y = @as(usize, @intFromFloat(shot.previous.y));

                while (true) {
                    // check to see if shot is in the overlap
                    if (u.isVecInRect(rl.Vector2.init(@as(f32, @floatFromInt(shot_test_x)), @as(f32, @floatFromInt(shot_test_y))), overlap_rect)) {
                        // test shot
                        const overlap_offset_x = if (overlap_rect_x >= shot_test_x) overlap_rect_x - shot_test_x else shot_test_x - overlap_rect_x;
                        const overlap_offset_y = if (overlap_rect_y >= shot_test_y) overlap_rect_y - shot_test_y else shot_test_y - overlap_rect_y;

                        const actor_pixel = (overlap_rect_y - actor_rect_y + overlap_offset_y) * actor_rect_width + (overlap_rect_x - actor_rect_x + overlap_offset_x);
                        std.debug.print("dectIfActorShot {}\n", .{actor_pixel});
                        const test_pixel = actor_mask[actor_pixel];
                        if (test_pixel == 1) return true;
                    }

                    // increment position and exit if we are at the overlap
                    if (shot_offset.x < 0) shot_test_x -= 1 else if (shot_offset.x > 0) shot_test_x += 1;
                    if (shot_offset.y < 0) shot_test_y -= 1 else if (shot_offset.y > 0) shot_test_y += 1;
                    if (shot_test_x == overlap_rect_x and shot_test_y == overlap_rect_y) break;
                }
            }
        }
        return false;
    }

    test "detectIfActorShot - Hit" {
        var shooting_master = ShootingMaster.init();
        try shooting_master.takeShot(ShootDirection.UP_LEFT, rl.Vector2.init(50, 50));
        shooting_master.shots[0].drawEnd.x = 30;
        shooting_master.shots[0].drawEnd.y = 30;
        shooting_master.shots[0].previous.x = 50;
        shooting_master.shots[0].previous.y = 50;

        const actor_rect = u.Rectangle.init(40, 40, 10, 10);
        var actor_mask = [_]u8{
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        };

        const result = shooting_master.detectIfActorShot(actor_rect, actor_mask[0..]);
        std.debug.print("detectIfActorShot {}\n", .{result});
        try expect(result == true);
    }

    test "detectIfActorShot - Miss" {
        var shooting_master = ShootingMaster.init();
        try shooting_master.takeShot(ShootDirection.UP_LEFT, rl.Vector2.init(50, 50));
        shooting_master.shots[0].drawEnd.x = 30;
        shooting_master.shots[0].drawEnd.y = 30;
        shooting_master.shots[0].previous.x = 50;
        shooting_master.shots[0].previous.y = 50;

        const actor_rect = u.Rectangle.init(40, 40, 10, 10);
        var actor_mask = [_]u8{
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        };

        const result = shooting_master.detectIfActorShot(actor_rect, actor_mask[0..]);
        std.debug.print("detectIfActorShot {}\n", .{result});
        try expect(result == false);
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
            const speed = self.scaledSpeed * deltaTime;
            const shotDirectionV = self.buildShotDirection(shot.direction);
            const offsetV2 = rl.Vector2.init(shotDirectionV.x * speed, shotDirectionV.y * speed);

            switch (shot.active) {
                .ACTIVE => {
                    var remove: bool = false;

                    shot.previous = shot.drawEnd;
                    shot.drawEnd = u.vector2Add(shot.drawEnd, offsetV2);

                    var adjShotLength: f32 = undefined;
                    const distanceFromOrigin = u.calculateDistance(shot.drawEnd, shot.origin);
                    if (distanceFromOrigin > self.minDistanceForTail) {
                        adjShotLength = if (distanceFromOrigin - self.minDistanceForTail < self.shotLength)
                            distanceFromOrigin - self.minDistanceForTail
                        else
                            self.shotLength;
                    }
                    shot.drawStart = u.calculatePointOnLine(shot.drawEnd, shot.origin, adjShotLength);

                    const playerFrameDimensions: rl.Vector4 = .{
                        .x = game.playerFrame.frameStart.x,
                        .y = game.playerFrame.frameStart.y,
                        .z = game.playerFrame.frameStart.x + game.playerFrame.frameSize.x,
                        .w = game.playerFrame.frameStart.y + game.playerFrame.frameSize.y,
                    };

                    std.log.info("update shot {}", .{shot});

                    if (shot.drawEnd.x < playerFrameDimensions.x) {
                        remove = true;
                        shot.drawEnd.x = playerFrameDimensions.x;
                    } else if (shot.drawEnd.x > playerFrameDimensions.z) {
                        remove = true;
                        shot.drawEnd.x = playerFrameDimensions.z;
                    }

                    if (shot.drawEnd.y < playerFrameDimensions.y) {
                        remove = true;
                        shot.drawEnd.y = playerFrameDimensions.y;
                    } else if (shot.drawEnd.y > playerFrameDimensions.w) {
                        remove = true;
                        shot.drawEnd.y = playerFrameDimensions.w;
                    }

                    if (remove) {
                        shot.active = ShotStatus.REMOVING;
                    }
                },
                .REMOVING => {
                    shot.active = ShotStatus.IDLE;
                    self.shootingDirectionStates[@intFromEnum(shot.direction)].numActiveBullets -= 1;

                    // if (isShotFinished(shot.drawStart, shot.drawEnd, offsetV2)) {
                    //     shot.active = ShotStatus.IDLE;
                    //     self.shootingDirectionStates[@intFromEnum(shot.direction)].numActiveBullets -= 1;
                    //     std.debug.print("removing {}", .{shot});
                    //     shot.drawStart.x = shot.drawEnd.x;
                    //     shot.drawStart.y = shot.drawEnd.y;
                    // } else shot.drawStart = u.vector2Add(shot.drawStart, offsetV2);
                },
                .IDLE => {},
            }
        }
    }

    /// Is Shot Finished
    /// - test if start has caught up with end
    /// - depends on offset direction
    fn isShotFinished(start: rl.Vector2, end: rl.Vector2, offset: rl.Vector2) bool {
        var result_x = false;
        var result_y = false;

        if (offset.x >= 0 and start.x >= end.x) result_x = true else if (offset.x < 0 and start.x <= end.x) result_x = true;
        if (offset.y >= 0 and start.y >= end.y) result_y = true else if (offset.y < 0 and start.y <= end.y) result_y = true;

        return result_x and result_y;
    }

    test "isShotFinished test" {
        try expect(isShotFinished(rl.Vector2.init(0, 0), rl.Vector2.init(10, 0), rl.Vector2.init(1, 0)) == false);
        try expect(isShotFinished(rl.Vector2.init(10, 0), rl.Vector2.init(10, 0), rl.Vector2.init(1, 0)) == true);

        try expect(isShotFinished(rl.Vector2.init(10, 0), rl.Vector2.init(0, 0), rl.Vector2.init(-1, 0)) == false);
        try expect(isShotFinished(rl.Vector2.init(0, 0), rl.Vector2.init(0, 0), rl.Vector2.init(-1, 0)) == true);

        try expect(isShotFinished(rl.Vector2.init(0, 0), rl.Vector2.init(0, 10), rl.Vector2.init(0, 1)) == false);
        try expect(isShotFinished(rl.Vector2.init(0, 10), rl.Vector2.init(0, 10), rl.Vector2.init(0, 1)) == true);

        try expect(isShotFinished(rl.Vector2.init(0, 10), rl.Vector2.init(0, 0), rl.Vector2.init(0, -1)) == false);
        try expect(isShotFinished(rl.Vector2.init(0, 0), rl.Vector2.init(0, 0), rl.Vector2.init(0, -1)) == true);
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
            if (shot.active == ShotStatus.IDLE) {
                shot.* = Shot.init(direction, origin);
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
            switch (shot.active) {
                .ACTIVE, .REMOVING => {
                    rl.DrawLineEx(shot.drawStart, shot.drawEnd, 2, rl.Color.init(255, 255, 255, 255));
                },
                .IDLE => {},
            }
        }
    }
};
