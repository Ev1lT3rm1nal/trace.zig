//! Small and simple tracing library for the Zig programming language.
//!
//! ## How to install
//!
//! 1. Requires Zig compiler version 0.10.0
//! 2. Clone / copy repository locally
//! 3. Either import `main.zig` into your project:
//!
//! ```
//! const trace = @import("<path to the repository>/src/main.zig");
//! ```
//!
//! 4. Or define it as a package in your `build.zig`:
//!
//! ```
//! // build.zig
//! // ...
//!     const exe = b.addExecutable("name_of_executable", "src/main.zig");
//!     exe.addPackagePath("trace", "../../src/main.zig");
//! // ...
//! ```
//!
//! 5. And then import the package via `@import` and the name of the package (here `trace`):
//!
//! ```
//! const trace = @import("trace");
//! ```
//!
//! 6. See more details on how to install it via package in the `examples`
//! 7. The examples show  the usage in an executable but trace.zig can also be used for libraries
//!
//! ## How to use
//!
//! To enable tracing (otherwise it will fallback to no-ops) one must define a public boolean constant
//! in its `root` file:
//!
//! ```
//! pub const enable_trace = true;
//! ```
//!
//! The examples assumes that you have cloned this repository into the path `../third_party/` relative to a `src` folder.
//! trace.zig can also be used as a package, the basic steps are described in the `README.md` of the repository.
//!
//! ### Span
//!
//! A time span can be open and closed inside a function:
//!
//! ```
//! const trace = @import("./third_party/trace.zig/src/main.zig");
//! const Span = trace.Span;
//!
//! pub const enable_trace = true; // must be enabled otherwise traces will be no-ops
//!
//! fn myFunc() void {
//!     const span = Span.open("A unique identifier");
//!     defer span.close(); // Span is closed automatically when the function returns
//!
//!     // execute the logic of myFunc
//!     // ...
//!
//!     // as mentioned above, span is closed here.
//! }
//! ```
//!
//! When:
//!
//! 1. trace is enabled (i.e. `pub const enable_trace=true`), and
//! 2. the the default writer is used, and
//! 3. `myFunc` is called,
//!
//! then something like the below output will be logged with `std.log`:
//!
//! ```shell
//! info: ;tp;2215696614260;0;A unique identifier;9887
//! info: ;tp;2215696653476;1;A unique identifier;9887
//! ```
//!
//! ## instrument
//!
//! Some categories of functions can be instrumented and used as shown below:
//!
//! ```
//! const trace = @import("./third_party/trace.zig/src/main.zig");
//! const instrument = trace.Instrument;
//!
//! fn myAdd(a: u64, b:u64) u64 {
//!     return a+b;
//! }
//! const instrumentedAdd = instrumentAdd(myAdd, "myAdd");
//! //                                            ^^^^^
//! // A unique identifier is required again. The function name can be used,
//! // but should be unique regarding the overall usage of identifiers.
//!
//! fn anotherFunction() void {
//!     // The instrumented function is called slightly different than the original function.
//!     // instrument maps the given function to a new function with its arguments turned
//!     // into an argument tuple.
//!     const value = instrumentedAdd(.{5, 6});
//!     _ = value;
//! }
//! ```
//!
//! When:
//!
//! 1. trace is enabled (i.e. `pub const enable_trace=true`), and
//! 2. the the default writer is used, and
//! 3. `anotherFunction` is called,
//!
//! then something like the below output will be logged with `std.log`:
//!
//! ```shell
//! info: ;tp;2215696614260;0;myAdd;6588
//! info: ;tp;2215696653476;1;myAdd;6588
//! ```
//!
//! ## On unique identifiers
//!
//! Currently the caller of `Span.open` or `instrument` must provide an identifier,
//! more specifically an `[] const u8` slice. This identifier needs to be unique
//! otherwise different spans (i.e. used at different source code locations) or
//! different instrumented functions cannot be differentiated in the output of the writer.
//! When analyzing the output (this is `std.log` for the default writer) such spans or
//! instrumented functions appear with the same id, making it impossible to trace the origin of
//! the span or the actually called function.
//!
//! Consider the following log output, created by two spans with the identifier "my span".
//!
//! ```shell
//! info: ;tp;2215696614260;0;my span;7853
//! info: ;tp;2215707778213;0;my span;7853
//! info: ;tp;2215770379010;1;my span;7583
//! info: ;tp;2215770407553;1;my span;7583
//! ```
//!
//! It is impossible to reconstruct from this output which span closes first: the one
//! that was opened first (with timestamp `2215696614260`) or the one that opened second
//! (with timestamp `2215770407553`).
//!
//! ## Writer
//!
//! When tracing is enabled (i.e. `enable_trace = true`) then trace.zig will log
//! (using `std.log`) so called trace points. This can be overriden if a function with the
//! following name and signature is implemented in the `root` file:
//!
//! ```
//! const TracePoint = @import(../third_party/trace.zig/src/trace_point.zig").TracePoint;
//!
//! pub inline fn writeTracePoint(trace_point: TracePoint) void {
//!     // custom implementation here
//! }
//! // inline is not strictly necessary.
//! ```
//!
//! ## Clock
//!
//! When tracing is enabled (i.e. `enable_trace = true`) then trace.zig requires a timestamp
//! as part of the trace point. A timestamp will help to analyze the trace logs and see
//! when spans (or trace events) have taken place during the execution of a program.
//! In the default behavior, trace.zig uses `std.time.Instant` to get a timestamp from the underlying
//! OS (in nanoseconds). This behavior can also be override, when the following name and signature is implemented in
//! the `root` file:
//!
//! ```
//! pub inline tracePointTimestamp() u64 {
//!     var timestamp: u64 = 0;
//!     // custom implementation
//!     return timestamp; }
//! ```
//!
//! In this way an own timestamp implementation can be provided.
//! However, ideally:
//!
//! 1. The timestamp is monotonic (which is currently not the case in the default implementation)
//! 2. The resolution of the timestamp is known (which simplifies the comparison to other traces or events etc.)
//!
//! ## Context
//!
//! When tracing is enabled (i.e. `enable_trace = true`) then trace.zig will
//! will require a context id (There is a default implementation which uses
//! `std.Thread.getCurrentId` to get the current context id). This context id
//! is necessary for multi-threading environments where a span is opened or
//! closed in multiple threads concurrently. In these cases it would otherwise
//! hard to know which trace point was created in which thread "context".
//! However as usual, this function can be overridden, which may be useful
//! for single threaded applications or freestanding target. If this is
//! necessary a function with the following name and signature need to be
//! implemented in the `root` file:
//!
//! ```
//! pub inline fn getTraceContext() u64 {
//!     var id = 0;
//!     // custom implementation here
//!     return id;
//! }
//! // inline is not strictly necessary.
//! ```
//!
//! ## Freestanding
//!
//! If the writer and the clock behavior is overriden with implementations
//! that don't use libc functionality, then it should be possible
//! to use trace.zig in freestanding environments (e.g. embedded systems).
//!
//! ## Limitations
//!
//! ### Overhead
//!
//! I believe that logging every span open and span close may result in a non-negligible overhead.
//! This must be further analyzed (see [GitLab issue #1](https://gitlab.com/zig_tracing/trace.zig/-/issues/1)) and
//! then the default writer is improved. In the meantime the writer can be overridden (i.e. implementing
//! `writeTracePoint` in the `root` file).
//!
//! ### Async functions
//!
//! Although context and context ids solve the multi-threading problem, I
//! believe that the context cannot be relied on in an async environment.
//! My line of thinking is, that an async function, when can be executed
//! by multiple threads until it is completed. This means each trace point
//! created during the execution could be with a different context id, which
//! makes it close to impossible to analyze. A solution for async needs to be
//! found, see
//! [GitLab issue #18](https://gitlab.com/zig_tracing/trace.zig/-/issues/18).

/// The Span namespace.
pub const Span = @import("span.zig");

/// The instrument function.
pub const instrument = @import("instrument.zig").instrument;

test {
    @import("std").testing.refAllDecls(@This());
}
