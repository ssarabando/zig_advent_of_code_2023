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

fn _adjacency_tests(ppn: PossiblePartNumber, expected: Symbol, symbols: []const Symbol) !void {
    for (symbols) |symbol| {
        const actual = ppn.is_adjacent_to_symbol(&symbol);
        if (meta.eql(expected, symbol)) {
            try expect(actual);
        } else {
            try expect(!actual);
        }
    }
}

// yx0123456789
// 0 467..114..
// 1 ...*......
// 2 ..35..633.
// 3 ......#...
// 4 617*......
// 5 .....+.58.
// 6 ..592.....
// 7 ......755.
// 8 ...$.*....
// 9 .664.598..
// yx0123456789
test "adjacency tests" {
    const symbols = [_]Symbol{
        Symbol.init('*', 3, 1),
        Symbol.init('#', 6, 3),
        Symbol.init('*', 3, 4),
        Symbol.init('+', 5, 5),
        Symbol.init('$', 3, 8),
        Symbol.init('*', 5, 8),
    };
    const ppns = [_]PossiblePartNumber{
        PossiblePartNumber.init("467", 0, 0),
        PossiblePartNumber.init("114", 5, 0),
        PossiblePartNumber.init("35", 2, 2),
        PossiblePartNumber.init("633", 6, 2),
        PossiblePartNumber.init("617", 0, 4),
        PossiblePartNumber.init("58", 7, 5),
        PossiblePartNumber.init("592", 2, 6),
        PossiblePartNumber.init("755", 6, 7),
        PossiblePartNumber.init("664", 1, 9),
        PossiblePartNumber.init("598", 5, 9),
    };
    // 467 is a part number (adjacent to the 1st *)
    try _adjacency_tests(ppns[0], symbols[0], symbols[0..]);
    // 114 is not a part number
    for (symbols) |symbol| {
        try expect(!ppns[1].is_adjacent_to_symbol(&symbol));
    }
    // 35 is a part number (adjacent to the 1st *)
    try _adjacency_tests(ppns[2], symbols[0], symbols[0..]);
    // 633 is a part number (adjacent to the #)
    try _adjacency_tests(ppns[3], symbols[1], symbols[0..]);
    // 617 is a part number (adjacent to the 2nd *)
    try _adjacency_tests(ppns[4], symbols[2], symbols[0..]);
    // 58 is not a part number
    for (symbols) |symbol| try expect(!ppns[5].is_adjacent_to_symbol(&symbol));
    // 592 is a part number (adjacent to the 1st +)
    try _adjacency_tests(ppns[6], symbols[3], symbols[0..]);
    // 755 is a part number (adjacent to the 3rd *)
    try _adjacency_tests(ppns[7], symbols[5], symbols[0..]);
    // 664 is a part number (adjacent to the 1st $)
    try _adjacency_tests(ppns[8], symbols[4], symbols[0..]);
    // 598 is a part number (adjacent to the 3rd *)
    try _adjacency_tests(ppns[9], symbols[5], symbols[0..]);
}

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

    var sum_of_part_numbers: usize = 0;
    for (possible_parts.items) |ppn| {
        std.debug.print("{d},{d}: {d}\n", .{ ppn.y, ppn.x, ppn.value });
        for (symbols.items) |symbol| {
            // std.debug.print("\t{d},{d}: {u}\n", .{ symbol.y, symbol.x, symbol.value });
            if (ppn.is_adjacent_to_symbol(&symbol)) {
                // std.debug.print("\t\tFound a part number. {d} = {d} + {d}\n", .{
                //     sum_of_part_numbers + ppn.value,
                //     sum_of_part_numbers,
                //     ppn.value,
                // });
                sum_of_part_numbers += ppn.value;
                break;
            }
        }
    }

    try stdout.print("Sum of part numbers is {d}\n", .{sum_of_part_numbers});

    return 0;
}

test "digit recognition" {
    try expect(!is_digit('.'));
    try expect(is_digit('0'));
    try expect(is_digit('1'));
    try expect(is_digit('2'));
    try expect(is_digit('3'));
    try expect(is_digit('4'));
    try expect(is_digit('5'));
    try expect(is_digit('6'));
    try expect(is_digit('7'));
    try expect(is_digit('8'));
    try expect(is_digit('9'));
    try expect(!is_digit('*'));
    try expect(!is_digit('='));
    try expect(!is_digit('-'));
    try expect(!is_digit('/'));
    try expect(!is_digit('%'));
    try expect(!is_digit('$'));
    try expect(!is_digit('&'));
    try expect(!is_digit('@'));
}

test "symbol recognition" {
    try expect(!is_symbol('.'));
    try expect(!is_symbol('0'));
    try expect(!is_symbol('1'));
    try expect(!is_symbol('2'));
    try expect(!is_symbol('3'));
    try expect(!is_symbol('4'));
    try expect(!is_symbol('5'));
    try expect(!is_symbol('6'));
    try expect(!is_symbol('7'));
    try expect(!is_symbol('8'));
    try expect(!is_symbol('9'));
    try expect(is_symbol('*'));
    try expect(is_symbol('='));
    try expect(is_symbol('-'));
    try expect(is_symbol('/'));
    try expect(is_symbol('%'));
    try expect(is_symbol('$'));
    try expect(is_symbol('&'));
    try expect(is_symbol('@'));
}
