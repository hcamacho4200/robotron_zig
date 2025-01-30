const std = @import("std");
const expect = @import("std").testing.expect;

const rlzb = @import("rlzb");
const rl = rlzb.raylib;

const ai = @import("./actors/image.zig");
const Diamond = @import("actors/diamond.zig").Diamond;
const u = @import("util.zig");

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

pub const RGB = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn init(r: u8, g: u8, b: u8, a: u8) RGB {
        return RGB{ .r = r, .g = g, .b = b, .a = a };
    }
};

pub const Rectangle = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    pub fn init(x: f32, y: f32, width: f32, height: f32) Rectangle {
        return Rectangle{ .x = x, .y = y, .width = width, .height = height };
    }

    /// Init Rectangle with Coordinates
    /// - determine which pair is the upper left
    /// - compute the positive width
    /// - return the rectangle object
    pub fn init_with_coords(x1: f32, y1: f32, x2: f32, y2: f32) Rectangle {
        const x_origin = @min(x1, x2);
        const y_origin = @min(y1, y2);
        const x_width = @abs(x1 - x2);
        const y_width = @abs(y1 - y2);

        return Rectangle.init(x_origin, y_origin, x_width, y_width);
    }

    test "init_with_coord" {
        var actual: u.Rectangle = undefined;

        actual = init_with_coords(50, 50, 40, 60);
        std.debug.print("{}\n", .{actual});
        try expect(actual.x == 40 and actual.y == 50 and actual.width == 10 and actual.height == 10);
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

pub fn generateRandomIntInRange(rng: *std.Random.Xoshiro256, min: u32, max: u32) u32 {
    const range: u32 = max - min + 1;
    return @as(u32, @intCast(rng.next() % range)) + min;
}

test "generateRandomIntInRange" {
    var rng = std.Random.Xoshiro256.init(1234);
    for (0..500) |_| {
        const actual = generateRandomIntInRange(&rng, 10, 100);
        // std.debug.print("random {}\n", .{actual});
        try expect(actual >= 10 and actual <= 100);
    }
}

/// Detect Pixel Overlap
/// - normalize the overlap rect by subtracting test and actor rects coordinates (in the loop)
/// - flatten x,y for each rect into an offset from 0 in each mask
pub fn detectPixelOverlap(actor_mask: [*]u8, rect_actor: Rectangle, test_mask: [*]u8, rect_test: Rectangle, overlap_rect: Rectangle) bool {
    const overlap_rect_x = @as(usize, @intFromFloat(overlap_rect.x));
    const overlap_rect_y = @as(usize, @intFromFloat(overlap_rect.y));
    const overlap_rect_width = @as(usize, @intFromFloat(overlap_rect.width));
    const overlap_rect_height = @as(usize, @intFromFloat(overlap_rect.height));
    const rect_actor_y = @as(usize, @intFromFloat(rect_actor.y));
    const rect_actor_x = @as(usize, @intFromFloat(rect_actor.x));
    const rect_actor_width = @as(usize, @intFromFloat(rect_actor.width));
    const rect_test_y = @as(usize, @intFromFloat(rect_test.y));
    const rect_test_x = @as(usize, @intFromFloat(rect_test.x));
    const rect_test_width = @as(usize, @intFromFloat(rect_test.width));

    var results = std.ArrayList(RGB).init(std.heap.page_allocator);
    defer results.deinit();
    const size = @as(usize, @intCast(overlap_rect_height * overlap_rect_width));
    results.ensureTotalCapacity(size) catch |err| {
        std.debug.print("Error: {}\n", .{err});
    };

    var collision_detection = false;

    var results_count: usize = 0;
    const pixel_collision = RGB.init(255, 0, 0, 100);
    const blank = RGB.init(0, 0, 0, 0);

    for (0..overlap_rect_width) |y| {
        for (0..overlap_rect_height) |x| {
            const actor_pixel = (overlap_rect_y - rect_actor_y + y) * rect_actor_width + (overlap_rect_x - rect_actor_x + x);
            const test_pixel = (overlap_rect_y - rect_test_y + y) * rect_test_width + (overlap_rect_x - rect_test_x + x);

            if (actor_mask[actor_pixel] == 1 and test_mask[test_pixel] == 1) {
                collision_detection = true;
                results.append(pixel_collision) catch |err| {
                    std.debug.print("Error: {}\n", .{err});
                };
            } else {
                results.append(blank) catch |err| {
                    std.debug.print("Error: {}\n", .{err});
                };
            }
            results_count += 1;
        }
    }
    return collision_detection;
}

test "detectPixelOverlap - single pixel" {
    const actor_rect = Rectangle.init(56, 56, 1, 1);
    var actor_mask = [_]u8{1};

    const test_rect = Rectangle.init(56, 56, 3, 3);
    var test_mask = [_]u8{
        1, 1, 1,
        1, 1, 1,
        1, 1, 1,
    };

    const overlap_rect = Rectangle.init(56, 56, 1, 1);

    const results = detectPixelOverlap(actor_mask[0..], actor_rect, test_mask[0..], test_rect, overlap_rect);
    std.debug.print("{any}\n", .{results});
    try std.testing.expect(results == true);
}

test "detectPixelOverlap - upper left" {
    const actor_rect = Rectangle.init(50, 50, 10, 10);
    var actor_mask = [_]u8{
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
        0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
    };

    const test_rect = Rectangle.init(56, 56, 10, 10);
    var test_mask = [_]u8{
        1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
        1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
        1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    };

    const overlap_rect = Rectangle.init(56, 56, 4, 4);

    const results = detectPixelOverlap(actor_mask[0..], actor_rect, test_mask[0..], test_rect, overlap_rect);
    std.debug.print("{any}\n", .{results});
}

pub fn isVecInRect(pixel: rl.Vector2, rect: Rectangle) bool {
    if (pixel.x >= rect.x and pixel.x < rect.x + rect.width) {
        if (pixel.y >= rect.y and pixel.y < rect.y + rect.height) {
            return true;
        }
    }
    return false;
}

test "isVecInRect" {
    try expect(isVecInRect(rl.Vector2.init(50, 50), Rectangle.init(50, 50, 60, 60)) == true);
    try expect(isVecInRect(rl.Vector2.init(109, 109), Rectangle.init(50, 50, 60, 60)) == true);

    try expect(isVecInRect(rl.Vector2.init(110, 110), Rectangle.init(50, 50, 60, 60)) == false);
    try expect(isVecInRect(rl.Vector2.init(48, 48), Rectangle.init(50, 50, 60, 60)) == false);
}

const Line = struct {
    start: rl.Vector2,
    end: rl.Vector2,

    pub fn init(start: rl.Vector2, end: rl.Vector2) Line {
        return Line{ .start = start, .end = end };
    }
};

/// Detect Line Pixel Overlap
/// Given a line, does any pixel overlap the line
/// - determine a rect overlap for this actor and shot line
///
/// - determine shot line coordinate
/// - determine if mask is a 1 at that coordinate.
pub fn detectLinePixelOverlap(actor_rect: Rectangle, actor_mask: [*]u8, shot_line: Line) bool {
    const offset_x: f32 = if (shot_line.start.x < shot_line.end.x) 1 else if (shot_line.start.x > shot_line.end.x) -1 else 0;
    const offset_y: f32 = if (shot_line.start.y < shot_line.end.y) 1 else if (shot_line.start.y > shot_line.end.y) -1 else 0;
    const actor_adj_rect = Rectangle.init(0, 0, actor_rect.width, actor_rect.height);

    var line_pos = shot_line.start;
    while (true) {
        const line_pos_adj_x = line_pos.x - actor_rect.x;
        const line_pos_adj_y = line_pos.y - actor_rect.y;

        if (isVecInRect(rl.Vector2.init(line_pos_adj_x, line_pos_adj_y), actor_adj_rect)) {
            std.debug.print("inside: ", .{});
            const pixel = line_pos_adj_y * actor_adj_rect.width + line_pos_adj_x;
            const hit = actor_mask[@as(usize, @intFromFloat(pixel))];
            std.debug.print(" {} ", .{hit});
            if (hit == 1) return true;
        } else {
            std.debug.print("outside: ", .{});
        }

        std.debug.print("line_pos {any} adj_x {any} adj_y {any}\n", .{ line_pos, line_pos_adj_x, line_pos_adj_y });

        line_pos.x += offset_x;
        line_pos.y += offset_y;

        if (line_pos.x == shot_line.end.x + offset_x and line_pos.y == shot_line.end.y + offset_y) break;
    }
    return false;
}

test "detectLinePixelOverlap" {
    const actor_rect = Rectangle.init(50, 50, 10, 10);
    var actor_mask = [_]u8{
        1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
        1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
        1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    };

    const shot_line = Line.init(rl.Vector2.init(70, 70), rl.Vector2.init(40, 40));
    const actual = detectLinePixelOverlap(actor_rect, actor_mask[0..], shot_line);

    std.debug.print("test {}\n", .{actual});

    try expect(actual == true);
}
