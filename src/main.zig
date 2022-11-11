const std = @import("std");
const testing = std.testing;

pub const span = @import("span.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
