const std = @import("std");
const expect = @import("std").testing.expect;

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const d = @import("./actors/diamond.zig");
const ai = @import("./actors/image.zig");
const i = @import("./actors//interfaces.zig");
const u = @import("util.zig");

const Diamond = @import("./actors/diamond.zig").Diamond;
const Empty = @import("./actors/empty.zig").Empty;
const Mine = @import("./actors/mine.zig").Mine;
const Star = @import("./actors/star.zig").Star;

pub const Actor = union(enum) {
    diamond: Diamond,
    mine: Mine,
    star: Star,
    empty: Empty,
};

pub const ActorMaster = struct {
    actors: [1024]Actor,

    pub fn init() ActorMaster {
        var uninitialized: [1024]Actor = undefined;
        for (uninitialized[0..]) |*actor| {
            actor.* = Actor{ .empty = Empty.init() };
        }
        return ActorMaster{ .actors = uninitialized };
    }

    pub fn addActor(self: *@This(), new_actor: Actor) void {
        // _ = new_actor;
        for (self.actors[0..]) |*actor| {
            switch (actor.*) {
                .empty => {
                    actor.* = new_actor;
                    return;
                },
                else => {},
            }
        }
        std.debug.print("Unable to add actor\n", .{});
    }

    pub fn countActive(self: *@This()) usize {
        var size: usize = 0;
        for (self.actors[0..]) |*actor| {
            switch (actor.*) {
                .empty => {},
                else => {
                    size += 1;
                },
            }
        }
        return size;
    }

    pub fn listActive(self: *@This()) void {
        for (self.actors[0..]) |*actor| {
            switch (actor.*) {
                .empty => {},
                else => {
                    std.debug.print("Found {}\n", .{actor});
                },
            }
        }
    }

    pub fn handleUpdate(self: *@This()) void {
        for (self.actors[0..]) |*actor| {
            switch (actor.*) {
                .diamond => actor.diamond.actor_interface.sprite.handleUpdate(actor),
                .mine => actor.mine.actor_interface.sprite.handleUpdate(actor),
                else => {},
            }
        }
    }

    pub fn handleDraw(self: *@This()) void {
        for (self.actors[0..]) |*actor| {
            switch (actor.*) {
                .diamond => actor.diamond.actor_interface.sprite.handleDraw(actor),
                else => {},
            }
        }
    }

    pub fn removeActor(self: *@This(), actor: *Actor) void {
        std.debug.print("removing actor {}", .{actor});
        for (0..self.actors.len) |idx| {
            if (&self.actors[idx] == actor) {
                self.actors[idx] = Actor{ .empty = Empty.init() };
            }
        }
    }

    const CollisionResult = struct { actor: *Actor, overlap: u.Rectangle, pixel: bool };

    pub fn checkCollision(self: *@This(), rect_test: u.Rectangle, test_image: ai.ActorImage, rectange_only: bool) ?CollisionResult {
        for (self.actors[0..]) |*actor| {
            var rect_actor: u.Rectangle = undefined;
            var actor_mask: ai.ActorMask = undefined;
            switch (actor.*) {
                .diamond => {
                    rect_actor = u.Rectangle.init(
                        actor.diamond.sprite_position.x,
                        actor.diamond.sprite_position.y,
                        actor.diamond.sprite_position.width,
                        actor.diamond.sprite_position.height,
                    );
                    actor_mask = d.actor_image.actor_mask;
                },
                else => {},
            }
            const overlap = u.isOverLappingRectangles(rect_actor, rect_test);
            if (overlap) |overlap_rectangle| {
                var result = CollisionResult{ .actor = actor, .overlap = overlap_rectangle, .pixel = true };

                if (!rectange_only) {
                    const pixel_collision = u.detectPixelOverlap(actor_mask.mask, rect_actor, test_image.actor_mask.mask, rect_test, overlap_rectangle);
                    std.debug.print("rect collsion {}\n", .{overlap_rectangle});
                    if (pixel_collision) {
                        std.debug.print("pixel collsion {}\n", .{result});
                        result = CollisionResult{ .actor = actor, .overlap = overlap_rectangle, .pixel = true };
                    }
                }
                return result;
            }
        }
        return null;
    }

    pub fn getEdgesFromActor(self: *const @This(), actor: *const Actor) ?[4]i.SpriteEdge {
        _ = self;
        switch (actor.*) {
            .diamond => {
                return actor.diamond.sprite_position.getEdges();
            },
            else => {
                return null;
            },
        }
    }

    /// Gather Actors by Line
    /// Looking for actors that intersect a line segment, ie: shot
    /// - build line
    /// - gather edges from actor
    /// - test if the edges and the line intersect
    /// - add to action_master (tmp)
    /// - return
    /// - TODO: sort the CD actors by distance from the center of player.
    pub fn gatherActorsByLine(self: *@This(), start: rl.Vector2, end: rl.Vector2) !*std.ArrayList(*Actor) {
        const found_actors = try std.heap.page_allocator.create(std.ArrayList(*Actor));
        found_actors.* = std.ArrayList(*Actor).init(std.heap.page_allocator);

        for (self.actors[0..]) |*actor| {
            switch (actor.*) {
                .diamond => {
                    const optional_edges = self.getEdgesFromActor(actor);
                    if (optional_edges) |edges| {
                        for (edges[0..]) |edge| {
                            var collision_point = rl.Vector2.init(0, 0);
                            if (rl.CheckCollisionLines(start, end, edge.start, edge.end, &collision_point)) {
                                found_actors.*.append(@constCast(actor)) catch |err| std.debug.print("Unable to add actor {}", .{err});
                            }
                        }
                    }
                },
                else => {},
            }
        }
        return found_actors;
    }

    test "Gather Actors By Line" {
        var actor_master = ActorMaster.init();
        actor_master.addActor(Actor{ .diamond = Diamond.init(535, 560) });

        const start = rl.Vector2.init(560, 560);
        const end = rl.Vector2.init(560, 602);

        const actual = try actor_master.gatherActorsByLine(start, end);
        std.debug.print("output {} {any}\n", .{ actual.items.len, actual.items[0] });

        try expect(actual.items.len == 1);
        try expect(false);
    }
};
