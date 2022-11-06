pub const TraceType = enum(u2) {
    span_open = 0,
    span_close = 1,
    event = 2,
};

pub const TracePoint = struct {
    id: [] const u8,
    timestamp: i128,
    trace_type: TraceType,

    pub fn toBytes(self: TracePoint) [] const u8 {
        const length = self.id.len + 16 + 1;
        var bytes: [length] u8 = undefined;
        var ts = self.timestamp;
        var index = 15;
        while (index >= 0) : (index -= 1) {
            bytes[index] = ts & 0xFF;
            ts >>= 8;
        }
        bytes[16] = @enumToInt(self.trace_type);
        return bytes;
    }
};

test "TracePoint.toBytes" {
    const testing = @import("std").testing;

    // Arrange
    const trace_point = TracePoint{
        .trace_type = TraceType.event,
        .timestamp = 0x00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F,
        .id = "Trace point test",
    };

    // Act
    var bytes = trace_point.toBytes();

    // Assert
    try testing.expectEqual(33, bytes.len);

    var index = 0;

    while (index < 16) : (index += 1) {
        testing.expectEqual(index, bytes[index]);
    }

    testing.expectEqual(2, bytes[index]);

    index += 1;

    const id = "Trace point test";

    for (id) |c| {
        testing.expectEqual(c, bytes[index]);
        index += 1;
    }

}
