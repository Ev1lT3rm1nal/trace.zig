const std = @import("std");
const testing = std.testing;

pub const Span = @import("span.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
