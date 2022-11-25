//! Namespace containing all types and  methods that define a `TracePoint`.

const std = @import("std");

/// An enumeration the enables the differentiation of different trace points.
pub const TraceType = enum(u2) {
    /// Used when a `Span` is opened.
    span_open = 0,
    /// Used when a `Span` is closed.
    span_close = 1,
    /// Used when an event is traced.
    event = 2,
    /// Used when an error event is traced.
    error_event = 3,

    /// Formats `TraceType` into a more human readable output.
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

/// Defines a trace point, i.e. a point in time with a unique identifier
/// and an a `TraceType`.
pub const TracePoint = struct {
    /// The unique identifier of the `TracePoint`.
    id: []const u8,
    /// The timestamp of the `TracePoint`.
    timestamp: u64,
    /// The `TraceType` of the `TracePoint`.
    trace_type: TraceType,

    /// Formats the `TracePoint` to a string slice.
    ///
    /// This is used in the default writer implementation to log the trace point.
    /// The format is:
    ///
    /// ```
    /// tp;<timestamp>;<trace type as u8>;<identifier as string>
    /// ```
    ///
    /// 1. `;` is used so that the log output can easily be further processed as CSV.
    /// 2. `tp` is added to simplify filtering for "t"race "p"oints in the log output.
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
