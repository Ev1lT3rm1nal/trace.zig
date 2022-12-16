const std = @import("std");
const trace = @import("trace");
const Span = trace.Span;
const instrument = trace.instrument;
const AllocatorError = std.mem.Allocator.Error;

// Required to enable tracing
pub const enable_trace = false;

inline fn calculationExample() AllocatorError!f64 {
    var prng = std.rand.DefaultPrng.init(1);
    const rand = prng.random();

    const allocation_span = Span.open("Allocation");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if (leaked) std.testing.expect(false) catch @panic("TEST FAIL"); //fail test; can't try in defer as defer is executed after we return
    }
    const length = 1_000_000;
    var a = try std.ArrayList(f64).initCapacity(allocator, length);
    defer a.deinit();
    var b = try std.ArrayList(f64).initCapacity(allocator, length);
    defer b.deinit();
    var c = try std.ArrayList(f64).initCapacity(allocator, length);
    defer c.deinit();
    allocation_span.close();
    const array_initialisation_span = Span.open("Array initialization");
    var i: usize = 0;
    while (i < length) : (i += 1) {
        try a.append(rand.float(f64));
        try b.append(rand.float(f64));
        try c.append(0.0);
    }
    array_initialisation_span.close();

    var sum: f64 = 0.0;
    {
        const calculation_span = Span.open("Calculation");
        defer calculation_span.close();
        for (c.items) |_, index| {
            c.items[index] = a.items[index] * b.items[index];
        }
        for (c.items) |value| {
            sum += value;
        }
    }

    return sum;
}

const calcExample = instrument(calculationExample, "calculationExample Function");

pub fn main() !void {
    const main_span = Span.open("main function");
    defer main_span.close();

    const sum = try calcExample(.{});

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    try stdout.print("Output of the main function: {}\n", .{sum});
    try bw.flush();
}
