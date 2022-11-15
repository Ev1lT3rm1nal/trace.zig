const std = @import("std");
const Span = @import("span.zig");

pub inline fn instrument(comptime f: anytype, id: []const u8) @TypeOf(f) {
    return instrument0Args(f, id);
}

inline fn instrument0Args(comptime f: anytype, id: []const u8) @TypeOf(f) {
    const Wrapper = struct {
        fn wrapped() @typeInfo(@TypeOf(f)).Fn.return_type.? {
            const span = Span.open(id);
            defer span.close();
            return f();
        }
    };
    return Wrapper.wrapped;
}
