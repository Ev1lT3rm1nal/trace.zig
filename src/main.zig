const std = @import("std");
const testing = std.testing;

pub const TracePoint = @import("trace_point.zig").TracePoint;
pub const TraceType = @import("trace_point.zig").TraceType;

test "Array Lengt" {
  const expectEqual = @import("std").testing.expectEqual;
  const string = "Test string";
  try expectEqual(11, string.len);
}
