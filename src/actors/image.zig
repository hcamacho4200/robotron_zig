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

    pub fn init(texture_path: [*c]const u8) ActorImage {
        const texture = rl.LoadTexture(texture_path);
        const image = rl.LoadImageFromTexture(texture);

        return ActorImage{
            .texture = texture,
            .image = image,
            .actor_mask = ActorMask.init(image),
        };
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

    pub fn getImage(self: *@This(), direction: ActorDirection) ActorImage {
        return self.images[@intFromEnum(direction)];
    }
};
