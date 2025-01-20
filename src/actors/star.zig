pub const Star = struct {
    x: f32,
    y: f32,
    active: bool,

    pub fn setPosition(self: *@This(), x: f32, y: f32) void {
        self.x = x;
        self.y = y;
    }
};
