pub const ActorInterface = union(enum) {
    sprite: SpriteInterface,
};

pub const SpriteInterface = struct { handleDraw: *const fn (self: *anyopaque) void, handleUpdate: *const fn (self: *anyopaque) void };
pub const SpritePosition = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    pub fn init(x: f32, y: f32, width: f32, height: f32) SpritePosition {
        return SpritePosition{ .x = x, .y = y, .width = width, .height = height };
    }
};
