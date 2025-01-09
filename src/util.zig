const rlzb = @import("rlzb");
const rl = rlzb.raylib;

pub fn vector2Add(v1: rl.Vector2, v2: rl.Vector2) rl.Vector2 {
    return rl.Vector2{
        .x = v1.x + v2.x,
        .y = v1.y + v2.y,
    };
}

pub fn vector2Subtract(v1: rl.Vector2, v2: rl.Vector2) rl.Vector2 {
    return rl.Vector2{
        .x = v1.x - v2.x,
        .y = v1.y - v2.y,
    };
}
