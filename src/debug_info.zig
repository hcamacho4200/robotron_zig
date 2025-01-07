const std = @import("std");
const g = @import("./game.zig");
const p = @import("./player.zig");
const rlzb = @import("rlzb");
const rl = rlzb.raylib;

pub fn handleDisplayDebugInfo(game: g.Game, player: p.Player, deltaTime: f32) !void {
    const fontSize = 20;
    const start_x = 10;
    const start_y = 10;
    const debugColor = rl.YELLOW;

    var line: c_int = 0;

    var buffer: [100]u8 = undefined;

    if (game.debugInfo) {
        const newFontSize: f32 = @as(f32, @floatFromInt(fontSize)) * game.screen.scalingFactor;

        var message = try std.fmt.bufPrintZ(&buffer, "Delta Time: {d:.4}", .{deltaTime});
        rl.DrawText(message.ptr, start_x, start_y + (line * @as(c_int, @intFromFloat(newFontSize))), @as(c_int, (@intFromFloat(newFontSize))), debugColor);

        line += 1;
        message = try std.fmt.bufPrintZ(&buffer, "Height: {}", .{game.screen.height});
        rl.DrawText(message.ptr, start_x, start_y + (line * @as(c_int, @intFromFloat(newFontSize))), @as(c_int, (@intFromFloat(newFontSize))), debugColor);

        line += 1;
        message = try std.fmt.bufPrintZ(&buffer, "Original Height: {}", .{game.screen.originalHeight});
        rl.DrawText(message.ptr, start_x, start_y + (line * @as(c_int, @intFromFloat(newFontSize))), @as(c_int, (@intFromFloat(newFontSize))), debugColor);

        line += 1;
        message = try std.fmt.bufPrintZ(&buffer, "Scale: {d:.2}", .{game.screen.scalingFactor});
        rl.DrawText(message.ptr, start_x, start_y + (line * @as(c_int, @intFromFloat(newFontSize))), @as(c_int, (@intFromFloat(newFontSize))), debugColor);

        line += 1;
        message = try std.fmt.bufPrintZ(&buffer, "Frames/s: {d:.2}", .{60 / (60 * deltaTime)});
        rl.DrawText(message.ptr, start_x, start_y + (line * @as(c_int, @intFromFloat(newFontSize))), @as(c_int, (@intFromFloat(newFontSize))), debugColor);

        line += 1;
        message = try std.fmt.bufPrintZ(&buffer, "Player X: {d:.4}, Y: {d:.4}", .{ player.position.x, player.position.y });
        rl.DrawText(message.ptr, start_x, start_y + (line * @as(c_int, @intFromFloat(newFontSize))), @as(c_int, (@intFromFloat(newFontSize))), debugColor);
    }
}
