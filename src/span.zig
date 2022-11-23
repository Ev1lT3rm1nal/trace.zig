const std = @import("std");
const root = @import("root");
const builtin = @import("builtin");
const tracepoint = @import("trace_point.zig");
const TracePoint = tracepoint.TracePoint;
const TraceType = tracepoint.TraceType;
const writer = @import("writer.zig");
const clock = @import("clock.zig");

const enable = if (@hasDecl(root, "enable_trace")) root.enable_trace else if (builtin.is_test)
    true
else
    false;

pub inline fn open(comptime id: []const u8) Span {
    if (!enable) {
        return .{};
    } else {
        const trace_point = TracePoint{
            .id = id,
            .timestamp = clock.timestamp(),
            .trace_type = TraceType.span_open,
        };
        writer.write(trace_point);
        return Span{ .id = id };
    }
}

const PrivateSpan = struct {
    id: []const u8,
    pub inline fn close(self: @This()) void {
        const trace_point = TracePoint{
            .id = self.id,
            .timestamp = clock.timestamp(),
            .trace_type = TraceType.span_close,
        };
        writer.write(trace_point);
    }
};

const Span = if (enable) PrivateSpan else struct {
    pub inline fn close(self: @This()) void {
        _ = self;
    }
};

test "Span open and close" {
    const span = open("Span Test Id 1");
    defer span.close();
}

test "PrivateSpan" {
    // Arrange
    const private_span = PrivateSpan{ .id = "Test Private Span" };
    // Act
    private_span.close();
}
