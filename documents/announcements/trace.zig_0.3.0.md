# Multi-thread awareness for default writer in trace.zig 0.3.0

[trace.zig](https://gitlab.com/zig_tracing/trace.zig) is a small and simple
tracing client library for Zig. It aims to fill the gap until `std` provides a
better and more sophisticated implementation. It is also a learning Zig project
for myself. You can find the basic usage and concepts of trace.zig in the 0.1.0
announcement article
[here](https://zig.news/huntrss/tracezig-a-small-and-simple-tracing-client-library-2ffj).

I recently released version 0.3.0 of this library that tackled the issue No. 5
[Consider multi-threading for default writer](https://gitlab.com/zig_tracing/trace.zig/-/issues/5).

The default writer, writes the trace points to `std.log.info` but it did not
consider or was aware of multi-threading.

## The problem

Imagine you have some application that handles requests (maybe a simple
server) as they come and go by using one thread per request. Some requests
take longer to process, some shorter. Some requests are processed in parallel.
All of them are processed by the same function. Assume you're using `trace.zig`
to trace your application. You may have collected a trace as shown below:

```bash
info: ;tp;5406903957614;0;processRequest # this is a span open
info: ;tp;5406929313234;0;processRequest # this is a span open
info: ;tp;5406954247671;1;processRequest # this is a span close
info: ;tp;5406979588282;1;processRequest # this is a span close
```

This means two requests are processed in parallel. What is not clear from this
trace is, which request is finished first, which one is finished last. Also it
is not clear if the first request (the one with timestamp 5406903957614) is
the one that finishes before the second. This means one of the two
situations may have occurred:

* Request 1 takes longer than request 2:

  ![Request 1 takes longer than request 2](./Request1_longer.drawio.png "Request 1 takes longer than request 2")

* Request 1 finishes first:

  ![Request 1 finishes first](./Request1_finishes_first.drawio.png "Request 1 finishes first")

It is impossible to know what is the situation out of the trace points that
were logged. The data contained in a logged trace point is not enough for
such situations.

## The solution

In 0.3.0 I introduced the concept of "context". A "context" in the context of
trace.zig (pun intended) can be understood as an execution context of a
function. I primarily think of threads at the moment, this means a particular
thread that executes a function. However, in order to keep it simple, trace.zig
does only consider context with an identifier, more precisely an `u64`. See
below how `TracePoint` now also requires a `context_id`:

```zig
// context.zig
pub const TracePoint = struct {
    id: []const u8,
    timestamp: u64,
    trace_type: TraceType,
    // this field is new
    context_id: u64
}
```

If a `span` is open or closed, `getContextId` is called to get the `context_id`
to create the `TracePoint`. The default implementation uses
`std.Thread.getCurrentId`. As usual in trace.zig it is possible to override
the default implementation. This may help in set-ups which are not multi-
threading or freestanding targets like embedded systems, see the source code
sample of `context.zig` below:

```zig
// context.zig
pub inline fn getContextId() u64 {
    if (@hasDecl(root, "getTraceContextId")) {
        return root.getTraceContextId();
    } else {
        return getDefaultContextId();
    }
}

inline fn getDefaultContextId() u64 {
    return std.Thread.getCurrentId();
}
```

But how does this solve the aforementioned problem? If we run the program from
above another time, but this time with the updated trace.zig library, we get
a trace like below:

```shell
info: ;tp;10813966523729;0;processRequest;16161 # this is a span open
info: ;tp;10813991640338;0;processRequest;16162 # this is a span open
info: ;tp;10814016747457;1;processRequest;16161 # this is a span close
info: ;tp;10814041897272;1;processRequest;16162 # this is a span close
```

With this additional information (the context id, resp. thread id) we can see
that the first request does also finish first.

## Async functions

Although context and context ids solve the multi-threading problem, I believe
that the context cannot be relied on in an async environment. My line of
thinking is, that an async function, when can be executed by multiple threads
until it is completed. This means each trace point created during the
execution could be with a different context id, which makes it close to
impossible to analyze. A solution for async needs to be found, see
[GitLab issue #18](https://gitlab.com/zig_tracing/trace.zig/-/issues/18).

## Closing

You can find the tagged version in the
[gitlab repository](https://gitlab.com/zig_tracing/trace.zig). Checkout
[CONTRIBUTING.md](https://gitlab.com/zig_tracing/trace.zig/-/blob/main/CONTRIBUTING.md)
if you want to contribute to this project. Let me know if I have made some
mistakes in my article.

Thank you for reading.
