const std = @import("std");

const BulletDirection = enum { UP, DOWN, LEFT, RIGHT, UP_LEFT, UP_RIGHT, DOWN_LEFT, DOWN_RIGHT };

pub const BulletShootingState = struct {
    direction: BulletDirection,
    numActiveBullets: usize,
    timeSinceLastShot: f32,

    pub fn init(direction: BulletDirection) BulletShootingState {
        return BulletShootingState{ .direction = direction, .numActiveBullets = 0, .timeSinceLastShot = -1 };
    }
};

pub const Bullets = struct {
    bulletStates: [8]BulletShootingState,

    pub fn init() Bullets {

        // Manually initialize each bullet state
        var bullets: Bullets = undefined;
        bullets.bulletStates[0] = BulletShootingState.init(BulletDirection.UP);
        bullets.bulletStates[1] = BulletShootingState.init(BulletDirection.DOWN);
        bullets.bulletStates[2] = BulletShootingState.init(BulletDirection.LEFT);
        bullets.bulletStates[3] = BulletShootingState.init(BulletDirection.RIGHT);
        bullets.bulletStates[4] = BulletShootingState.init(BulletDirection.UP_LEFT);
        bullets.bulletStates[5] = BulletShootingState.init(BulletDirection.UP_RIGHT);
        bullets.bulletStates[6] = BulletShootingState.init(BulletDirection.DOWN_LEFT);
        bullets.bulletStates[7] = BulletShootingState.init(BulletDirection.DOWN_RIGHT);

        return bullets;
    }
};
