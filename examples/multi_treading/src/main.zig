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
    std.log.debug("Hello from thread {}. About to sleep {} ms.", .{ id, msToSleep });
    const nanoseconds = msToSleep * 1_000_000;
    sleep(nanoseconds);
    std.log.debug("Thread {} ready sleeping {} ms.", .{ Thread.getCurrentId(), msToSleep });
}

pub fn main() !void {
    const span = Span.open("main");
    defer span.close();
    std.log.debug("Using spans in a multi-threaded environment.", .{});

    // Threads interleave with each other
    const thread1 = try Thread.spawn(.{}, threadFunction, .{50});
    sleep(25_000_000);
    const thread2 = try Thread.spawn(.{}, threadFunction, .{50});
    thread1.join();
    thread2.join();
    std.log.debug("Interleaved threads example finished.", .{});

    // Longer running thread  encloses shorter running thread
    const thread3 = try Thread.spawn(.{}, threadFunction, .{100});
    sleep(25_000_000);
    const thread4 = try Thread.spawn(.{}, threadFunction, .{50});

    thread3.join();
    thread4.join();
    std.log.debug("Enclosing thread example finished.", .{});
}
