pub const TraceType = enum(u2) {
    span_open = 0,
    span_close = 1,
    event = 2,
    error_event = 3,
};

pub const TracePointStruct = struct {
    id: []const u8,
    timestamp: i128,
    trace_type: TraceType,
};

pub fn TracePoint(comptime id_length: comptime_int) type {
    return struct {
        id: *const [id_length:0]u8,
        timestamp: i128,
        trace_type: TraceType,
        const Self = @This();

        pub fn toBytes(self: *Self) [id_length + 16 + 1]u8 {
            const length = id_length + 16 + 1;
            var bytes: [length]u8 = undefined;
            var ts = self.timestamp;
            var index: usize = 15;
            while (index > 0) : (index -= 1) {
                bytes[index] = @intCast(u8, ts & 0xFF);
                ts >>= 8;
            }
            bytes[0] = @intCast(u8, ts & 0xFF);

            index = 16;
            bytes[index] = @enumToInt(self.trace_type);
            index += 1;

            for (self.id) |byte| {
                bytes[index] = byte;
                index += 1;
            }
            return bytes;
        }
    };
}

test "TracePoint.toBytes" {
    const std = @import("std");
    const testing = std.testing;

    // Arrange
    var trace_point = TracePoint(16){
        .trace_type = TraceType.event,
        .timestamp = 0x00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F,
        .id = "Trace point test",
    };

    // Act
    var bytes = trace_point.toBytes();

    // Assert
    try testing.expect(33 == bytes.len);

    var index: u8 = 0;

    while (index < 16) : (index += 1) {
        try testing.expectEqual(index, bytes[index]);
    }

    try testing.expect(2 == bytes[16]);

    index += 1;

    const id = "Trace point test";

    for (id) |c| {
        try testing.expectEqual(c, bytes[index]);
        index += 1;
    }
}
