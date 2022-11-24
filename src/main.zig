/// Span enables to trace a time span in the source code.
///
/// ## Example usages
///
/// The examples assumes that you have cloned this repository into the path `./third_party/`.
/// trace.zig can also be used as a package, the basic steps are described in the `README.md` of the repository.
///
/// 1. Creation of a timespan for a function
///
/// ```
/// const trace = @import("./third_party/trace.zig/src/main.zig");
/// const Span = trace.Span;
///
/// pub const enable_trace = true; // must be enabled otherwise traces will be no-ops
///
/// fn myFunc() void {
///     const span = Span.open("A unique identifier");
///     defer span.close(); // Span is closed automatically when the function returns
///
///     // execute the logic of myFunc
///     // ...
///
///     // as mentioned above, span is closed here.
/// }
/// ```
///
/// 2. Usage by calling `close` on the span at a specific line in the source code
///
/// ```
/// const trace = @import("./third_party/trace.zig/src/main.zig");
/// const Span = trace.Span;
///
/// pub const enable_trace = true; // must be enabled otherwise traces will be no-ops
///
/// fn anotherFunc() void {
///    // some logic happens here
///    // ...
///
///    const span = Span.open("Another unique identifier");
///    // some more logic
///    // ...
///    span.close(); // should close the span at this location
///
///    // usage inside a block together with defer is also possible
///    {
///         const span_2 = Span.open("Yet another unique identifier");
///         defer span.close(); // will close the span when this block is exited
///
///         // some logic here
///         // ...
///
///         // span.close() happens here.
///    }
/// }
/// ```
///
/// ## On unique identifiers
///
/// TODO
///
/// ## Writer and Clock interface
///
/// TODO
/// 1. what is the default behavior
/// 2. how to override and why
/// ```
pub const Span = @import("span.zig");

/// Instrument a function.
pub const instrument = @import("instrument.zig").instrument;

test {
    const instrument_tests = @import("instrument.tests.zig");
    _ = instrument_tests;
    @import("std").testing.refAllDecls(@This());
}
