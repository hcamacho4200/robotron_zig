const std = @import("std");

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const u = @import("../util.zig");

pub const ActorMask = struct {
    width: i32,
    height: i32,
    mask: [*]u8,

    pub fn init(image: rl.Image) ActorMask {
        const width = image.width;
        const height = image.height;
        const mask_length = @as(usize, @intCast(width)) * @as(usize, @intCast(height));

        var mask = @as([*]u8, @ptrCast(image.data));

        for (0..mask_length) |i| {
            const alpha = @as([*]u8, @ptrCast(image.data))[i * 4 + 3];
            mask[i] = if (alpha > 50) 1 else 0;
        }

        return ActorMask{
            .width = width,
            .height = height,
            .mask = mask,
        };
    }

    pub fn dumpMask(self: *const @This()) void {
        std.debug.print("\n", .{});
        const width = @as(usize, @intCast(self.width));
        const height = @as(usize, @intCast(self.height));
        for (0..height) |y| {
            for (0..width) |x| {
                std.debug.print("{}", .{self.mask[y * width + x]});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
    }
};

pub const ActorImage = struct {
    texture: rl.Texture,
    image: rl.Image,
    actor_mask: ActorMask,
    width: f32,
    height: f32,

    pub fn init(texture_path: [*c]const u8, frames: f32) ActorImage {
        const texture = rl.LoadTexture(texture_path);
        const image = rl.LoadImageFromTexture(texture);

        const width = texture.width;
        const height = texture.height;

        return ActorImage{
            .texture = texture,
            .image = image,
            .actor_mask = ActorMask.init(image),
            .width = @as(f32, @floatFromInt(width)) / frames,
            .height = @as(f32, @floatFromInt(height)),
        };
    }

    pub fn getFrameRect(self: *@This(), frame: f32) rl.Rectangle {
        return rl.Rectangle.init(frame * self.width, 0, self.width, self.height);
    }
};

pub const ActorBump = struct {
    frames: f32,
    activeFrame: f32,
    frameBeforeBump: f32,
    frameBeforeCount: f32,

    pub fn init(total_frames: f32, frames_before_bump: f32) ActorBump {
        return ActorBump{
            .frames = total_frames,
            .activeFrame = 0,
            .frameBeforeBump = frames_before_bump,
            .frameBeforeCount = 0,
        };
    }

    pub fn bumpActiveFrame(self: *ActorBump) void {
        if (self.frameBeforeCount > self.frameBeforeBump) {
            self.frameBeforeCount = 0;
            self.activeFrame += 1;
            if (self.activeFrame > self.frames) {
                self.activeFrame = 0;
                std.debug.print("resetting bump\n", .{});
            }
            std.debug.print("bumpActiveFrame {} {}\n", .{ self.activeFrame, self.frames });
        }
        self.frameBeforeCount += 1;
    }
};

pub const ActorDirection = enum { DOWN, UP, LEFT, RIGHT };

pub const ActorContainer = struct {
    images: [@typeInfo(ActorDirection).Enum.fields.len]ActorImage = undefined,

    pub fn init() ActorContainer {
        return ActorContainer{};
    }

    pub fn addImage(self: *@This(), direction: ActorDirection, actor_image: ActorImage) void {
        self.images[@intFromEnum(direction)] = actor_image;
    }

    pub fn getImage(self: *@This(), direction: ActorDirection) *ActorImage {
        return &self.images[@intFromEnum(direction)];
    }
};
