pub const ActorInterface = union(enum) {
    sprite: SpriteInterface,
};

pub const SpriteInterface = struct { handleDraw: *const fn (self: *anyopaque) void, handleUpdate: *const fn (self: *anyopaque) void };
