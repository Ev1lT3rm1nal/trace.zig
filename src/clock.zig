const std = @import("std");
const Instant = std.time.Instant;
const builtin = std.builtin; 
const os = std.os;
const root = @import("root");

pub inline fn timestamp() u64 {
  if (@hasDecl(root, "tracePointTimestamp")) {
    return root.tracePointTimestamp();
  } else {
    return defaultTimeStamp();
  }
}

inline fn defaultTimeStamp() u64 {
  // return 0 when Instant.now returns an error.
  const instant = Instant.now() catch return 0;
  const ts = instant.timestamp;
  return convertTimestamp(@TypeOf(ts), ts);
}

test "defaultTimeStamp" {
  const ts1 = defaultTimeStamp();
  try std.testing.expect(ts1 != 0);
  std.debug.print("\ntimestamp={}\n", .{ts1});
  const ts2 = defaultTimeStamp();
  try std.testing.expect(ts2 != 0);
  std.debug.print("timestamp={}\n", .{ts2});
  try std.testing.expect(ts1 < ts2);
}

inline fn convertTimestamp(comptime T: type, time_stamp: T) u64 {
    if (T == os.timespec) {
      // Hint:
      //   Inspired by https://github.com/ziglang/zig/blob/8a5818535b83ba87849cb09de9f1ccd32e8bb480/lib/std/time.zig
      //   Line 113
      const tv_sec = time_stamp.tv_sec;
      const tv_nsec = time_stamp.tv_nsec;
      if (tv_sec < 0) {
        std.log.err("Negative timestamp values w.r.t to epoch: {}", .{time_stamp});
        return 0;
      }
      if (tv_nsec < 0) {
        std.log.err("Negative timestamp values w.r.t to epoch: {}", .{time_stamp});
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