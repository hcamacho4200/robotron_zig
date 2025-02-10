const std = @import("std");
const expect = @import("std").testing.expect;

const rlzb = @import("rlzb");
const rl = rlzb.raylib;

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,

    pub fn equal(self: *const @This(), test_color: Color) bool {
        if (self.r == test_color.r and
            self.g == test_color.g and
            self.b == test_color.b and
            self.a == test_color.a) return true;
        return false;
    }
};

pub const robotron_red = Color{ .r = 255.0 / 255.0, .g = 0.0, .b = 0.0, .a = 255.0 / 255.0 };
pub const robotron_yellow = Color{ .r = 233.0 / 255.0, .g = 233.0 / 255.0, .b = 0.0, .a = 255.0 / 255.0 };
pub const robotron_green = Color{ .r = 19.0 / 255.0, .g = 236.0 / 255.0, .b = 0.0 / 255.0, .a = 255.0 / 255.0 };
pub const robotron_blue = Color{ .r = 0.0 / 255.0, .g = 0.0 / 255.0, .b = 250.0 / 255.0, .a = 255.0 / 255.0 };

pub const ColorChangeStatus = struct {
    colors: std.ArrayList(Color) = undefined,
    position: usize = 0,
    total: usize = 0,
    frameCount: usize = 0,
    frameCountToChange: usize = 7,

    pub fn init(colors: []const Color, frames_before_change: usize) ColorChangeStatus {
        var color_change_status = ColorChangeStatus{};
        color_change_status.colors = std.ArrayList(Color).init(std.heap.page_allocator);
        color_change_status.frameCount = 0;
        color_change_status.position = 0;
        color_change_status.total = colors.len;
        color_change_status.frameCountToChange = frames_before_change;

        for (colors) |color| {
            color_change_status.colors.append(color) catch |err| {
                std.debug.panic("Unable to add color {}", .{err});
            };
        }
        std.debug.print("ColorChangeStatus {any}\n", .{color_change_status.colors.items});
        return color_change_status;
    }

    pub fn getNextColor(self: *@This()) Color {
        self.frameCount += 1;
        if (self.frameCount > self.frameCountToChange) {
            self.position += 1;
            self.frameCount = 0;
            if (self.position >= self.total) self.position = 0;
        }
        return self.colors.items[self.position];
    }

    pub fn deinit(self: *@This()) void {
        self.colors.deinit();
    }
};

test "ColorChangeStatus" {
    const colors = &[_]Color{ robotron_blue, robotron_green, robotron_red };
    var color_change_status = ColorChangeStatus.init(colors, 2);
    try expect(color_change_status.getNextColor().equal(robotron_blue));
    try expect(color_change_status.getNextColor().equal(robotron_blue));
    try expect(color_change_status.getNextColor().equal(robotron_green));
    try expect(color_change_status.getNextColor().equal(robotron_green));
    try expect(color_change_status.getNextColor().equal(robotron_red));
    try expect(color_change_status.getNextColor().equal(robotron_red));
}

pub const Game = struct {
    title: [*c]const u8 = "",
    screen: struct {
        /// width of the current game portal
        width: c_int,
        /// height of the current game portal
        height: c_int,
        /// flag for resize, true if current resized and not recalculated
        updated: bool,
        /// original height when the game was started on the screen, this is rendering height
        originalHeight: c_int,
        /// scaling factor, calculated based on the original height and the resized height
        scalingFactor: f32,
    },
    playerFrame: struct {
        upperPadding: f32,
        lowerPadding: f32,
        sidePadding: f32,
        boarderWidth: f32,
        frameStart: rl.Vector2,
        frameSize: rl.Vector2,
        frameThick: rl.Vector2,
    },
    frameCount: u64,
    debugInfo: bool,

    pub fn init() Game {
        return Game{ .title = "", .screen = .{ .width = 0, .height = 0, .updated = false, .originalHeight = 0, .scalingFactor = 0 }, .playerFrame = .{
            .upperPadding = 0.05,
            .lowerPadding = 0.04,
            .sidePadding = 0.03,
            .boarderWidth = 0.005,
            .frameStart = rl.Vector2.init(0, 0),
            .frameSize = rl.Vector2.init(0, 0),
            .frameThick = rl.Vector2.init(10, 10),
        }, .frameCount = 0, .debugInfo = false };
    }

    /// Updates screen size and scaling factors
    /// - track original height
    /// - set current height and width based on parameters
    /// - adjust scaling factor by getting the ratio of new height from original height
    pub fn updateScreenSize(self: *@This(), width: c_int, height: c_int) void {
        if (self.screen.originalHeight == 0) {
            self.screen.originalHeight = height;
        }

        self.screen.width = width;
        self.screen.height = height;
        self.screen.updated = true;

        if (self.screen.height > self.screen.originalHeight) self.screen.height = self.screen.originalHeight;

        const sh: u32 = @intCast(self.screen.height);
        const oh: u32 = @intCast(self.screen.originalHeight);

        self.screen.scalingFactor = @as(f32, @floatFromInt(sh)) / @as(f32, @floatFromInt(oh));
    }

    /// Update Game Field based on current dimensions stored in height and width
    /// - create padding on the top
    /// - create padding on the bottom
    /// - update player field
    pub fn updateGameField(self: *@This()) void {
        const sidePadding = self.playerFrame.sidePadding;
        const upperPadding = self.playerFrame.upperPadding;
        const lowerPadding = self.playerFrame.lowerPadding;
        const frameThickness = self.playerFrame.boarderWidth;
        const width_fp = @as(f32, @floatFromInt(self.screen.width));
        const height_fp = @as(f32, @floatFromInt(self.screen.height));

        // set the frameStart
        self.playerFrame.frameStart.x = 0.0 + (width_fp * sidePadding);
        self.playerFrame.frameStart.y = 0 + (height_fp * upperPadding);

        // set the frameSize
        self.playerFrame.frameSize.x = width_fp - self.playerFrame.frameStart.x - (width_fp * sidePadding);
        self.playerFrame.frameSize.y = height_fp - self.playerFrame.frameStart.y - (height_fp * lowerPadding);

        // set the frameThickness
        self.playerFrame.frameThick.x = height_fp * frameThickness;
        self.playerFrame.frameThick.y = height_fp * frameThickness;
    }
};
