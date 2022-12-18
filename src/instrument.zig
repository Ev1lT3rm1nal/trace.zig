//! Namespace that contains the `instrument` function.

const std = @import("std");
const Span = @import("span.zig");

/// Instrument enables to instrument a function (if it is supported).
///
/// An instrumented function is "wrapped" with a Span. This means upon
/// calling this function a span is opened before the actual call and closed
/// when the function returns. `instrument` itselfs maps the given function into
/// a new function. During this mapping the given functions arguments are mapped
/// into a `std.meta.ArgsTuple`. See an abstract example of this mapping below:
///
/// instrument: fn (Arg1Type, Arg2Type, ..., ArgNType) ReturnType => fn (.{Arg1Type, Arg2Type, ..., ArgNType}) ReturnType
///
/// This means that an instrumented function is called slightly different than the given
/// function. See examples below.
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
///     const value = instrumentedAdd(.{5, 6});
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
///     const Self = @This();
///     fn innerDotProduct(self: Self, other: Self) u32 {
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
///     // Unfortunately the instrumented function cannot be called with the "." syntax as usual.
///     const dot = dotProduct(.{point_1, point_2});
///     try @import("std").testing.expect(60 == dot);
/// }
/// ```
///
/// ## Supported functions
///
/// Functions with an arbitrary number of arguments are supported. However these arguments must not be
/// generic, or `anytype`, etc.. See below for more information on unsupported functions.
///
/// ## Unsupported functions
///
/// The following categories of functions are not supported:
///
/// 1. Generic functions
/// 2. Function with variadic arguments
/// 3. Functions with variadic arguments
/// 4. Function with C calling convention are not supported
/// 5. The return type is not null. This should be solvable in the future
///    if I understand this comment correctly:
///    [`std.builtin`](https://github.com/ziglang/zig/blob/5b9d0a446af4e74c9f915a34b39de83d9b2335f9/lib/std/builtin.zig#L371-L372).
///
/// ### Some examples of unsupported functions
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
/// ## Explanations
///
/// These limitations occur from the facts, that:
///
/// 1. `std.meta.ArgsTuple` does not support generic functions or function with variadic arguments
/// 2. I cannot extract the information if a parameter requires `comptime` from
///    `std.builtin.Type` other than the inherent knowledge that arguments of type
///    `type`require `comptime`
/// 3. Although if an argument is generic can be extracted (via
///    `std.builtin.Type.Fn.Param`) I am not sure if a generic type
///    can be replaced with `anytype` or how to extract the type of a generic type.
/// 5. I have no idea how to define a return type that is null.
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

test "Instrument Struct method" {
    const Point = struct {
        x: u32,
        y: u32,
        const Self = @This();
        fn innerDotProduct(self: Self, other: Self) u32 {
            return self.x * other.x + self.y * other.y;
        }
        const dotProduct = instrument(innerDotProduct, "Point.dotProduct");
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

test "Instrument with multiple parameter function" {
    const TestNamespace = struct {
        inline fn mulFive(a: u64, b: u64, c: u64, d: u64, e: u64) u64 {
            return a * b * c * d * e;
        }
    };

    const instrMulFive = instrument(TestNamespace.mulFive, "MulFive");
    try std.testing.expect(120 == instrMulFive(.{ 1, 2, 3, 4, 5 }));
}

test "Instrument with 0 args and void return type" {
    // Arrange
    const TestStruct = struct {
        var value: u8 = 0;
        fn incrementValue() void {
            value += 1;
        }
    };
    const instrumentedIncrementValue = instrument(TestStruct.incrementValue, "incrementValue");

    // Act
    instrumentedIncrementValue(.{});

    // Assert
    try std.testing.expect(TestStruct.value == 1);
}

test "Instrument with 1 arg and u8 return type" {
    // Arrange
    const TestStruct = struct {
        fn pow2Inner(value: u8) u8 {
            return value * value;
        }
    };
    const pow2 = instrument(TestStruct.pow2Inner, "pow2");

    // Act
    const result = pow2(.{5});

    // Assert
    try std.testing.expect(25 == result);
}

test "Instrument with 2 arguments" {
    const TestNamespace = struct {
        fn addInner(x: u8, y: u8) u8 {
            return x + y;
        }
    };

    const add = instrument(TestNamespace.addInner, "add");
    try std.testing.expect(11 == add(.{ 5, 6 }));
}

test "C calling convention" {
    const TestNamespace = struct {
        fn cFunc(x: u8, y: u8) callconv(.C) u8 {
            return x * y;
        }
    };
    _ = TestNamespace;
    //const instrCFunct = instrument(TestNamespace.cFunc, "cFunc");
    //try std.testing.expectEqual(30, instrCFunct(.{ 5, 6 }));
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
