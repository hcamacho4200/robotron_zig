pub const Empty = struct {
    active: bool,

    pub fn init() Empty {
        return Empty{ .active = false };
    }
};
