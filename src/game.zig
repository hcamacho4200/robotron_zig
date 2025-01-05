// zig fmt: off
pub const Game = struct {
    title: [*c]const u8, 
    screen: struct { 
        width: c_int, 
        height: c_int,
        updated: bool
    }, 
    frameCount: u64,

    pub fn updateScreenSize(self: *Game,  width: c_int, height: c_int) void {
        self.screen.width = width;
        self.screen.height = height;
        self.screen.updated = true;
    }
};