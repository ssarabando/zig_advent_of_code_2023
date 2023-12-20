const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const meta = std.meta;
const expect = std.testing.expect;

const PossiblePartNumber = struct {
    x: u16,
    y: u16,
    len: u8,
    value: u16,
    pub fn init(value: []const u8, x: u16, y: u16) PossiblePartNumber {
        return PossiblePartNumber{
            .x = x,
            .y = y,
            .len = @intCast(value.len),
            .value = fmt.parseUnsigned(u16, value, 10) catch 0,
        };
    }
    pub fn is_adjacent_to_symbol(self: PossiblePartNumber, symbol: *const Symbol) bool {
        // Is adjacent if the symbol is anywhere from the column before up to
        // the column after and in the same line or in the one just before
        // or just after.
        const is_adjacent_line: bool = @as(i32, self.y) - 1 <= symbol.y and symbol.y <= self.y + 1;
        const is_adjacent_column: bool = @as(i32, self.x) - 1 <= symbol.x and symbol.x <= self.x + self.len;
        return is_adjacent_line and is_adjacent_column;
    }
};

const Symbol = struct {
    x: u16,
    y: u16,
    value: u8,
    pub fn init(symbol: u8, x: u16, y: u16) Symbol {
        return Symbol{ .x = x, .y = y, .value = symbol };
    }
};

fn is_digit(char: u8) bool {
    return char >= '0' and char <= '9';
}

fn is_symbol(char: u8) bool {
    return char != '.' and !is_digit(char);
}

fn print_syntax(stdout: fs.File.Writer) !void {
    try stdout.print("Syntax: day03\n\n", .{});
    try stdout.print("Computes the result of AoC 2023 day 3.\n", .{});
    try stdout.print("Example:\n\tcat input.txt | day03\n", .{});
}

pub fn main() !u8 {
    const stdout = io.getStdOut().writer();

    const stdin_file = io.getStdIn();
    if (stdin_file.isTty()) {
        try print_syntax(stdout);
        return 1;
    }

    var br = io.bufferedReader(stdin_file.reader());
    const stdin = br.reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var possible_parts = std.ArrayList(PossiblePartNumber).init(gpa.allocator());
    defer possible_parts.deinit();

    var symbols = std.ArrayList(Symbol).init(gpa.allocator());
    defer symbols.deinit();

    var line_buffer: [1024]u8 = undefined;

    var y: u16 = 0;
    while (true) {
        var result = try stdin.readUntilDelimiterOrEof(&line_buffer, '\n');
        if (result) |line| {
            var last_was_digit = false;
            var start_digit: u16 = 0;
            for (line, 0..) |char, x| {
                if (last_was_digit and is_digit(char)) continue;
                if (last_was_digit and !is_digit(char)) {
                    last_was_digit = false;
                    const ppn = PossiblePartNumber.init(
                        line[start_digit..x],
                        start_digit,
                        y,
                    );
                    start_digit = 0;
                    try possible_parts.append(ppn);
                }
                if (!last_was_digit and is_digit(char)) {
                    last_was_digit = true;
                    start_digit = @intCast(x);
                }
                if (is_symbol(char)) {
                    last_was_digit = false;
                    const symbol = Symbol.init(char, @intCast(x), y);
                    try symbols.append(symbol);
                }
            }
            // In case the last char was a digit, this is our change to catch
            // it.
            if (last_was_digit) {
                const ppn = PossiblePartNumber.init(
                    line[start_digit..],
                    start_digit,
                    y,
                );
                try possible_parts.append(ppn);
            }
        } else {
            break;
        }
        y += 1;
    }

    var parts = std.ArrayList(PossiblePartNumber).init(gpa.allocator());
    defer parts.deinit();

    var sum_of_part_numbers: usize = 0;
    for (possible_parts.items) |ppn| {
        for (symbols.items) |symbol| {
            if (ppn.is_adjacent_to_symbol(&symbol)) {
                try parts.append(ppn);
                sum_of_part_numbers += ppn.value;
                break;
            }
        }
    }

    var sum_of_gear_ratios: usize = 0;
    for (symbols.items) |symbol| {
        if (symbol.value != '*') continue;
        var number_of_adjacent_parts: u8 = 0;
        var gear_ratio: usize = 1;
        for (parts.items) |pn| {
            if (pn.is_adjacent_to_symbol(&symbol)) {
                number_of_adjacent_parts += 1;
                gear_ratio *= pn.value;
            }
        }
        if (number_of_adjacent_parts == 2) {
            sum_of_gear_ratios += gear_ratio;
        }
    }

    // Note: for some reason that I will not search for at this time, the
    // sum_of_part_numbers is different if run in powershell or in cmd:
    // cat input.txt | day03.exe (ps) gives me 541515.
    // day03.exe (cmd) gives me the correct number (540131).
    // Both give the correct sum_of_gear_ratios.
    try stdout.print("Sum of part numbers is {d}\n", .{sum_of_part_numbers});
    try stdout.print("Sum of gear ratios is {d}\n", .{sum_of_gear_ratios});

    return 0;
}
