const std = @import("std");

const ActorInterface = @import("interfaces.zig").ActorInterface;
const SpriteInterface = @import("interfaces.zig").SpriteInterface;

pub const Mine = struct {
    x: f32,
    y: f32,
    actor_interface: ActorInterface,

    pub fn init(x: f32, y: f32) Mine {
        return Mine{
            .x = x,
            .y = y,
            .actor_interface = ActorInterface{ .sprite = SpriteInterface{ .handleDraw = handleDraw, .handleUpdate = handleUpdate } },
        };
    }

    pub fn setPosition(self: *@This(), x: f32, y: f32) void {
        self.x = x;
        self.y = y;
    }
};

pub fn handleDraw(self: *anyopaque) void {
    const mine: *Mine = @alignCast(@ptrCast(self));
    std.debug.print("Mine draw {} {d}\n", .{ self, mine.x });
}

pub fn handleUpdate(self: *anyopaque) void {
    const mine: *Mine = @alignCast(@ptrCast(self));
    std.debug.print("Mine Update {} {d}\n", .{ self, mine.x });
}
