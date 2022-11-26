//! Namespace that contains the implementation of the default writer.

const std = @import("std");
const root = @import("root");
const TracePoint = @import("trace_point.zig").TracePoint;

/// The write function that writes a `TracePoint` either
/// using the `writeDefault` function or the `writeTracePoint`
/// function realized in the `root` file.
pub inline fn write(trace_point: TracePoint) void {
    if (@hasDecl(root, "writeTracePoint")) {
        root.writeTracePoint(trace_point);
    } else {
        writeDefault(trace_point);
    }
}

/// The default implementation of the `write`function.
///
/// Logs `TracePoints` with `std.log.info`.
inline fn writeDefault(trace_point: TracePoint) void {
    std.log.info(";{}", .{trace_point});
}

test "write" {
    // Arrange
    const TraceType = @import("trace_point.zig").TraceType;
    const trace_point = TracePoint{
        .id = "write Default Test",
        .timestamp = 1223,
        .trace_type = TraceType.span_open,
    };
    // Act
    write(trace_point);
    // Assert
}

test "writeDefault" {
    // Arrange
    const TraceType = @import("trace_point.zig").TraceType;
    const trace_point = TracePoint{
        .id = "write Default Test",
        .timestamp = 1223,
        .trace_type = TraceType.span_open,
    };
    // Act
    writeDefault(trace_point);
    // Assert
}
