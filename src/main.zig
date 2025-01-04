const std = @import("std");

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const Game = struct { title: [*c]const u8, screen: struct { width: f32, height: f32 } };

const Player = struct { name: []const u8, position: struct { x: f32, y: f32 }, speed: f32, dimensions: struct { width: f32, height: f32 } };

const playerRectColor = rl.Color.init(255, 0, 0, 255);
// Define an enum for player direction
const Direction = enum { UP, DOWN, LEFT, RIGHT };

pub fn main() !void {
    const game = Game{ .title = "Robotron Zig 2024", .screen = .{ .width = 800, .height = 600 } };

    rl.InitWindow(game.screen.width, game.screen.height, game.title);
    defer rl.CloseWindow();
    rl.SetTargetFPS(60);

    var player = Player{ .name = "Robotron", .speed = 5, .position = .{ .x = 0, .y = 0 }, .dimensions = .{ .width = 50, .height = 50 } };

    while (!rl.WindowShouldClose()) {
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_S.toCInt())) player.position.x = updatePlayerPosition(player, game, Direction.LEFT);
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_F.toCInt())) player.position.x = updatePlayerPosition(player, game, Direction.RIGHT);
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_E.toCInt())) player.position.y = updatePlayerPosition(player, game, Direction.UP);
        if (rl.IsKeyDown(rl.KeyboardKey.KEY_D.toCInt())) player.position.y = updatePlayerPosition(player, game, Direction.DOWN);

        rl.BeginDrawing();
        rl.ClearBackground(rl.Color.init(0, 0, 0, 0));

        const playerRect = rl.Rectangle.init(player.position.x, player.position.y, player.dimensions.width, player.dimensions.height);
        rl.DrawRectangleRec(playerRect, playerRectColor);

        rl.EndDrawing();
    }

    return;
}

fn updatePlayerPosition(player: Player, game: Game, direction: Direction) f32 {
    const speed = player.speed;
    const width = game.screen.width;
    const height = game.screen.height;

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
