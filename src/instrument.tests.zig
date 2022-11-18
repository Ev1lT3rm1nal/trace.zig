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

// ============ Tests for 2 arguments ============================

fn vanilla2Args(x: u8, y: u8) u8 {
    return x + y;
}

test "Test 2 arguments vanilla pattern" {
    const expect = @import("std").testing.expect;
    const instrumentedVanilla2Args = instrument(vanilla2Args, "vanilla2Args");
    try expect(11 == instrumentedVanilla2Args(5, 6));
}

fn firstArgType2Args(comptime T: type, x: T) u8 {
    return @as(u8, x * x);
}

test "Test 2 arguments type first argument pattern" {
    const expect = @import("std").testing.expect;
    const instrumented = instrument(firstArgType2Args, "firstArgType2Args");
    try expect(25 == instrumented(u8, 5));
}

fn lastArgAnytype2Args(x: u8, y: anytype) u8 {
    var z: u8 = 0;
    var ret = x;
    while (z <= y) : (z += 1) {
        ret *= x;
    }
    return ret;
}

test "Test 2 arguments anytype last argument pattern" {
    const expect = @import("std").testing.expect;
    const instrumented = instrument(lastArgAnytype2Args, "lastArgAnytype2Args");
    try expect(128 == instrumented(2, 5));
}

fn firstTypeLastAnytype2Args(comptime T: type, y: anytype) u8 {
    return @as(T, y);
}

test "Test 2 arguments first \"type\" last anytype argument pattern" {
    const expect = @import("std").testing.expect;
    const instrumented = instrument(firstTypeLastAnytype2Args, "firstTypeLastAnytype2Args");
    try expect(5 == instrumented(u16, 5));
}

// ============ Tests for 3 arguments ============================

fn vanilla3Args(x: u8, y: u8, z: u8) u8 {
    return x + y + z;
}

test "Test 3 arguments vanilla pattern" {
    const expect = @import("std").testing.expect;
    const instrumented = instrument(vanilla3Args, "vanilla3Args");
    try expect(18 == instrumented(5, 6, 7));
}

fn firstArgType3Args(comptime T: type, x: u8, y: T) u8 {
    return @as(T, x * y);
}

test "Test 3 arguments type first argument pattern" {
    const expect = @import("std").testing.expect;
    const instrumented = instrument(firstArgType3Args, "firstArgType3Args");
    try expect(30 == instrumented(u8, 5, 6));
}

fn lastArgAnytype3Args(x: u8, y: u8, z: anytype) u8 {
    var ret = x;
    var t: u8 = 1;
    while (t <= y) : (t += z) {
        ret *= x;
    }
    return ret + z;
}

test "Test 3 arguments anytype last argument pattern" {
    const expect = @import("std").testing.expect;
    const instrumented = instrument(lastArgAnytype3Args, "lastArgAnytype3Args");
    try expect(65 == instrumented(2, 5, 1));
}

fn firstTypeLastAnytype3Args(comptime T: type, x: u8, y: anytype) u8 {
    return @as(T, x + y);
}

test "Test 3 arguments first \"type\" last anytype argument pattern" {
    const expect = @import("std").testing.expect;
    const instrumented = instrument(firstTypeLastAnytype3Args, "firstTypeLastAnytype2Args");
    try expect(125 == instrumented(u8, 5, 120));
}

// ========================================================================================
// Test struct methods
// ========================================================================================

const Point = struct {
    x: u32,
    y: u32,
    const Self = Point;
    fn innerDotProduct(self: Point, other: Point) u32 {
        return self.x * other.x + self.y * other.y;
    }
    const dotProduct = instrument(innerDotProduct, "Point.dotProduct");
};

test "Struct method" {
    const point_1 = Point{
        .x = 5,
        .y = 6,
    };
    const point_2 = Point{
        .x = 6,
        .y = 5,
    };
    const dot = point_1.dotProduct(point_2);
    try @import("std").testing.expect(60 == dot);
}

// ========================================================================================
// Unsupported functions
// ========================================================================================

// Currently not supported since it is not clear how to identify if an argument is comptime
fn comptimeAnytypeOneArgumentVoidFunction(comptime f: anytype) void {
    const std = @import("std");
    const type_info = @typeInfo(@TypeOf(f));
    const arg = type_info.Fn.args[0];
    std.debug.print("Param of comptime anytype: {}", .{arg});
}

// Currently not supported since it is not clear how to identify if an argument is comptime
fn anotherFunction(comptime x: anytype) void {
    const std = @import("std");
    const type_name = @typeName(@TypeOf(x));
    std.debug.print("Type name: {}", .{type_name});
}

fn genericAdd(x: anytype) @TypeOf(x) {
    return x + 1;
}

// Currently not supported since return_type is null
fn pow2(comptime T: type, x: T) @TypeOf(x) {
    return x * x;
}
