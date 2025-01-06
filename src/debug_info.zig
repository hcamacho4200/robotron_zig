const std = @import("std");
const g = @import("./game.zig");
const rlzb = @import("rlzb");
const rl = rlzb.raylib;

pub fn handleDisplayDebugInfo(game: g.Game, deltaTime: f32) !void {
    const fontSize = 20;
    const start = 10;
    var line: c_int = 0;

    var buffer: [100]u8 = undefined;

    if (game.debugInfo) {
        const newFontSize: f32 = @as(f32, @floatFromInt(fontSize)) * game.screen.scalingFactor;

        var message = try std.fmt.bufPrintZ(&buffer, "Delta Time: {d:.4}", .{deltaTime});
        rl.DrawText(message.ptr, 10, start + (line * @as(c_int, @intFromFloat(newFontSize))), @as(c_int, (@intFromFloat(newFontSize))), rl.GRAY);

        line += 1;
        message = try std.fmt.bufPrintZ(&buffer, "Height: {}", .{game.screen.height});
        rl.DrawText(message.ptr, 10, start + (line * @as(c_int, @intFromFloat(newFontSize))), @as(c_int, (@intFromFloat(newFontSize))), rl.GRAY);

        line += 1;
        message = try std.fmt.bufPrintZ(&buffer, "Original Height: {}", .{game.screen.originalHeight});
        rl.DrawText(message.ptr, 10, start + (line * @as(c_int, @intFromFloat(newFontSize))), @as(c_int, (@intFromFloat(newFontSize))), rl.GRAY);

        line += 1;
        message = try std.fmt.bufPrintZ(&buffer, "Scale: {d:.2}", .{game.screen.scalingFactor});
        rl.DrawText(message.ptr, 10, start + (line * @as(c_int, @intFromFloat(newFontSize))), @as(c_int, (@intFromFloat(newFontSize))), rl.GRAY);

        line += 1;
        message = try std.fmt.bufPrintZ(&buffer, "Frames/s: {d:.2}", .{60 / (60 * deltaTime)});
        rl.DrawText(message.ptr, 10, start + (line * @as(c_int, @intFromFloat(newFontSize))), @as(c_int, (@intFromFloat(newFontSize))), rl.GRAY);
    }
}
