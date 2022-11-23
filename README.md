# trace.zig

Small and simple tracing library for the Zig programming language.

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

* And then import the package via `@import` and the name of the package:

```zig
const trace = @import("trace");
```

* See more details on how to install it via package in the `examples`
* The examples show  the usage in an executable but trace.zig can also be used for libraries

## How to use

Check the generated documentation **here** to see how this library can be used.

## License

MIT, find the license file [here](./LICENSE).
