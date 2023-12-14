const std = @import("std");

const CalibrationValue = struct {
    value: u64,
    pub fn init(first: u32, last: u32) CalibrationValue {
        return CalibrationValue{ .value = first * 10 + last };
    }
};

fn find_calibration_value(line: []u8) CalibrationValue {
    var first: u32 = 0;
    for (line) |char| {
        if (char >= '0' and char <= '9') {
            first = std.fmt.parseInt(u32, &[1]u8{char}, 10) catch 0;
            break;
        }
    }

    var last: u32 = 0;
    var idx = line.len - 1;
    while (idx >= 0) : (idx -= 1) {
        var char = line[idx];
        if (char >= '0' and char <= '9') {
            last = std.fmt.parseInt(u32, &[1]u8{char}, 10) catch 0;
            break;
        }
    }

    return CalibrationValue.init(first, last);
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const stdin = std.io.getStdIn();
    var br = std.io.bufferedReader(stdin.reader());
    var r = br.reader();

    var line_buffer: [4096]u8 = undefined;
    var total: u64 = 0;
    while (true) {
        var line = try r.readUntilDelimiterOrEof(&line_buffer, '\n');
        if (line) |l| {
            var calibration_value = find_calibration_value(l);
            total += calibration_value.value;
        } else {
            break;
        }
    }
    try stdout.print("Total: {d}\n", .{total});
}
