const std = @import("std");
const root = @import("root");
const TracePoint = @import("trace_point.zig").TracePoint;

pub inline fn write(trace_point: TracePoint) void {
    if (@hasDecl(root, "writeTracePoint")) {
        root.writeTracePoint(trace_point);
    } else {
        writeDefault(trace_point);
    }
}

inline fn writeDefault(trace_point: TracePoint) void {
    std.log.info(";{}", .{trace_point});
}
