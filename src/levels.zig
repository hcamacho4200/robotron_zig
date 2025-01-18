const std = @import("std");
const expect = @import("std").testing.expect;

const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

pub const ActorPosition = struct { origin: rl.Vector2, width: f32, height: f32, rectTL: rl.Vector2, rectLR: rl.Vector2 };

pub const ActorType = enum { DIAMOND, TRIANGLE, STAR, MINE };
const ActorInterface = struct {
    draw: fn (self: *ActorObject) void,
    detectCollision: fn (self: *ActorObject, otherActor: ActorObject) bool,
    setPosition: fn (self: *ActorObject, position: rl.Vector2) ActorPosition,
};

const Diamond = struct {
    position: ActorPosition,
    interface: ActorInterface,
    // zig fmt: off
    pub fn init() Diamond {
        return Diamond{ 
            .position = .{ 
                .origin = rl.Vector2.init(50, 50), 
                .rectTL = rl.Vector2.init(50, 50), 
                .rectLR = rl.Vector2.init(50, 50), 
                .height = 10, 
                .width = 10 
            },
            .interface = .{
                .draw = drawDiamond,
                .detectCollision = detectCollisionDiamond,
                .setPosition = setPosition
                
            } 
        };
    }
};
// zig fmt: on

fn drawDiamond(self: *ActorObject) void {
    std.log.info("draw {}", .{self.position.origin});
}

fn detectCollisionDiamond(self: *ActorObject, other: ActorObject) bool {
    std.log.info("detect {} {}", .{ self.position.origin, other });
    return false;
}

fn setPosition(self: *ActorObject, position: rl.Vector2) ActorPosition {
    std.log.info("setPosition {} {}", .{ self.position.origin, position });
    return ActorPosition{ .origin = rl.Vector2.init(50, 50), .rectTL = rl.Vector2.init(50, 50), .rectLR = rl.Vector2.init(50, 50), .height = 10, .width = 10 };
}

const Triangle = struct { position: ActorPosition, interface: ActorInterface };

const Star = struct { position: ActorPosition, interface: ActorInterface };

const Mine = struct { position: ActorPosition, interface: ActorInterface };

const ActorObject = union(enum) { DIAMOND: Diamond, TRIANGLE: Triangle, STAR: Star, MINE: Mine };

const level = struct {
    numDiamonds: u16,
    numTriangles: u16,
    numStars: u16,
    numMines: u16,
};

const levels = struct {
    levels: []level,
};

test "This is a test" {
    const d1 = Diamond.init();
    const d2 = Diamond.init();

    var test_actors: [2]ActorInterface = [_]ActorInterface{ d1.interface, d2.interface };

    for (test_actors[0..]) |actor| {
        std.log.info("{}", .{actor});
    }
    try expect(false);
}
