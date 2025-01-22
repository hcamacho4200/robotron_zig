const std = @import("std");
const expect = @import("std").testing.expect;

const rlzb = @import("rlzb");
const rl = rlzb.raylib;

const Diamond = @import("actors/diamond.zig").Diamond;

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

pub const Rectangle = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    pub fn init(x: f32, y: f32, width: f32, height: f32) Rectangle {
        return Rectangle{ .x = x, .y = y, .width = width, .height = height };
    }

    pub fn equal(self: *const Rectangle, rect: Rectangle) bool {
        return self.x == rect.x and self.y == rect.y and self.width == self.width and self.height == self.height;
    }
};

pub fn isOverLappingRectangles(rect1: Rectangle, rect2: Rectangle) ?Rectangle {
    const left = @max(rect1.x, rect2.x);
    const right = @min(rect1.x + rect1.width, rect2.x + rect2.width);
    const top = @max(rect1.y, rect2.y);
    const bottom = @min(rect1.y + rect1.height, rect2.y + rect2.height);

    if (right > left and bottom > top) {
        return Rectangle{
            .x = left,
            .y = top,
            .width = right - left,
            .height = bottom - top,
        };
    }
    return null; // No overlap
}

test "isOverLapping - Overlapping" {
    const rect1 = Rectangle{ .x = 10, .y = 10, .width = 50, .height = 50 };
    const rect2 = Rectangle{ .x = 30, .y = 30, .width = 50, .height = 50 };

    const ol = isOverLappingRectangles(rect1, rect2);
    try expect(ol != null);

    if (ol) |overlap| {
        std.debug.print("Overlap {d} {d} {d} {d}\n", .{ overlap.x, overlap.y, overlap.width, overlap.height });
        try expect(overlap.equal(Rectangle{ .x = 30, .y = 30, .width = 30, .height = 30 }));
    }
    try expect(true);
}

test "isOverLapping - non Overlapping" {
    var rect1 = Rectangle{ .x = 10, .y = 10, .width = 10, .height = 10 };
    var rect2 = Rectangle{ .x = 30, .y = 30, .width = 50, .height = 50 };
    var ol = isOverLappingRectangles(rect1, rect2);
    try expect(ol == null);

    rect1 = Rectangle{ .x = 80, .y = 80, .width = 10, .height = 10 };
    rect2 = Rectangle{ .x = 30, .y = 30, .width = 50, .height = 50 };
    ol = isOverLappingRectangles(rect1, rect2);
    try expect(ol == null);

    rect1 = Rectangle{ .x = 10, .y = 80, .width = 10, .height = 10 };
    rect2 = Rectangle{ .x = 30, .y = 30, .width = 50, .height = 50 };
    ol = isOverLappingRectangles(rect1, rect2);
    try expect(ol == null);

    rect1 = Rectangle{ .x = 80, .y = 10, .width = 10, .height = 10 };
    rect2 = Rectangle{ .x = 30, .y = 30, .width = 50, .height = 50 };
    ol = isOverLappingRectangles(rect1, rect2);
    try expect(ol == null);
}
