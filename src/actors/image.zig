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

    /// isPixelCollsion - test if two masks have a shared pixel
    // pub fn isPixelCollision(self: *@This(), rect_actor: u.Rectangle, test_mask: ActorMask, rect_test: u.Rectangle, overlap_rect: u.Rectangle ) bool {

    //     for (0..overlap_rect.height) | overlap_y| {
    //         for (0..overlap_rect.width | overlap_x)| {
    //             const actor_mask_pixel = self.mask[(rect_actor.y - y) * width + (rect_actor.x - x)]
    //             const test_mask_pixel = test_mask.mask[(rect_test.y - y) * width + (rect_test.x - x)]

    //         }
    //     }

    // }

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
