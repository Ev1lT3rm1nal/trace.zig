const std = @import("std");
const Span = @import("span.zig");

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

/// Specifies the function argument patterns that are supported by instrument.
const FunctionArgumentPattern = enum {
    /// All parameters are "vanilla", e.g. fn vanilla(a:u8,b:u16) void {}
    vanilla,
    /// A type is the first argument, e.g. fn typeFirst(comptime T: type, a:u8) void {}
    type_is_first_argument,
    /// anytype is the last argument, e.g. fn format(fmt: [] const u8, args: anytype) void {}
    anytype_is_last_argument,
    /// A type is the first argument, the last argument is anytype the last, e.g. fn typeFirstAnytypeLast(comptime T: type, args: anytype) void {}
    type_is_first_anytype_last,
};

const FunctionArguments = struct {
    calling_convention: std.builtin.CallingConvention,
    arguments: []const std.builtin.Type.Fn.Param,
    return_type: type,
    argument_pattern: FunctionArgumentPattern,
    number_of_arguments: usize,
};

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
        .type_is_first_anytype_last
    else
        .vanilla;

    return pattern;
}

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
        .type_is_first_anytype_last => {
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
        .type_is_first_anytype_last => {
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
