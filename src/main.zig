const std = @import("std");
const testing = std.testing;

pub const span = @import("span.zig");

const enable_trace = true;

test {
 @import("std").testing.refAllDecls(@This());
 const span_1 = span.open("Main Id");
 defer span_1.close();
}