const std = @import("std");
const os = @import("os");

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const g = @import("game.zig");
const mb = @import("message_box.zig");
const di = @import("debug_info.zig");
const p = @import("player.zig");
const u = @import("util.zig");
const a = @import("actor_master.zig");
const ai = @import("./actors/image.zig");
const a_diamond = @import("./actors/diamond.zig");

// zig fmt: on

const playerRectColor = rl.Color.init(255, 0, 0, 255);

test {
    @import("std").testing.refAllDecls(@This());
}

pub fn main() !void {
    var game = g.Game.init();
    game.title = "Robotron Zig 2024";
    rl.InitWindow(0, 0, game.title);
    rl.SetWindowState(@intCast(rl.ConfigFlags.FLAG_WINDOW_RESIZABLE.toCInt()));
    rl.SetWindowMinSize(400, 300);
    defer rl.CloseWindow();
    rl.SetTargetFPS(60);

    // Establish Random Number Seed
    var rng = std.Random.Xoshiro256.init(1234);

    const diamond_actor_image = ai.ActorImage.init("./resources/textures/sprite-diamond.png");
    a_diamond.actor_image = diamond_actor_image;
    std.debug.print("{}", .{diamond_actor_image});
    a_diamond.actor_image.actor_mask.dumpMask();

    const player_actor_image = ai.ActorImage.init("./resources/textures/player-down-crop.png");
    p.actor_image = player_actor_image;
    std.debug.print("{}", .{player_actor_image});
    p.actor_image.actor_mask.dumpMask();

    const windowBarHeight = estimateTitleBarHeight();

    game.updateScreenSize(@divTrunc((rl.GetMonitorHeight(0) - windowBarHeight) * 4, 3), rl.GetMonitorHeight(0) - windowBarHeight);
    game.updateGameField();

    var player = p.Player.init();
    updateScreen(&game, &player);

    var actor_master = a.ActorMaster.init();
    for (0..100) |_| {
        const player_frame_x_min = @as(u32, @intFromFloat(game.playerFrame.frameStart.x));
        const player_frame_x_max = @as(u32, @intFromFloat(game.playerFrame.frameStart.x + game.playerFrame.frameSize.x));
        const player_frame_y_min = @as(u32, @intFromFloat(game.playerFrame.frameStart.y));
        const player_frame_y_max = @as(u32, @intFromFloat(game.playerFrame.frameStart.y + game.playerFrame.frameSize.y));

        while (true) {
            const x = @as(f32, @floatFromInt(u.generateRandomIntInRange(&rng, player_frame_x_min, player_frame_x_max)));
            const y = @as(f32, @floatFromInt(u.generateRandomIntInRange(&rng, player_frame_y_min, player_frame_y_max)));
            const new_actor = a.Actor{ .diamond = a_diamond.Diamond.init(x, y) };
            const rect_test = u.Rectangle.init(x, y, new_actor.diamond.sprite_position.width, new_actor.diamond.sprite_position.height);
            const actor_collided_with = actor_master.checkCollision(rect_test, a_diamond.actor_image, true);
            if (actor_collided_with) |_| {} else {
                actor_master.addActor(new_actor);
                break;
            }
        }
    }
    // actor_master.addActor(a.Actor{ .diamond = a_diamond.Diamond.init(200, 200) });
    // actor_master.addActor(a.Actor{ .diamond = a_diamond.Diamond.init(400, 200) });
    // actor_master.addActor(a.Actor{ .diamond = a_diamond.Diamond.init(600, 200) });
    // actor_master.addActor(a.Actor{ .diamond = a_diamond.Diamond.init(800, 200) });
    // actor_master.addActor(a.Actor{ .diamond = a_diamond.Diamond.init(200, 400) });
    // actor_master.addActor(a.Actor{ .diamond = a_diamond.Diamond.init(200, 600) });
    // actor_master.addActor(a.Actor{ .diamond = a_diamond.Diamond.init(200, 800) });
    actor_master.listActive();

    const playerDownCropTexture = rl.LoadTexture("resources/textures/player-down-crop.png");
    const playerDownCropTextureGlasses = rl.LoadTexture("resources/textures/player-down-crop-glasses.png");
    const playerDownCropTexture_width = @as(f32, @floatFromInt(playerDownCropTexture.width));
    const playerDownCropTexture_height = @as(f32, @floatFromInt(playerDownCropTexture.height));
    const frameRec = rl.Rectangle.init(0.0, 0.0, playerDownCropTexture_width, playerDownCropTexture_height);
    player.dimensions.width = playerDownCropTexture_width;
    player.dimensions.height = playerDownCropTexture_height;
    const playerDownCropShader = rl.LoadShader(null, "resources/shaders/player-down-crop.fs");

    const image = rl.LoadImageFromTexture(playerDownCropTexture);
    if (image.height > 0) {}

    var newColor: [4]f32 = undefined;
    const robotron_red = [4]f32{ 255.0 / 255.0, 0.0, 0.0, 255.0 / 255.0 };
    // const robotron_yellow = [4]f32{ 233.0 / 255.0, 233.0 / 255.0, 0.0, 255.0 / 255.0 };
    const robotron_green = [4]f32{ 19.0 / 255.0, 236.0 / 255.0, 0.0 / 255.0, 255.0 / 255.0 };
    const robotron_blue = [4]f32{ 0.0 / 255.0, 0.0 / 255.0, 250.0 / 255.0, 255.0 / 255.0 };

    // zig fmt: off
    const PlayerGlassesColorStatus = struct { 
        colors: [][4]f32, 
        position: usize, 
        total: usize,
        frameCount: usize = 0,
        frameCountToChange: usize = 7, 
    };
    // zig fmt: on

    var playerGlassesColors = [_][4]f32{ robotron_blue, robotron_green, robotron_red };
    var playerGlassesColorStatus = PlayerGlassesColorStatus{ .colors = playerGlassesColors[0..], .position = 0, .total = playerGlassesColors.len };

    while (!rl.WindowShouldClose()) {
        updateScreen(&game, &player);

        const offsetStart = u.vector2Subtract(game.playerFrame.frameStart, game.playerFrame.frameThick);
        const offsetSize = u.vector2Add(u.vector2Add(game.playerFrame.frameSize, game.playerFrame.frameThick), game.playerFrame.frameThick);

        const deltaTime = rl.GetFrameTime();

        // Player Movement
        try player.handlePlayerInput(game, deltaTime);

        // Player Shooting
        player.handlePlayerShots(game, deltaTime);

        // Player Collision with Actors
        var player_collision = false;
        var player_overlap: u.Rectangle = undefined;
        const rect_test = u.Rectangle.init(player.position.x, player.position.y, player.dimensions.width, player.dimensions.height);
        const actor_collided_with = actor_master.checkCollision(rect_test, p.actor_image, false);
        if (actor_collided_with) |ao| {
            player_collision = true;
            player_overlap = ao.overlap;
            std.debug.print("player collision with {} bounded by {}\n", .{ ao.actor, ao.overlap });
        } else {
            player_collision = false;
        }

        // Debug Info
        if (rl.IsKeyPressed(rl.KeyboardKey.KEY_GRAVE.toCInt())) {
            game.debugInfo = !game.debugInfo;
        }

        // Setup shader value pass-thru
        rl.SetShaderValue(playerDownCropShader, rl.GetShaderLocation(playerDownCropShader, "newColor"), &newColor, rl.ShaderUniformDataType.SHADER_UNIFORM_VEC4.toCInt());

        playerGlassesColorStatus.frameCount += 1;
        if (playerGlassesColorStatus.frameCount > playerGlassesColorStatus.frameCountToChange) {
            playerGlassesColorStatus.frameCount = 0;
            playerGlassesColorStatus.position += 1;
            if (playerGlassesColorStatus.position >= playerGlassesColorStatus.total) playerGlassesColorStatus.position = 0;
            newColor = playerGlassesColorStatus.colors[playerGlassesColorStatus.position];
        }

        rl.BeginDrawing();

        // Draw the playfield
        rl.ClearBackground(rl.Color.init(0, 0, 0, 0));

        rl.BeginShaderMode(playerDownCropShader);
        rl.DrawRectangleV(offsetStart, offsetSize, rl.Color.init(0, 255, 0, 255));
        rl.EndShaderMode();

        rl.DrawRectangleV(game.playerFrame.frameStart, game.playerFrame.frameSize, rl.Color.init(0, 0, 0, 255));
        rl.DrawTextureRec(playerDownCropTexture, frameRec, rl.Vector2.init(player.position.x, player.position.y), rl.WHITE);

        // handle drawing of the actors
        actor_master.handleDraw();

        rl.BeginShaderMode(playerDownCropShader);
        rl.DrawTextureRec(playerDownCropTextureGlasses, frameRec, rl.Vector2.init(player.position.x, player.position.y), rl.BLANK);
        rl.EndShaderMode();

        // Draw the bullets
        player.drawShots();

        // Draw the player overlap collision
        if (player_collision) {
            rl.DrawRectangle(@intFromFloat(player_overlap.x), @intFromFloat(player_overlap.y), @intFromFloat(player_overlap.width), @intFromFloat(player_overlap.height), rl.Color.init(255, 255, 255, 150));
        }

        // Handle debugging info
        try di.handleDisplayDebugInfo(game, player, deltaTime);

        rl.EndDrawing();
    }
    return;
}

fn updateScreen(game: *g.Game, player: *p.Player) void {
    // if window is resized adjust width based on Height to maintain 4:3
    if (game.screen.updated) {
        rl.SetWindowSize(game.screen.width, game.screen.height);
        player.updatePlayerScale(game.screen.height);
        game.screen.updated = false;
    }
    if (rl.IsWindowResized()) {
        game.updateScreenSize(@divTrunc(rl.GetRenderHeight() * 4, 3), rl.GetRenderHeight());
        rl.SetWindowSize(game.screen.width, game.screen.height);
        player.updatePlayerScale(game.screen.height);
        game.screen.updated = false;
    }

    // Update Player Portal (Game Field)
    game.updateGameField();
    if (!player.position.valid) {
        player.setPlayerPosition(game.playerFrame.frameSize.x / 2 - player.dimensions.width / 2, game.playerFrame.frameSize.y / 2 - player.dimensions.height / 2);
        player.position.valid = true;
    }
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
