//! The namespace containing the functions needed to provide timestamps,
//! which are necessary for `TracePoint`s.

const std = @import("std");
const Instant = std.time.Instant;
const builtin = std.builtin;
const os = std.os;
const root = @import("root");

/// Function that returns a timestamp.
pub inline fn timestamp() u64 {
    if (@hasDecl(root, "tracePointTimestamp")) {
        return root.tracePointTimestamp();
    } else {
        return defaultTimestamp();
    }
}

/// Default timestamp implementation. Returns a timestamp in nanoseconds
/// resolution.
///
/// Uses `std.time.Instant` which is currently not monotonic.
inline fn defaultTimestamp() u64 {
    // return 0 when Instant.now returns an error.
    const instant = Instant.now() catch return 0;
    const ts = instant.timestamp;
    return convertTimestamp(@TypeOf(ts), ts);
}

/// Converts a timestamp into `u64` value.
///
/// This is necessary since `Instant.now` returns a `os.timespec`,
/// instead of a u64.
///
/// If the returned value is negative w.r.t. to the epoch, then 0 is returned
/// and an error is logged. (This is lowered to `std.debug.log` so that
/// test return in a success without further information on occured errors).
inline fn convertTimestamp(comptime T: type, time_stamp: T) u64 {
    if (T == os.timespec) {
        // Hint:
        //   Inspired by https://github.com/ziglang/zig/blob/8a5818535b83ba87849cb09de9f1ccd32e8bb480/lib/std/time.zig
        //   Line 113
        const tv_sec = time_stamp.tv_sec;
        const tv_nsec = time_stamp.tv_nsec;
        if (tv_sec < 0) {
            if (@import("builtin").is_test) {
                std.log.debug("Negative timestamp values w.r.t to epoch: {}", .{time_stamp});
            } else {
                std.log.err("Negative timestamp values w.r.t to epoch: {}", .{time_stamp});
            }
            return 0;
        }
        if (tv_nsec < 0) {
            if (@import("builtin").is_test) {
                std.log.debug("Negative timestamp values w.r.t to epoch: {}", .{time_stamp});
            } else {
                std.log.err("Negative timestamp values w.r.t to epoch: {}", .{time_stamp});
            }
            return 0;
        }
        return (@intCast(u64, tv_sec) * 1_000_000_000) + @intCast(u64, tv_nsec);
    } else if (@TypeOf(time_stamp) == u64) {
        return time_stamp;
    } else {
        @compileLog("Instant.now return type={}", .{T});
        return 0;
    }
}

test "convertTimestamp for u64" {
    // Arrange
    // Act
    const ts = convertTimestamp(u64, 17);
    // Assert
    try std.testing.expect(ts == 17);
}

test "convertTimestamp for postive os.timespec" {
    // Arrange
    const expect = std.testing.expect;
    const os_ts = os.timespec{
        .tv_sec = 17,
        .tv_nsec = 333,
    };
    // Act
    const ts = convertTimestamp(os.timespec, os_ts);
    // Assert
    try expect(ts == 17_000_000_333);
}

test "convertTimestamp for negaive tv_sec os.timespec" {
    // Arrange
    const expect = std.testing.expect;
    const os_ts = os.timespec{
        .tv_sec = -17,
        .tv_nsec = 333,
    };
    // Act
    const ts = convertTimestamp(os.timespec, os_ts);
    // Assert
    try expect(ts == 0);
}

test "convertTimestamp for negative tv_nsec os.timespec" {
    // Arrange
    const expect = std.testing.expect;
    const os_ts = os.timespec{
        .tv_sec = 17,
        .tv_nsec = -333,
    };
    // Act
    const ts = convertTimestamp(os.timespec, os_ts);
    // Assert
    try expect(ts == 0);
}

test "timestamp" {
    // Arrange

    // Act
    const ts1 = timestamp();
    const ts2 = timestamp();

    // Assert
    try std.testing.expect(ts1 != 0);
    try std.testing.expect(ts2 != 0);
    try std.testing.expect(ts1 < ts2);
}

test "defaultTimestamp" {
    // Arrange
    // Act
    const ts1 = defaultTimestamp();
    const ts2 = defaultTimestamp();
    // Assert
    try std.testing.expect(ts1 != 0);
    try std.testing.expect(ts2 != 0);
    try std.testing.expect(ts1 < ts2);
}
