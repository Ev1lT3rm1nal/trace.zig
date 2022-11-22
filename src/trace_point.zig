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

test "TraceType.format" {
    // Arrange
    const expect = std.testing.expect;
    const eql = std.mem.eql;
    const test_allocator = std.testing.allocator;
    const trace_type_span_open = TraceType.span_open;
    const trace_type_span_close = TraceType.span_close;
    const trace_type_trace_event = TraceType.event;
    const trace_type_trace_error = TraceType.error_event;

    // Act
    const trace_type_span_open_string = try std.fmt.allocPrint(test_allocator, "{}", .{trace_type_span_open});
    defer test_allocator.free(trace_type_span_open_string);
    const trace_type_span_close_string = try std.fmt.allocPrint(test_allocator, "{}", .{trace_type_span_close});
    defer test_allocator.free(trace_type_span_close_string);
    const trace_type_trace_event_string = try std.fmt.allocPrint(test_allocator, "{}", .{trace_type_trace_event});
    defer test_allocator.free(trace_type_trace_event_string);
    const trace_type_trace_error_string = try std.fmt.allocPrint(test_allocator, "{}", .{trace_type_trace_error});
    defer test_allocator.free(trace_type_trace_error_string);

    // Assert
    try expect(eql(
        u8,
        trace_type_span_open_string,
        "Span open",
    ));
    try expect(eql(
        u8,
        trace_type_span_close_string,
        "Span close",
    ));
    try expect(eql(
        u8,
        trace_type_trace_event_string,
        "Event",
    ));
    try expect(eql(
        u8,
        trace_type_trace_error_string,
        "Error event",
    ));
}

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
    // Arrange
    const testing = std.testing;
    const expect = std.testing.expect;
    const eql = std.mem.eql;
    const test_allocator = testing.allocator;
    const trace_point = TracePoint{
        .id = "Test Id",
        .trace_type = TraceType.span_close,
        .timestamp = 123,
    };

    // Act
    const trace_point_string = try std.fmt.allocPrint(test_allocator, "{}", .{trace_point});
    defer test_allocator.free(trace_point_string);

    // Assert
    try expect(eql(
        u8,
        trace_point_string,
        "tp;123;1;Test Id",
    ));
}
