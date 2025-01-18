const std = @import("std");
const expect = @import("std").testing.expect;

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

pub fn calculateDistance(a: rl.Vector2, b: rl.Vector2) f32 {
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    return @sqrt(dx * dx + dy * dy);
}

test "calculateDistance should return 5" {
    const v1 = rl.Vector2.init(0, 0);
    const v2 = rl.Vector2.init(3, 4);

    const actual = calculateDistance(v1, v2);
    try expect(actual == 5);
}

pub fn calculatePointOnLine(end: rl.Vector2, origin: rl.Vector2, distance: f32) rl.Vector2 {
    const direction = rl.Vector2{
        .x = origin.x - end.x,
        .y = origin.y - end.y,
    };

    const length = @sqrt(direction.x * direction.x + direction.y * direction.y);

    // Normalize the direction vector
    const normalized = rl.Vector2{
        .x = direction.x / length,
        .y = direction.y / length,
    };

    // Scale the normalized vector by the distance
    const scaled = rl.Vector2{
        .x = normalized.x * distance,
        .y = normalized.y * distance,
    };

    // Add the scaled vector to the starting point
    return rl.Vector2{
        .x = end.x + scaled.x,
        .y = end.y + scaled.y,
    };
}
