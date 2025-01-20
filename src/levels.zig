const std = @import("std");
const expect = @import("std").testing.expect;

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const Diamond = @import("./actors/diamond.zig").Diamond;
const Empty = @import("./actors/empty.zig").Empty;
const Mine = @import("./actors/mine.zig").Mine;
const Star = @import("./actors/star.zig").Star;

const Actor = union(enum) {
    diamond: Diamond,
    mine: Mine,
    star: Star,
    empty: Empty,
};

const ActorMaster = struct {
    actors: [1024]Actor,

    pub fn init() ActorMaster {
        var uninitialized: [1024]Actor = undefined;
        for (uninitialized[0..]) |*actor| {
            actor.* = Actor{ .empty = Empty.init() };
        }

        return ActorMaster{ .actors = uninitialized };
    }

    pub fn processActors(self: *@This()) void {
        for (self.actors) |actor| {
            std.debug.print("  {}\n", .{actor});
        }
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
};

// zig fmt: on

test "This is a test" {
    @setEvalBranchQuota(10_000);
    var actor_master = ActorMaster.init();
    actor_master.processActors();
    actor_master.addActor(Actor{ .diamond = Diamond.init(100, 200) });
    actor_master.addActor(Actor{ .mine = Mine.init(0, 0) });
    actor_master.listActive();
    actor_master.handleUpdate();

    switch (actor_master.actors[0]) {
        .diamond => {
            actor_master.actors[0].diamond.actor_interface.sprite.handleDraw(&actor_master.actors[0]);
        },
        .mine => {},
        else => {
            std.debug.print("ignore ", .{});
        },
    }

    try expect(true);

    // var shape_d1 = Shape{ .diamond = Diamond{ .x = 100, .y = 200, .active = true } };
    // shape_d1.diamond.setPosition(50, 50);
    // std.debug.print("\n{}\n", .{shape_d1});

    // var shape_m1 = Shape{ .mine = Mine{ .x = 100, .y = 200, .active = true } };
    // shape_m1.mine.setPosition(51, 51);
    // std.debug.print("{}\n", .{shape_m1});

    // var shape_s1 = Shape{ .star = Star{ .x = 100, .y = 200, .active = true } };
    // shape_s1.star.setPosition(51, 51);
    // std.debug.print("{}\n", .{shape_s1});

    // for (shapes[0..]) |*shape| {
    //     shape.* = Shape{ .empty = Empty.init() };
    // }

    // for (shapes) |shape| {
    //     std.debug.print("  {}\n", .{shape});
    // }
}
