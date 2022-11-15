const std = @import("std");
const testing = std.testing;

pub const Span = @import("span.zig");
pub const instrument = @import("instrument.zig").instrument;

test {
    const instrument_tests = @import("instrument.tests.zig");
    _ = instrument_tests;
    @import("std").testing.refAllDecls(@This());
}
