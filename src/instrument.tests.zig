const instrument = @import("instrument.zig").instrument;

fn zeroArgVoidFunction() void {
    const std = @import("std");
    std.debug.print("Zero arg void function called.", .{});
}

const instrumentedZeroArgVoidFunction = instrument(zeroArgVoidFunction, "zero arg void function");

test "Test instrument for void function with 0 Arguments" {
    const expect = @import("std").testing.expect;

    instrumentedZeroArgVoidFunction();
    try expect(true);
}

fn zeroArgU8Function() u8 {
    return 127;
}

const instrumentedZeroArgU8Function = instrument(zeroArgU8Function, "zero arg u8 function");

test "Test instrument for u8 function with 0 Arguments" {
    const expect = @import("std").testing.expect;

    const value = instrumentedZeroArgU8Function();
    try expect(value == 127);
}

inline fn inlinedZeroArgU8Function() u8 {
    return 111;
}

const instrumentedInlinedZeroArgU8Function = instrument(inlinedZeroArgU8Function, "zero arg u8 function");

test "Test instrument for inlined u8 function with 0 Arguments" {
    const expect = @import("std").testing.expect;

    const value = instrumentedInlinedZeroArgU8Function();
    try expect(value == 111);
}

fn cCallconvOneArgi32Function(arg1: i32) callconv(.C) i32 {
    return -12298 + arg1;
}

const instrumentedCCallConvOneArgi32Function = instrument(cCallconvOneArgi32Function, "cCallconvArgi32Function");

test "Test instrument for C call convention i32 function with 1 Argument" {
    const std = @import("std");
    const expect = std.testing.expect;

    const value = instrumentedCCallConvOneArgi32Function(8);
    try expect(value == -12290);
}

fn oneAnytpeArgU8Function(arg1: anytype) u8 {
    return arg1.a + arg1.b;
}

const instumentedOneAnytpeArgU8Function = instrument(oneAnytpeArgU8Function, "oneAnytpeArgU8Function");

test "Test instrument for u8 function with 1 anytype Argument" {
    const std = @import("std");
    const expect = std.testing.expect;

    const value = instumentedOneAnytpeArgU8Function(.{ .a = 5, .b = 7 });
    try expect(value == 12);
}

fn oneComptimeArgU8SliceFunction(comptime T: type) []const u8 {
    return @typeName(T);
}

const instumentedOneComptimeArgU8SliceFunction = instrument(oneComptimeArgU8SliceFunction, "oneComptimeArgU8SliceFunction");

test "Test instrument for comptime T function with 1 comptime Argument" {
    const std = @import("std");
    const expect = std.testing.expect;

    const value = instumentedOneComptimeArgU8SliceFunction(u8);
    try expect(std.mem.eql(u8, value, "u8"));
}
