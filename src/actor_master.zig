const std = @import("std");
const expect = @import("std").testing.expect;

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const d = @import("./actors/diamond.zig");
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
                    std.debug.print("Found empty {}\n", .{actor});
                    actor.* = new_actor;
                    return;
                },
                else => {},
            }
        }
        std.debug.print("Unable to add actor\n", .{});
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

    pub fn checkCollision(self: *@This(), rect_test: u.Rectangle) ?struct { actor: *Actor, overlap: u.Rectangle } {
        for (self.actors[0..]) |*actor| {
            var rect_actor: u.Rectangle = undefined;
            switch (actor.*) {
                .diamond => {
                    rect_actor = u.Rectangle.init(
                        actor.diamond.sprite_position.x,
                        actor.diamond.sprite_position.y,
                        actor.diamond.sprite_position.width,
                        actor.diamond.sprite_position.height,
                    );
                },
                else => {},
            }
            const overlap = u.isOverLappingRectangles(rect_actor, rect_test);
            if (overlap) |overlap_rectangle| {
                return .{ .actor = actor, .overlap = overlap_rectangle };
            }
        }
        return null;
    }
};

// zig fmt: on

test "This is a test" {
    @setEvalBranchQuota(10_000);
    var actor_master = ActorMaster.init();
    actor_master.addActor(Actor{ .diamond = Diamond.init(100, 200) });
    actor_master.addActor(Actor{ .mine = Mine.init(0, 0) });
    actor_master.listActive();
    actor_master.handleUpdate();
    try expect(true);
}

test "Checking" {
    const TestType = struct { active: bool };
    var testType = TestType{ .active = true };
    testType.active = false;
    std.debug.print("{}", .{testType});
}
