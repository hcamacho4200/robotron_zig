const SpritePosition = @import("interfaces.zig").SpritePosition;

pub const Empty = struct {
    sprite_position: SpritePosition,

    pub fn init(x: f32, y: f32) Empty {
        return Empty{
            .sprite_position = SpritePosition.init(x, y, 50, 50),
        };
    }

    pub fn handleDraw(self: Empty) void {
        _ = self;
    }
};
