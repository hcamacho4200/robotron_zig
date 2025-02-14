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
const a_grunt = @import("./actors/grunt.zig");
const sh = @import("shooting.zig");

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

    // boarder shader
    const player_front_mask_shader = rl.LoadShader(null, "resources/shaders/player-down-crop.fs");

    const diamond_actor_image = ai.ActorImage.init("./resources/textures/sprite-diamond.png");
    a_diamond.actor_image = diamond_actor_image;
    std.debug.print("{}", .{diamond_actor_image});
    a_diamond.actor_image.actor_mask.dumpMask();

    const windowBarHeight = estimateTitleBarHeight();

    game.updateScreenSize(@divTrunc((rl.GetMonitorHeight(0) - windowBarHeight) * 4, 3), rl.GetMonitorHeight(0) - windowBarHeight);
    game.updateGameField();

    var player = p.Player.init();
    defer p.glasses_color_status.deinit();

    updateScreen(&game, &player);

    var actor_master = a.ActorMaster.init();
    for (0..40) |_| {
        actor_master.addActor(newActorPlacement(.grunt, game, player, &actor_master, &rng, 400, false));
    }

    for (0..3) |_| {
        const new_actor = newActorPlacement(.diamond, game, player, &actor_master, &rng, 400, false);
        actor_master.addActor(new_actor);
    }
    actor_master.listActive();

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
        const actor_collided_with = actor_master.checkCollision(rect_test, p.active_image, false);
        if (actor_collided_with) |ao| {
            player_collision = true;
            player_overlap = ao.overlap;
            std.debug.print("player collision with {} bounded by {}\n", .{ ao.actor, ao.overlap });
            actor_master.removeActor(ao.actor);
        } else {
            player_collision = false;
        }

        // Debug Info
        if (rl.IsKeyPressed(rl.KeyboardKey.KEY_GRAVE.toCInt())) {
            game.debugInfo = !game.debugInfo;
        }

        rl.BeginDrawing();

        // Draw the playfield
        rl.ClearBackground(rl.Color.init(0, 0, 0, 0));

        rl.SetShaderValue(player_front_mask_shader, rl.GetShaderLocation(player_front_mask_shader, "newColor"), &g.robotron_blue, rl.ShaderUniformDataType.SHADER_UNIFORM_VEC4.toCInt());
        rl.BeginShaderMode(player_front_mask_shader);
        rl.DrawRectangleV(offsetStart, offsetSize, rl.Color.init(0, 255, 0, 255));
        rl.EndShaderMode();

        // handle drawing of player
        player.draw(game);

        // Draw the bullets
        player.drawShots();

        // Handle Shot Collisions
        for (player.shootingMaster.shots[0..]) |*shot| {
            if (shot.active == sh.ShotStatus.ACTIVE) {
                const actors_by_line = try actor_master.gatherActorsByLine(shot.drawStart, shot.drawEnd);
                defer actors_by_line.deinit();
                if (actors_by_line.items.len > 0) {
                    const actor = actors_by_line.items[0];
                    var actor_rect: ?u.Rectangle = undefined;
                    var actor_mask: ?ai.ActorMask = undefined;
                    switch (actor.*) {
                        .diamond => |*sprite| {
                            actor_rect = sprite.sprite_position.asRectangle();
                            actor_mask = a_diamond.actor_image.actor_mask;
                        },
                        .grunt => |*sprite| {
                            actor_rect = sprite.sprite_position.asRectangle();
                            actor_mask = a_grunt.active_image.actor_mask;
                        },
                        else => {},
                    }
                    actor_master.removeActor(actors_by_line.items[0]);
                    shot.active = sh.ShotStatus.REMOVING;
                }
            }
        }

        // handle update of the actors
        actor_master.handleUpdate(game, player, deltaTime);

        // handle drawing of the actors
        actor_master.handleDraw();

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

/// New Actor Placement
/// Create a new actor within the bounds of the play field with options:
/// - allow overlap
/// - distance from the player starting position
pub fn newActorPlacement(actor_type: @TypeOf(.diamond), game: g.Game, player: p.Player, actor_master: *a.ActorMaster, rng: *std.Random.Xoshiro256, distance_from_player: f32, allow_overlap: bool) a.Actor {
    const player_frame_x_min = @as(u32, @intFromFloat(game.playerFrame.frameStart.x));
    const player_frame_x_max = @as(u32, @intFromFloat(game.playerFrame.frameStart.x + game.playerFrame.frameSize.x));
    const player_frame_y_min = @as(u32, @intFromFloat(game.playerFrame.frameStart.y));
    const player_frame_y_max = @as(u32, @intFromFloat(game.playerFrame.frameStart.y + game.playerFrame.frameSize.y));

    _ = allow_overlap;

    while (true) {
        const x = @as(f32, @floatFromInt(u.generateRandomIntInRange(rng, player_frame_x_min, player_frame_x_max)));
        const y = @as(f32, @floatFromInt(u.generateRandomIntInRange(rng, player_frame_y_min, player_frame_y_max)));

        var new_actor: a.Actor = undefined;
        switch (actor_type) {
            .diamond => new_actor = a.Actor{ .diamond = a_diamond.Diamond.init(x, y) },
            .grunt => new_actor = a.Actor{ .grunt = a_grunt.Grunt.init(x, y, @as(f32, @floatFromInt(game.screen.height))) },
            else => {},
        }

        var rect_test: u.Rectangle = undefined;
        var distance: f32 = undefined;

        switch (new_actor) {
            inline else => |actor| {
                rect_test = u.Rectangle.init(x, y, actor.sprite_position.width, actor.sprite_position.height);
                distance = u.calculateDistance(player.center.toVector2(), actor.sprite_position.center.toVector2());
            },
        }

        // check distance from player.
        const padding = 5;
        if (distance > distance_from_player) {
            if (rect_test.x + padding > @as(f32, @floatFromInt(player_frame_x_min)) and
                rect_test.y + padding > @as(f32, @floatFromInt(player_frame_y_min)) and
                rect_test.x + rect_test.width + padding < @as(f32, @floatFromInt(player_frame_x_max)) and
                rect_test.y + rect_test.height + padding < @as(f32, @floatFromInt(player_frame_y_max)))
            {

                // Check if new actor collides with any other actor.
                const actor_collided_with = actor_master.checkCollision(rect_test, a_diamond.actor_image, true);
                if (actor_collided_with) |_| {} else {
                    return new_actor;
                }
            }
        }
    }
}
