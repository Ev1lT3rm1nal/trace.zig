//! Namespace that contains the `instrument` function.

const std = @import("std");
const Span = @import("span.zig");

/// Instrument enables to instrument a function (if it is supported).
///
/// An instrumented function is "wrapped" with a Span. This means upon
/// calling this function a span is opened before the actual call closed
/// when the function returns.
///
/// Emits a compile error if an unsupported function is instrumented.
///
/// ## Example usage
///
/// The examples assumes that you have cloned this repository into the path `./third_party/`.
/// trace.zig can also be used as a package, the basic steps are described in the `README.md` of the repository.
///
/// ### Instrumenting a supported function
///
/// ```
/// const trace = @import("./third_party/trace.zig/src/main.zig");
/// const instrument = trace.Instrument;
///
/// fn myAdd(a: u64, b:u64) u64 {
///     return a+b;
/// }
/// const instrumentedAdd = instrumentAdd(myAdd, "myAdd");
/// //                                            ^^^^^
/// // A unique identifier is required again. The function name can be used,
/// // but should be unique.
///
/// fn anotherFunction() void {
///     // The instrumented function can be called as the original function.
///     const value = instrumentedAdd(5,6);
///     _ = value;
/// }
/// ```
///
/// ### Usage in member functions of structs
///
/// ```
/// const Point = struct {
///     x: u32,
///     y: u32,
///     const Self = Point;
///     fn innerDotProduct(self: Point, other: Point) u32 {
///         return self.x * other.x + self.y * other.y;
///     }
///     // the instrumented method.
///     const dotProduct = instrument(innerDotProduct, "Point.dotProduct");
/// };
///
/// test "Struct method" {
///     const point_1 = Point{
///         .x = 5,
///         .y = 6,
///     };
///     const point_2 = Point{
///         .x = 6,
///         .y = 5,
///     };
///     // The instrumented function can be called with the "." syntax as
///     // usual.
///     const dot = point_1.dotProduct(point_2);
///     try @import("std").testing.expect(60 == dot);
/// }
/// ```
///
/// ## Supported functions
///
/// The following rules define which type of function (or more specific function arguments)
/// are supported:
///
/// 1. From zero up to three arguments supported.
/// 2. Arguments can be vanilla arguments, i.e. without specific identifiers like `comptime` (e.g. `u8`).
/// 3. The first argument can be of type `type`, i.e. it requires the `comptime` qualifier.
/// 4. The last argument can be of type `anytype`.
/// 5. The return type is not null. This should be solvable in the future
///    if I understand this comment correctly:
///    [`std.builtin`](https://github.com/ziglang/zig/blob/5b9d0a446af4e74c9f915a34b39de83d9b2335f9/lib/std/builtin.zig#L371-L372).
/// 6. A combination of the above.
///
/// ### Examples
///
/// 1. A function with three "vanilla" arguments is supported:
///
/// ```
/// fn func(a:u8,b:i16,c:u128) void {
///     _ = a;
///     _ = b;
///     _ = c;
/// }
/// ```
///
/// 2. A function with a `type` as first argument, a "vanilla" as second and an `anytype` as last
///
/// ```
/// fn func2(comptime T:type, b:u8, c: anytype) void {
///     _ = T;
///     _ = b;
///     _ = c;
/// }
/// ```
///
/// ### Explanations
///
/// These limitations occur from the fact, that:
///
/// 1. I've not found a generic way to iterate over the number of arguments.
///    This means I switch case over the number of arguments.
/// 2. I cannot extract the information if a parameter requires `comptime` from
///    `std.builtin.Type` other than the inherent knowledge that arguments of type
///    `type`require `comptime`
/// 3. Although if an argument is generic can be extracted (via
///    `std.builtin.Type.Fn.Param`) I am not sure if a generic type
///    can be replaced with `anytype` or how to extract the type of a generic type.
///    Using anytype as the last argument seemed like a reasonable pattern to support.
///    Also if I support multiple generics I need to define more patterns due to reason 1.
/// 4. Patterns seemed like a reasonable solution that would simplify the implementation (I can
///    switch over the analyzed pattern as opposed to an if-else hell).
/// 5. I have no idea how to define a return type that is null.
///
/// ## Some examples of unsupported functions
///
/// 1. Return type is null
///
/// ```
/// fn pow2(comptime T: type, x: T) @TypeOf(x) {
///     return x * x;
/// }
/// ```
///
/// 2. Currently not supported since it is not clear how to identify an argument is `comptime`
///
/// ```
/// fn debugPrintTypeName(comptime x: anytype) void {
///     const std = @import("std");
///     const type_name = @typeName(@TypeOf(x));
///     std.debug.print("Type name: {}", .{type_name});
/// }
/// ```
///
/// 3. Two (or more) anytype arguments
///
/// ```
/// fn add(a: anytype, b:anytype) void {
///     const c = a + b;
///     _ = c;
/// }
/// ```
///
pub inline fn instrument(comptime f: anytype, id: []const u8) @TypeOf(f) {
    const function_arguments = validateFunction(f);

    const wrapped_function = switch (function_arguments.number_of_arguments) {
        0 => instrument0Args(f, function_arguments, id),
        1 => instrument1Arg(f, function_arguments, id),
        2 => instrument2Arg(f, function_arguments, id),
        3 => instrument3Arg(f, function_arguments, id),
        else => @compileError("Only up to 3 function argument is supported"),
    };

    return wrapped_function;
}

