# Announcing trace-zig 0.1.0

trace.zig is a small an simple tracing client library for Zig. It aims to fill the gap until the std library will have its own tracing. It hopefully can inspire this future implementation or help avoiding the mistakes trace.zig may have done ;).

## Where to find it?

trace.zig is hosted in the [trace.zig](https://gitlab.com/zig_tracing/trace.zig) repository on GitLab. As usual the [README.md](https://gitlab.com/zig_tracing/trace.zig/-/blob/main/README.md) is good starting point to learn more. The documentation is inside the source code files as doc comments. Especially [main.zig](https://gitlab.com/zig_tracing/trace.zig/-/blob/main/src/main.zig) contains useful information. The plan is to host the document as GitLab pages. Example usages can be found in the [examples](https://gitlab.com/zig_tracing/trace.zig/-/tree/main/examples) folder.

## How to use it?

trace.zig requires the Zig compiler in version 0.10.0. If you clone/copy the repository locally you can import `main.zig` into your source code files as usual:

```Zig
const trace = @import("<path to the repository>/src/main.zig");
```

Or you define it as a package in your `build.zig`:

```Zig
// build.zig
// ...
    const exe = b.addExecutable("name_of_executable", "src/main.zig");
    exe.addPackagePath("trace", "../../src/main.zig");
// ...
```

And then import it as package like this:

```Zig
const trace = @import("trace");
```

trace.zig currently supports creating spans or instrumenting functions. trace.zig needs to be enabled by defining a public boolean constant in your `root` file otherwise it will fallback to no-ops. Here is what you need to define:

```Zig
pub const enable_trace = true;
```

The examples assumes that you have cloned this repository into the path `../third_party/` relative to a `src` folder.

### Spans

A time span can be open and closed inside a function:

```Zig
const trace = @import("./third_party/trace.zig/src/main.zig");
const Span = trace.Span;

pub const enable_trace = true; // must be enabled otherwise traces will be no-ops

fn myFunc() void {
    const span = Span.open("A unique identifier");
    defer span.close(); // Span is closed automatically when the function returns

    // execute the logic of myFunc
    // ...

    // as mentioned above, span is closed here.
}
```

When:

1. trace is enabled (i.e. `pub const enable_trace=true`), and
2. the the default writer is used, and
3. `myFunc` is called,

then something like the below output will be logged with `std.log`:

```shell
info: ;tp;2215696614260;0;A unique identifier
info: ;tp;2215696653476;1;A unique identifier
```

### instrument

Some functions can be instrumented and used as shown below:

```Zig
const trace = @import("./third_party/trace.zig/src/main.zig");
const instrument = trace.Instrument;

fn myAdd(a: u64, b:u64) u64 {
    return a+b;
}
const instrumentedAdd = instrumentAdd(myAdd, "myAdd");
//                                            ^^^^^
// A unique identifier is required again. The function name can be used,
// but should be unique regarding the overall usage of identifiers.

fn anotherFunction() void {
    // The instrumented function can be called as the original function.
    const value = instrumentedAdd(5,6);
    _ = value;
}
```

When:

1. trace is enabled (i.e. `pub const enable_trace=true`), and
2. the the default writer is used, and
3. `anotherFunction` is called,

then something like the below output will be logged with `std.log`:

```shell
info: ;tp;2215696614260;0;myAdd
info: ;tp;2215696653476;1;myAdd
```

Unfortunately one cannot instrument every possible functions. The main reason is my lack of knowledge of Zig: I couldn't find a way to create a function by "looping" through the argument types of given function. You can instrument "simple" function with zero up to three arguments. With "simple" I mean using primitive types or structs as arguments. Some usages of generic arguments (more specific `anytype`) or `comptime` arguments are supported. For more information see the documentation of the `instrument` function in [instrument.zig](https://gitlab.com/zig_tracing/trace.zig/-/blob/main/src/instrument.zig#L153).
Instrumenting a non-supported function will result in a compile error with a hopefully useful compile error message. If you cannot instrument your function you can always use a span directly as described above.

## Contributions

Are very welcome and more detailed in [CONTRIBUTING.md](https://gitlab.com/zig_tracing/trace.zig/-/blob/main/CONTRIBUTING.md) but it boils down to the following contribution ideas:

* Use it, provide feedback, create issues (bugs and improvements)
* Fix issues (I already created more than a dozen)
* Create custom writers or clocks: You can override the behavior how tracing information is "written" (e.g. logged with `std.log`) or how a timestamp is provided (which is very relevant for freestanding and/or embedded systems)
* Create utilities to analyze log output, e.g. visualizations of spans etc..

## Limitations

### Thread safety

I believe that currently using an individual span inside a source code section which is called from more than on threads will lead to inconclusive spans. This means that one cannot identify from within which thread a span was opened and closed. There is already the [GitLab issue #5](https://gitlab.com/zig_tracing/trace.zig/-/issues/5) to address this limitation in the future.

### Overhead

I believe that logging every span open and span close may result in a non-negligible overhead. This must be further analyzed (see [GitHub issue #1](https://gitlab.com/zig_tracing/trace.zig/-/issues/1)) and then the default writer is improved. In the meantime the writer can be overridden (i.e. implementing `writeTracePoint` in the `root` file).
