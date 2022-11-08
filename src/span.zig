const std = @import("std");

const enable = true;

const SpanInner = struct {
  id: [] const u8,
  pub inline fn close(self:@This()) void {
    std.debug.print("Span closed {s}\n", .{self.id});
  }
};

pub const Span = if (enable) SpanInner else struct {
  pub inline fn close(self:@This()) void {
    _ = self;
  }
};

pub fn open(comptime id: [] const u8) Span {
  if (!enable) {
    return .{};
  }
  else {
    std.debug.print("\nSpan opened {s}\n", .{id});
    return Span{.id=id};
  }
}

test "Open and close span" {
  const span = open("TestId");
  defer span.close();
  std.debug.print("Span opened, closing is deferred\n", .{});
}