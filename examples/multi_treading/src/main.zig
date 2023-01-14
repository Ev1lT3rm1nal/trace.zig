const std = @import("std");
const trace = @import("trace");
const Span = trace.Span;
const Thread = std.Thread;
const sleep = std.time.sleep;

pub const enable_trace = true;

fn threadFunction(msToSleep: u64) void {
    const span = Span.open("threadFunction");
    defer span.close();
    const id = Thread.getCurrentId();
    std.debug.print("Hello from thread {}. About to sleep {} ms.\n", .{ id, msToSleep });
    const nanoseconds = msToSleep * 1_000_000;
    sleep(nanoseconds);
    std.debug.print("Thread {} ready sleeping {} ms.\n", .{ Thread.getCurrentId(), msToSleep });
}

pub fn main() !void {
    const span = Span.open("main");
    defer span.close();
    std.debug.print("Using spans in a multi-threaded environment.\n", .{});

    const thread1 = try Thread.spawn(.{}, threadFunction, .{550});
    sleep(50_000_000);
    const thread2 = try Thread.spawn(.{}, threadFunction, .{200});
    sleep(50_000_000);
    const thread3 = try Thread.spawn(.{}, threadFunction, .{200});

    thread1.join();
    thread2.join();
    thread3.join();
}
