const std = @import("std");
const root = @import("root");
const builtin = @import("builtin");
const tracepoint = @import("trace_point.zig");
const TracePoint = tracepoint.TracePoint;
const TraceType = tracepoint.TraceType;
const writer = @import("writer.zig");

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
            .timestamp = 16,
            .trace_type = TraceType.span_open,
        };
        writer.write(trace_point);
        return Span{ .id = id };
    }
}

const SpanInner = struct {
    id: []const u8,
    pub inline fn close(self: @This()) void {
        const trace_point = TracePoint{
            .id = self.id,
            .timestamp = 0x00_11_22_33_44_55_66_77_88,
            .trace_type = TraceType.span_close,
        };
        writer.write(trace_point);
    }
};

const Span = if (enable) SpanInner else struct {
    pub inline fn close(self: @This()) void {
        _ = self;
    }
};