pub inline fn instrument2(comptime Function: anytype, id: []const u8) fn (args: functionArgumentsTuple(Function)) callconv(functionCallingConvention(Function)) functionReturnType(Function) {
    const Wrapper = struct {
        fn wrapped(args: functionArgumentsTuple(Function)) callconv(@typeInfo(@TypeOf(Function)).Fn.calling_convention) @typeInfo(@TypeOf(Function)).Fn.return_type.? {
            const span = Span.open(id);
            defer span.close();
            return @call(.{}, Function, args);
        }
    };

    return Wrapper.wrapped;
}

test "Instrument Struct method" {
    const Point = struct {
        x: u32,
        y: u32,
        const Self = @This();
        fn innerDotProduct(self: Self, other: Self) u32 {
            return self.x * other.x + self.y * other.y;
        }
        const dotProduct = instrument2(innerDotProduct, "Point.dotProduct");
    };

    const point_1 = Point{
        .x = 5,
        .y = 6,
    };
    const point_2 = Point{
        .x = 6,
        .y = 5,
    };
    const dot = Point.dotProduct(.{ point_1, point_2 });
    try @import("std").testing.expect(60 == dot);
}

test "Test instrument with multiple parameter function" {
    const TestNamespace = struct {
        fn mulFive(a: u64, b: u64, c: u64, d: u64, e: u64) u64 {
            return a * b * c * d * e;
        }
    };

    const instrMulFive = instrument2(TestNamespace.mulFive, "MulFive");
    try std.testing.expect(120 == instrMulFive(.{ 1, 2, 3, 4, 5 }));
}

/// Creates the function arguments tuple for the given function.
///
/// Is used to create compile errors with context on `instrument`.
/// In this way it should be easier to differentiate the compile errors emitted due to unsupported functions.
/// Otherwise the errors of `std.meta.ArgsTuple` would be emitted which may make fixing the compile error harder.
/// Additionally this should make the definition of `instrument` easier to read.
/// This function makes the same checks as `std.Meta.ArgsTuple` hence it has pretty similar source code.
inline fn functionArgumentsTuple(comptime Function: anytype) type {
    const info = @typeInfo(@TypeOf(Function));
    if (info != .Fn) {
        @compileError("Only functions can be instrumented");
    }

    const function_info = info.Fn;
    if (function_info.is_generic) {
        @compileError("Instrumenting generic functions is not supported.");
    }
    if (function_info.is_var_args) {
        @compileError("Instrumenting variadic function is not supported.");
    }

    return std.meta.ArgsTuple(@TypeOf(Function));
}

/// Returns the calling convention of the given function.
///
/// This simplifies to read API for `instrument`.
inline fn functionCallingConvention(comptime Function: anytype) std.builtin.CallingConvention {
    const info = @typeInfo(@TypeOf(Function));
    if (info != .Fn) {
        @compileError("Only functions can be instrumented");
    }
    return info.Fn.calling_convention;
}

/// Returns the return type of the given function.
///
/// This simplifies to read API for `instrument`.
inline fn functionReturnType(comptime Function: anytype) type {
    const info = @typeInfo(@TypeOf(Function));
    if (info != .Fn) {
        @compileError("Only functions can be instrumented");
    }
    const return_type = info.Fn.return_type orelse @compileError("Null return type is not supported");
    return return_type;
}

/// Specifies the function argument patterns that are supported by instrument.
const FunctionArgumentPattern = enum {
    /// All parameters are "vanilla", e.g. fn vanilla(a:u8,b:u16) void {}
    vanilla,
    /// A type is the first argument, e.g. fn typeFirst(comptime T: type, a:u8) void {}
    type_is_first_argument,
    /// anytype is the last argument, e.g. fn format(fmt: [] const u8, args: anytype) void {}
    anytype_is_last_argument,
    /// A type is the first argument, the last argument is anytype the last, e.g. fn typeFirstAnytypeLast(comptime T: type, args: anytype) void {}
    type_is_first_anytype_is_last,
};

