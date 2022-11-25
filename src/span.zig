//! Span namespace contains the types and functions that realize spans.
//! Spans enable to trace a time span in the source code.
//!
//! ## Further example usage
//!
//! Usage by calling `close` on the span at a specific line in the source code
//! and using spans inside a block.
//!
//! ```
//! const trace = @import("./third_party/trace.zig/src/main.zig");
//! const Span = trace.Span;
//!
//! pub const enable_trace = true; // must be enabled otherwise traces will be no-ops
//!
//! fn anotherFunc() void {
//!    // some logic happens here
//!    // ...
//!
//!    const span = Span.open("Another unique identifier");
//!    // some more logic
//!    // ...
//!    span.close(); // should close the span at this location
//!
//!    // usage inside a block together with defer is also possible
//!    {
//!         const span_2 = Span.open("Yet another unique identifier");
//!         defer span.close(); // will close the span when this block is exited
//!
//!         // some logic here
//!         // ...
//!
//!         // span.close() happens here.
//!    }
//! }
//! ```

const root = @import("root");
const builtin = @import("builtin");
const tracepoint = @import("trace_point.zig");
const TracePoint = tracepoint.TracePoint;
const TraceType = tracepoint.TraceType;
const writer = @import("writer.zig");
const clock = @import("clock.zig");

/// Is checked during compile time. When false then Span's function are realized as no-ops.
const enable = if (@hasDecl(root, "enable_trace")) root.enable_trace else if (builtin.is_test)
    true
else
    false;

/// Opens a span.
///
/// ## Returns
///
/// A span. If tracing is not enabled (define `pub const enable_trace=true` in your `root`)
/// this function returns an empty struct.
/// Otherwise it returns a strcut with the public method `close` with no parameters.
/// This method shoud be called whenever the span needs to be closed. See Span namespace
/// documentation for complete usage example.
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

/// Namespace private realization of Span, when tracing is enabled.
/// Used to avoid usage errors from callees. A span needs to be opened
/// with `open` to work correctly. Creating a span from with its member
/// variables would be wrong.
const PrivateSpan = struct {
    id: []const u8,
    /// Struct method that must be called to close the span.
    pub inline fn close(self: @This()) void {
        const trace_point = TracePoint{
            .id = self.id,
            .timestamp = clock.timestamp(),
            .trace_type = TraceType.span_close,
        };
        writer.write(trace_point);
    }
};

/// Span type, which is used to create time spans in the source code.
/// Is either realized by `PrivateSpan` or by an empty anonymous stuct.
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
