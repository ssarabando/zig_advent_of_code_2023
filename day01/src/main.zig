const std = @import("std");

const MaxLineSize: usize = 4096;

const CalibrationValue = struct {
    value: u64,
    pub fn init(first: u32, last: u32) CalibrationValue {
        return CalibrationValue{ .value = first * 10 + last };
    }
};

const Numbers = [_][]const u8{
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
};

const Ordinals = "123456789";

fn spell_to_ordinal(line: []u8) []u8 {
    // The line with all spelled out numbers converted to their ordinal values.
    var new_line: [MaxLineSize]u8 = undefined;
    // The position (in the line) of the character being processed.
    var i: usize = 0;
    // The current number of ordinals copied over.
    var ordinals: usize = 0;
    while (i < line.len) {
        var char = line[i];
        if (char >= '0' and char <= '9') {
            // Already an ordinal, so just copy it.
            new_line[ordinals] = char;
            ordinals += 1;
        } else {
            // A letter. May be the start of a spelled number.
            var spelled_number_found = false;
            // Number of characters that make the spelled number.
            var chars_in_number: usize = 0;
            // Remaining number of chars in the line.
            var remaining_chars = line.len - i;
            for (Numbers, 0..) |number, n| {
                chars_in_number = number.len;
                if (remaining_chars < chars_in_number) continue;
                const possible_spelled_number = line[i .. i + chars_in_number];
                if (std.mem.eql(u8, number, possible_spelled_number)) {
                    new_line[ordinals] = Ordinals[n];
                    spelled_number_found = true;
                    break;
                }
            }
            if (spelled_number_found) {
                ordinals += 1;
            }
        }
        i += 1;
    }
    return new_line[0..ordinals];
}

fn find_calibration_value(line: []u8) CalibrationValue {
    if (line.len == 0) {
        return CalibrationValue.init(0, 0);
    }

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

    var line_buffer: [MaxLineSize]u8 = undefined;
    var total: u64 = 0;
    while (true) {
        var line = try r.readUntilDelimiterOrEof(&line_buffer, '\n');
        if (line) |l| {
            var calibration_value = find_calibration_value(spell_to_ordinal(l));
            total += calibration_value.value;
        } else {
            break;
        }
    }
    try stdout.print("Total: {d}\n", .{total});
}