/// Struct used to validate and analyze a function according their arguments.
const FunctionArguments = struct {
    calling_convention: std.builtin.CallingConvention,
    arguments: []const std.builtin.Type.Fn.Param,
    return_type: type,
    argument_pattern: FunctionArgumentPattern,
    number_of_arguments: usize,
};

/// Validates a function to check if it is supported and the function argument
/// pattern the function realizes.
fn validateFunction(comptime f: anytype) FunctionArguments {
    const function_type_info = @typeInfo(@TypeOf(f)).Fn;
    const args = function_type_info.args;
    const number_of_arguments = args.len;
    const calling_convention = function_type_info.calling_convention;
    const return_type = function_type_info.return_type orelse {
        @compileError("Null return type is not supported");
    };

    const pattern = analyseForFunctionArgumentsPattern(args, number_of_arguments);

    const function_arguments = FunctionArguments{
        .calling_convention = calling_convention,
        .arguments = args,
        .return_type = return_type,
        .argument_pattern = pattern,
        .number_of_arguments = number_of_arguments,
    };
    return function_arguments;
}

/// Analyse the function argument pattern of the given function.
fn analyseForFunctionArgumentsPattern(comptime arguments: []const std.builtin.Type.Fn.Param, number_of_arguments: usize) FunctionArgumentPattern {
    var number_of_type_arguments = 0;
    var number_of_anytypes = 0;
    for (arguments) |arg| {
        if (arg.arg_type != null) {
            if (arg.arg_type.? == type) {
                number_of_type_arguments += 1;
            }
        }
        if (arg.is_generic) {
            number_of_anytypes += 1;
        }
    }

    var first_argument_is_of_type_type: bool = false;
    if (number_of_type_arguments > 1) {
        @compileError("Only one function argument of type \"type\" is supported.");
    } else if (number_of_type_arguments == 1) {
        if (arguments[0].arg_type == null) {
            @compileError("Only if the first argument is of type \"type\" is supported.");
        }
        if (arguments[0].arg_type.? == type) {
            first_argument_is_of_type_type = true;
        } else {
            @compileError("Only if the first argument is of type \"type\" is supported.");
        }
    }

    var last_argument_is_anytype: bool = false;
    if (number_of_anytypes > 1) {
        @compileError("Only one function argument of type \"anytype\" allowed.");
    } else if (number_of_anytypes == 1) {
        if (arguments[number_of_arguments - 1].is_generic) {
            last_argument_is_anytype = true;
        } else {
            @compileError("It is only supported, that the last argument is of type \"anytype\".");
        }
    }

    const pattern = if (first_argument_is_of_type_type and !last_argument_is_anytype)
        .type_is_first_argument
    else if (!first_argument_is_of_type_type and last_argument_is_anytype)
        .anytype_is_last_argument
    else if (first_argument_is_of_type_type and last_argument_is_anytype)
        .type_is_first_anytype_is_last
    else
        .vanilla;

    return pattern;
}

/// Instruments a function with no arguments.
inline fn instrument0Args(comptime f: anytype, comptime function_arguments: FunctionArguments, id: []const u8) @TypeOf(f) {
    const calling_convention = function_arguments.calling_convention;
    const Wrapper = struct {
        fn wrapped() callconv(calling_convention) function_arguments.return_type {
            const span = Span.open(id);
            defer span.close();
            return f();
        }
    };
    return Wrapper.wrapped;
}

/// Instruments a function with 1 argument.
inline fn instrument1Arg(comptime f: anytype, comptime function_arguments: FunctionArguments, id: []const u8) @TypeOf(f) {
    const calling_convention = function_arguments.calling_convention;
    const arg = function_arguments.arguments[0];
    switch (function_arguments.argument_pattern) {
        .vanilla => {
            const arg_type = arg.arg_type.?;
            const Wrapper = struct {
                fn wrapped(p1: arg_type) callconv(calling_convention) function_arguments.return_type {
                    const span = Span.open(id);
                    defer span.close();
                    return f(p1);
                }
            };
            return Wrapper.wrapped;
        },
        .type_is_first_argument => {
            const Wrapper = struct {
                fn wrapped(comptime p1: type) callconv(calling_convention) function_arguments.return_type {
                    const span = Span.open(id);
                    defer span.close();
                    return f(p1);
                }
            };
            return Wrapper.wrapped;
        },
        .anytype_is_last_argument => {
            const Wrapper = struct {
                fn wrapped(p1: anytype) callconv(calling_convention) function_arguments.return_type {
                    const span = Span.open(id);
                    defer span.close();
                    return f(p1);
                }
            };
            return Wrapper.wrapped;
        },
        else => @compileError("It is not supported that the first argument is of type \"type\" and of type \"anytype\"."),
    }
}

