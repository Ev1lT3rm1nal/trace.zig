# Less but also more supported functions for trace.zig 0.2.0

[trace.zig](https://gitlab.com/zig_tracing/trace.zig) is a small and simple tracing client library for Zig. It aims to fill the gap until `std` provides a better and more sophisticated implementation. It is also a learning Zig project for myself. You can find the basic usage and concepts of trace.zig in the 0.1.0 announcement article [here](https://zig.news/huntrss/tracezig-a-small-and-simple-tracing-client-library-2ffj).

Due to very helpful comments for [Daurnimator](https://gitlab.com/daurnimator) I changed the implementation of the `instrument` function. `instrument` takes a given function and wraps it in a `span` (which is a time span that can be used to identify how long a specific source code part took to execute). The basic idea behind the implementation is as follows:

```Zig
pub fn instrument(comptime Function: fn(a:u8,b:u8) u8, id: [] const u8) (fn(a:u8,b:u8) u8) {
  const Wrapper = struct {
    fn wrapped(a:u8,b:u8) u8 {
      const span = Span.open(id);
      defer span.close();
      return f(a,b);
    }
  };
  return Wrapper.wrapped;
}
```

You may already see the limitation of this approach. It can only support functions of type `fn(a:u8,b:u8) u8`. In trace.zig 0.1.0 I overcame some of this limitation by defining so called function argument patterns. This means patterns of function arguments that the instrument code identified and specifically supported (or aborted with `@compileError`). This was done by using `@typeInfo(@TypeOf(Function))` and analyzing the returned `std.builtin.Type.Fn`. However the number of arguments was limited (only up to 4) but the first argument was allowed to be of type `type` while the last could be `anytype`. Another advantage was, that it did not change the function interface of the instrumented function.
It still felt awkward, limiting and I didn't like the implementation too much.

That's where [Daurnimator](https://gitlab.com/daurnimator)'s comments helped a lot: Using `@call` together with `std.meta.ArgsTuple` did lift the limitation of the supported number of arguments. The solution used in 0.1.0 could not somehow "iterate" the argument types of the given function to re-define its API in the form of the `wrapped` function. This is solved with the usage of `@call` and `std.meta.ArgsTuple`. The implementation of `instrument` in 0.2.0 is shown below:

```zig
pub inline fn instrument(comptime Function: anytype, id: []const u8) fn (args: functionArgumentsTuple(Function)) callconv(functionCallingConvention(Function)) functionReturnType(Function) {
    const Wrapper = struct {
        fn wrapped(args: functionArgumentsTuple(Function)) callconv(@typeInfo(@TypeOf(Function)).Fn.calling_convention) @typeInfo(@TypeOf(Function)).Fn.return_type.? {
            const span = Span.open(id);
            defer span.close();
            return @call(.{}, Function, args);
        }
    };

    return Wrapper.wrapped;
}
```

I omitted the implementations of the functions `functionArgumentsTuple`, `functionCallingConvention`, `functionReturnType` which basically are created to make the interface of `instrument` (hopefully) more readable. Additionally `@compileError`s are raised before calling functions in `std`, for example `std.meta.ArgsTuple`. The idea is, that the `@compileError`s are raised in `instrument.zig` with an error message indicating a problem with instrumenting a given function.

This means that `instrument` now does support an arbitrary number of arguments which basically means more functions as before. However the new implementation comes with a few limitations as well and it ends up supporting also less functions as before.

The limitations are:

1. Only non-generic functions are supported. Before it was possible to have at least the first argument of type `type`.
2. Functions with variadic arguments are not supported. Before the last argument could be of type `anytype`.
3. `std.builtin.Type.Fn.return_type` cannot be `null`.
4. Functions with C calling convention is not supported anymore.

Limitations 1 and 2 are due to `@compileError`s raised by `std.meta.ArgsTuple`. From my understanding there is no possibility to define a `std.meta.ArgsTuple` if some arguments are either generic of the function has variadic arguments. Limitation of 3 is due to the fact, that I don't know how to define a function with no return type. As far as I understand the following comment in `std.builtin` this issue may solve itself with future versions of Zig:

```zig
// Find this in Zig 0.10.0 standard library, builtin.zig line 371
// 
pub const Fn = struct {
  // ... omitted for brevity reasons
  /// TODO change the language spec to make this not optional.
  return_type: ?type,
  // ... omitted for brevity reasons
```

You can find this comment in github [here](https://github.com/ziglang/zig/blob/0.10.0/lib/std/builtin.zig#L371).

The last limitation comes from the fact that instrument changes the interface of the given function by using `std.meta.ArgsTuple`. Assume you have an `add` function defined as below:

```zig
fn add(a:u8,b:u8) callconv(.C) u8 {
  return a+b;
}

const instrumentedAdd = instrument(add,"add C function");
```

The above code does not compile with the following error (Zig 0.10):

```shell
# ...
error: parameter of type 'tuple{u8, u8}' not allowed in function with calling convention 'C'
# ...
note: only extern structs and ABI sized packed structs are extern compatible
```

The interface of the `add` function is changed, its arguments are now the tuple `{u8, u8}`. This is not supported with functions with C calling convention (issue already created [Add instrument function for functions with C calling convention](https://gitlab.com/zig_tracing/trace.zig/-/issues/17)). The change of the interface of the given functions is also the biggest drawback of the new `instrument` implementation. For example, in 0.1.0 the instrumented `add` function could be called identical, e.g. `instrumentedAdd(5,6)`. Now it must be called by creating a tuple, e.g. `instrumentedAdd(.{5,6})`. I don't like that this is the case but I think it is better in the long run. Especially since it is only a convenience function. Using `span`s directly is still possible regardless of the function arguments and calling convention.

You can find the tagged version in the [gitlab repository](https://gitlab.com/zig_tracing/trace.zig). Special thanks to [Daurnimator](https://gitlab.com/daurnimator) for providing the input. Checkout [CONTRIBUTING.md](https://gitlab.com/zig_tracing/trace.zig/-/blob/main/CONTRIBUTING.md) if you want to contribute to this project. Let me know if I have made some mistakes in my article. I would also like to know what you think about `instrument`. If it is something you find useful, or not.

Thank you for reading.
