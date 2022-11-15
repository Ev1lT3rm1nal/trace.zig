const instrument = @import("instrument.zig").instrument;

fn zeroArgVoidFunction() void {
    const std = @import("std");
    std.debug.print("Zero arg void function called.", .{});
}

const instrumentedZeroArgVoidFunction = instrument(zeroArgVoidFunction, "zero arg void function");

fn zeroArgU8Function() u8 {
    return 127;
}

const instrumentedZeroArgU8Function = instrument(zeroArgU8Function, "zero arg u8 function");

inline fn inlinedZeroArgU8Function() u8 {
    return 111;
}

const instrumentedInlinedZeroArgU8Function = instrument(inlinedZeroArgU8Function, "zero arg u8 function");


test "Test instrument for void function with 0 Arguments" {
    const expect = @import("std").testing.expect;

    instrumentedZeroArgVoidFunction();
    try expect(true);
}

test "Test instrument for u8 function with 0 Arguments" {
    const expect = @import("std").testing.expect;

    const value = instrumentedZeroArgU8Function();
    try expect(value == 127);
}

test "Test instrument for inlined u8 function with 0 Arguments" {
    const expect = @import("std").testing.expect;

    const value = instrumentedInlinedZeroArgU8Function();
    try expect(value == 111);
}