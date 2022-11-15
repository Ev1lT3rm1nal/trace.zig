const std = @import("std");
const Span = @import("span.zig");

pub inline fn instrument(comptime f: anytype, id: []const u8) @TypeOf(f) {
    const function_type = @typeInfo(@TypeOf(f)).Fn;
    const return_type = function_type.return_type;
    if (return_type == null) {
        @compileError("Null return type is not supported");
    }
    const args = function_type.args;
    const wrappedFunction = switch (args.len) {
        0 => instrument0Args(f, id, function_type),
        1 => instrument1Arg(f, id, function_type, args),
        else => @compileError("Only up to 1 argument allowed. Use anytype or combined arguments in structs"),
    };
    return wrappedFunction;
}

inline fn instrument0Args(comptime f: anytype, id: []const u8, comptime function_type: std.builtin.Type.Fn) @TypeOf(f) {
    const calling_convention = function_type.calling_convention;
    const Wrapper = struct {
        fn wrapped() callconv(calling_convention) function_type.return_type.? {
            const span = Span.open(id);
            defer span.close();
            return f();
        }
    };
    return Wrapper.wrapped;
}

inline fn instrument1Arg(comptime f: anytype, id: []const u8, comptime function_type: std.builtin.Type.Fn, comptime args: []const std.builtin.Type.Fn.Param) @TypeOf(f) {
    const calling_convention = function_type.calling_convention;
    const arg = args[0];
    if (arg.is_generic) {
        const Wrapper = struct {
            fn wrapped(p1: anytype) callconv(calling_convention) function_type.return_type.? {
                const span = Span.open(id);
                defer span.close();
                return f(p1);
            }
        };
        return Wrapper.wrapped;
    } else {
        const arg_type = arg.arg_type.?;
        const arg_type_info = @typeInfo(arg_type);
        if (arg_type_info == .Type) {
            const Wrapper = struct {
                fn wrapped(comptime p1: arg_type) callconv(calling_convention) function_type.return_type.? {
                    const span = Span.open(id);
                    defer span.close();
                    return f(p1);
                }
            };
            return Wrapper.wrapped;
        } else {
            const Wrapper = struct {
                fn wrapped(p1: arg_type) callconv(calling_convention) function_type.return_type.? {
                    const span = Span.open(id);
                    defer span.close();
                    return f(p1);
                }
            };
            return Wrapper.wrapped;
        }
    }
}