/// Instruments a function with 2 arguments.
inline fn instrument2Arg(comptime f: anytype, comptime function_arguments: FunctionArguments, id: []const u8) @TypeOf(f) {
    const calling_convention = function_arguments.calling_convention;
    const arg_1 = function_arguments.arguments[0];
    const arg_2 = function_arguments.arguments[1];
    switch (function_arguments.argument_pattern) {
        .vanilla => {
            const arg_1_type = arg_1.arg_type.?;
            const arg_2_type = arg_2.arg_type.?;
            const Wrapper = struct {
                fn wrapped(p1: arg_1_type, p2: arg_2_type) callconv(calling_convention) function_arguments.return_type {
                    const span = Span.open(id);
                    defer span.close();
                    return f(p1, p2);
                }
            };
            return Wrapper.wrapped;
        },
        .type_is_first_argument => {
            const Wrapper = struct {
                const arg_2_type = arg_2.arg_type.?;
                fn wrapped(comptime p1: type, p2: arg_2_type) callconv(calling_convention) function_arguments.return_type {
                    const span = Span.open(id);
                    defer span.close();
                    return f(p1, p2);
                }
            };
            return Wrapper.wrapped;
        },
        .anytype_is_last_argument => {
            const arg_1_type = arg_1.arg_type.?;
            const Wrapper = struct {
                fn wrapped(p1: arg_1_type, p2: anytype) callconv(calling_convention) function_arguments.return_type {
                    const span = Span.open(id);
                    defer span.close();
                    return f(p1, p2);
                }
            };
            return Wrapper.wrapped;
        },
        .type_is_first_anytype_is_last => {
            const Wrapper = struct {
                fn wrapped(comptime p1: type, p2: anytype) callconv(calling_convention) function_arguments.return_type {
                    const span = Span.open(id);
                    defer span.close();
                    return f(p1, p2);
                }
            };
            return Wrapper.wrapped;
        },
    }
}

/// Instruments a function with 3 arguments.
inline fn instrument3Arg(comptime f: anytype, comptime function_arguments: FunctionArguments, id: []const u8) @TypeOf(f) {
    const calling_convention = function_arguments.calling_convention;
    const arg_1 = function_arguments.arguments[0];
    const arg_2 = function_arguments.arguments[1];
    const arg_3 = function_arguments.arguments[2];
    switch (function_arguments.argument_pattern) {
        .vanilla => {
            const arg_1_type = arg_1.arg_type.?;
            const arg_2_type = arg_2.arg_type.?;
            const arg_3_type = arg_2.arg_type.?;
            const Wrapper = struct {
                fn wrapped(p1: arg_1_type, p2: arg_2_type, p3: arg_3_type) callconv(calling_convention) function_arguments.return_type {
                    const span = Span.open(id);
                    defer span.close();
                    return f(p1, p2, p3);
                }
            };
            return Wrapper.wrapped;
        },
        .type_is_first_argument => {
            const Wrapper = struct {
                const arg_2_type = arg_2.arg_type.?;
                const arg_3_type = arg_3.arg_type.?;
                fn wrapped(comptime p1: type, p2: arg_2_type, p3: arg_3_type) callconv(calling_convention) function_arguments.return_type {
                    const span = Span.open(id);
                    defer span.close();
                    return f(p1, p2, p3);
                }
            };
            return Wrapper.wrapped;
        },
        .anytype_is_last_argument => {
            const arg_1_type = arg_1.arg_type.?;
            const arg_2_type = arg_2.arg_type.?;
            const Wrapper = struct {
                fn wrapped(p1: arg_1_type, p2: arg_2_type, p3: anytype) callconv(calling_convention) function_arguments.return_type {
                    const span = Span.open(id);
                    defer span.close();
                    return f(p1, p2, p3);
                }
            };
            return Wrapper.wrapped;
        },
        .type_is_first_anytype_is_last => {
            const Wrapper = struct {
                const arg_2_type = arg_2.arg_type.?;
                fn wrapped(comptime p1: type, p2: arg_2_type, p3: anytype) callconv(calling_convention) function_arguments.return_type {
                    const span = Span.open(id);
                    defer span.close();
                    return f(p1, p2, p3);
                }
            };
            return Wrapper.wrapped;
        },
    }
}
