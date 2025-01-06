const std = @import("std");

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const g = @import("game.zig");
const mb = @import("message_box.zig");
const di = @import("debug_info.zig");
const p = @import("player.zig");

// zig fmt: on

const playerRectColor = rl.Color.init(255, 0, 0, 255);

pub fn main() !void {
    // var game = g.Game{ .title = "Robotron Zig 2024", .screen = .{ .width = 0, .height = 0, .updated = false }, .frameCount = 0 };
    var game = g.Game.init();
    game.title = "Robotron Zig 2024";
    rl.InitWindow(0, 0, game.title);
    rl.SetWindowState(@intCast(rl.ConfigFlags.FLAG_WINDOW_RESIZABLE.toCInt()));
    rl.SetWindowMinSize(400, 300);
    defer rl.CloseWindow();
    rl.SetTargetFPS(60);

    const windowBarHeight = estimateTitleBarHeight();

    game.updateScreenSize(@divTrunc((rl.GetMonitorHeight(0) - windowBarHeight) * 4, 3), rl.GetMonitorHeight(0) - windowBarHeight);

    var player = p.Player.init();

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

        // Player Movement
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_S.toCInt())) player.position.x = p.updatePlayerPosition(player, game, p.Direction.LEFT, deltaTime);
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_F.toCInt())) player.position.x = p.updatePlayerPosition(player, game, p.Direction.RIGHT, deltaTime);
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_E.toCInt())) player.position.y = p.updatePlayerPosition(player, game, p.Direction.UP, deltaTime);
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_D.toCInt())) player.position.y = p.updatePlayerPosition(player, game, p.Direction.DOWN, deltaTime);

        // Debug Info
        if (rl.IsKeyPressed(rl.KeyboardKey.KEY_GRAVE.toCInt())) {
            game.debugInfo = !game.debugInfo;
        }

        rl.BeginDrawing();
        rl.ClearBackground(rl.Color.init(0, 0, 0, 0));
        try di.handleDisplayDebugInfo(game, deltaTime);

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

// const ShotDirection = enum { UP, DOWN, LEFT, RIGHT, UP_RIGHT, UP_LEFT, DOWN_RIGHT, DOWN_LEFT };
// const Shots = struct { origin: struct { x: f32, y: f32 }, position: struct { x: f32, y: f32 }, direction: ShotDirection };
