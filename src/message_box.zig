const std = @import("std");

// zig fmt: off
pub const MessageBox = struct {
    lines: std.ArrayList([]u8),

    pub fn init() MessageBox {
        var buffer: [10*100]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        return MessageBox{.lines = std.ArrayList(u8).init(fba.allocator())};
    }

    pub fn add(self: *@This(), line: []u8) void {
        self.lines.append(line);
    }
};