const std = @import("std");

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const g = @import("./game.zig");

const Player = struct { name: []const u8, position: struct { x: f32, y: f32 }, speed: f32, dimensions: struct { width: f32, height: f32 } };
// zig fmt: on

const playerRectColor = rl.Color.init(255, 0, 0, 255);
// Define an enum for player direction
const Direction = enum { UP, DOWN, LEFT, RIGHT };

pub fn main() !void {
    var game = g.Game{ .title = "Robotron Zig 2024", .screen = .{ .width = 0, .height = 0, .updated = false }, .frameCount = 0 };
    rl.InitWindow(0, 0, game.title);
    rl.SetWindowState(@intCast(rl.ConfigFlags.FLAG_WINDOW_RESIZABLE.toCInt()));
    rl.SetWindowMinSize(400, 300);
    defer rl.CloseWindow();
    rl.SetTargetFPS(60);

    const windowBarHeight = estimateTitleBarHeight();

    game.updateScreenSize(@divTrunc((rl.GetMonitorHeight(0) - windowBarHeight) * 4, 3), rl.GetMonitorHeight(0) - windowBarHeight);

    var player = Player{ .name = "Robotron", .speed = 400, .position = .{ .x = 0, .y = 0 }, .dimensions = .{ .width = 20, .height = 40 } };

    while (!rl.WindowShouldClose()) {
        // if window is resized adjust width based on Height to maintain 4:3
        if (game.screen.updated) {
            rl.SetWindowSize(game.screen.width, game.screen.height);
            game.screen.updated = false;
        }
        if (rl.IsWindowResized()) {
            game.updateScreenSize(@divTrunc(rl.GetRenderHeight() * 4, 3), rl.GetRenderHeight());
            rl.SetWindowSize(game.screen.width, game.screen.height);
            game.screen.updated = false;
        }
        const deltaTime = rl.GetFrameTime();

        if (rl.IsKeyDown(rl.KeyboardKey.KEY_S.toCInt())) player.position.x = updatePlayerPosition(player, game, Direction.LEFT, deltaTime);
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_F.toCInt())) player.position.x = updatePlayerPosition(player, game, Direction.RIGHT, deltaTime);
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_E.toCInt())) player.position.y = updatePlayerPosition(player, game, Direction.UP, deltaTime);
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_D.toCInt())) player.position.y = updatePlayerPosition(player, game, Direction.DOWN, deltaTime);

        rl.BeginDrawing();
        rl.ClearBackground(rl.Color.init(0, 0, 0, 0));

        const playerRect = rl.Rectangle.init(player.position.x, player.position.y, player.dimensions.width, player.dimensions.height);
        rl.DrawRectangleRec(playerRect, playerRectColor);

        rl.EndDrawing();
    }
    return;
}

fn estimateTitleBarHeight() c_int {
    const builtin = @import("builtin");
    switch (builtin.target.os.tag) {
        .windows => {
            std.debug.print("Running on Windows\n", .{});
            return 30;
        },
        .macos => {
            std.debug.print("Running on MAC\n", .{});
            return 55;
        },
        else => {
            std.debug.print("Unknown OS\n", .{});
            return 22;
        },
    }
}

fn updatePlayerPosition(player: Player, game: g.Game, direction: Direction, deltaTime: f32) f32 {
    const speed = player.speed * deltaTime;
    const width: f32 = @floatFromInt(game.screen.width);
    const height: f32 = @floatFromInt(game.screen.height);

    var oldPosition: f32 = undefined;

    switch (direction) {
        Direction.LEFT => {
            oldPosition = player.position.x;
            const newPosition = player.position.x - speed;
            if (newPosition > 0) return newPosition;
        },
        Direction.RIGHT => {
            oldPosition = player.position.x;
            const newPosition = player.position.x + speed;
            if (newPosition + player.dimensions.width < width) return newPosition;
        },
        Direction.UP => {
            oldPosition = player.position.y;
            const newPosition = player.position.y - speed;
            if (newPosition > 0) return newPosition;
        },
        Direction.DOWN => {
            oldPosition = player.position.y;
            const newPosition = player.position.y + speed;
            if (newPosition + player.dimensions.height < height) return newPosition;
        },
    }
    return oldPosition;
}

// const ShotDirection = enum { UP, DOWN, LEFT, RIGHT, UP_RIGHT, UP_LEFT, DOWN_RIGHT, DOWN_LEFT };
// const Shots = struct { origin: struct { x: f32, y: f32 }, position: struct { x: f32, y: f32 }, direction: ShotDirection };
