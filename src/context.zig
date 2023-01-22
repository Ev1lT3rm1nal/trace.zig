//! The namespace containng the functions needed to get the context id for
//! a tracepoint.
//!
//! The default context id, is the thread id of the thread in which the
//! current trace point is created.
//!
//! A context is needed to differentiate different trace points that have
//! the same id, but are executed in different contexts. The best example is
//! a span inside a function that is executed in parallel or concurrently.
//!
//! The current default realization does work for multi threaded environments
//! but not for async functions. An individual async function may be executed
//! by several threads and may therefore result in a different context id for
//! the trace points created during a single execution of the function.

const std = @import("std");
const root = @import("root");

/// Function that returns the context id of the current execution context.
pub inline fn getContextId() u64 {
    if (@hasDecl(root, "getTraceContextId")) {
        return root.getTraceContextId();
    } else {
        return getDefaultContextId();
    }
}

/// Default implementation that does return the current thread id.
inline fn getDefaultContextId() u64 {
    return std.Thread.getCurrentId();
}

test "getDefaultContextId uses current thread Id" {
    // Arrange
    // Act
    const contextId = getContextId();
    // Assert
    const expectEqual = std.testing.expectEqual;
    const threadId = std.Thread.getCurrentId();
    try expectEqual(threadId, contextId);
}
