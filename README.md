# trace.zig

Small and simple tracing library for the Zig programming language.

## Motivation

I created this library because as of writing (end of 2022) Zig currently lacks a tracing library in `std` and trace.zig can bridge the gap. Additionally it enabled me to learn (some) Zig with a project that motivates me. Finally, the type system of Zig and its usage of generics enables to implement features like `instrument` which interested me.

## Features

* Opening and closing spans to define time spans of execution
* Instrumented a limited set of functions: This creates a span around the function automatically
* Disabled by default which should result in no-ops
* Default logs with `std.log` but this behavior can be overridden
* Uses the time provided by `std`, but this can also be overridden

## How to install

* Requires Zig compiler version 0.10.0
* Clone / copy repository locally
* Either import `main.zig` into your project:

```Zig
const trace = @import("<path to the repository>/src/main.zig");
```

* Or define it as a package in your `build.zig`:

```zig
// build.zig
// ...
    const exe = b.addExecutable("name_of_executable", "src/main.zig");
    exe.addPackagePath("trace", "../../src/main.zig");
// ...
```

* And then import the package via `@import` and the name of the package (here `trace`):

```zig
const trace = @import("trace");
```

* See more details on how to install it via package in the `examples`
* The examples show  the usage in an executable but trace.zig can also be used for libraries

## How to use

See some basic usages below. Further usages can be found inside the source code as doc comments and the to be added generated documentation.

To enable tracing (otherwise it will fallback to no-ops) one must define a public boolean constant in its `root` file:

```Zig
pub const enable_trace = true;
```

The examples assumes that you have cloned this repository into the path `../third_party/` relative to a `src` folder.
trace.zig can also be used as a package, the basic steps are described in the `README.md` of the repository.

### Span

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

## instrument

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

## License

MIT, find the license file [here](./LICENSE).