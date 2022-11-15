const std = @import("std");

pub const TraceType = enum(u2) {
    span_open = 0,
    span_close = 1,
    event = 2,
    error_event = 3,
    pub fn format(self: TraceType, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        const name = switch (self) {
            .span_open => "Span open",
            .span_close => "Span close",
            .event => "Event",
            .error_event => "Error event",
        };
        try writer.print("{s}", .{name});
        try writer.writeAll("");
    }
};

pub const TracePoint = struct {
    id: []const u8,
    timestamp: u64,
    trace_type: TraceType,
    pub fn format(self: TracePoint, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("tp;{d};{};{s}", .{ self.timestamp, @enumToInt(self.trace_type), self.id });
        try writer.writeAll("");
    }
};

test "TracePoint.format" {
    const testing = std.testing;
    const expect = std.testing.expect;
    const eql = std.mem.eql;
    const test_allocator = testing.allocator;
    const trace_point = TracePoint{
        .id = "Test Id",
        .trace_type = TraceType.span_close,
        .timestamp = 123,
    };
    const trace_point_string = try std.fmt.allocPrint(test_allocator, "{}", .{trace_point});
    defer test_allocator.free(trace_point_string);
    try expect(eql(
        u8,
        trace_point_string,
        "tp;123;1;Test Id",
    ));
}
