const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const u = @import("../util.zig");

pub const ActorInterface = union(enum) {
    sprite: SpriteInterface,
};

pub const SpriteCenter = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32, width: f32, height: f32) SpriteCenter {
        return SpriteCenter{ .x = x + (width / 2), .y = y + (height / 2) };
    }

    pub fn update(self: *@This(), x: f32, y: f32) void {
        self.x = x;
        self.y = y;
    }

    pub fn toVector2(self: *@This()) rl.Vector2 {
        return rl.Vector2.init(self.x, self.y);
    }
};
pub const SpriteInterface = struct { handleDraw: *const fn (self: *anyopaque) void, handleUpdate: *const fn (self: *anyopaque) void };
pub const SpritePosition = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    center: SpriteCenter,

    pub fn init(x: f32, y: f32, width: f32, height: f32) SpritePosition {
        return SpritePosition{ .x = x, .y = y, .width = width, .height = height, .center = SpriteCenter.init(x, y, width, height) };
    }

    pub fn asRectangle(self: *@This()) u.Rectangle {
        return u.Rectangle.init(self.x, self.y, self.width, self.height);
    }
};
