const std = @import("std");
const io = std.io;

fn is_symbol(char: u8) bool {
    return !(char == '0' or (char >= '0' and char <= '9'));
}

fn print_syntax() !void {
    const stdout = io.getStdOut().writer();
    try stdout.print("Syntax: day03\n\n", .{});
    try stdout.print("Computes the result of AoC 2023 day 3.\n", .{});
    try stdout.print("Example:\n\tcat input.txt | day03\n", .{});
}

//   0        9
// 0 467..114..
//   ...*......
//   ..35..633.
//   ......#...
//   617*......
//   .....+.58.
//   ..592.....
//   ......755.
//   ...$.*....
// 9 .664.598..
//
// 467 -> 0,0 to 2,0 => search for at least 1 symbol from -1,-1 to 3,1 (* at 3,1)
// 114 -> 5,0 to 7,0 => search for at least 1 symbol from 4,-1 to 8,1 (none)
//  35 -> 2,2 to 3,2 => search for at least 1 symbol from 1,1 to 4,3 (* at 3,1)
// 633 -> 6,2 to 8,2 => search for at least 1 symbol from 5,1 to 9,3 (# at 6,3)
// 617 -> 0,4 to 2,4 => search for at least 1 symbol from -1,3 to 3,5 (* at 3,4)
//  58 -> 7,5 to 8,5 => search for at least 1 symbol from 6,4 to 9,6 (none)
// 592 -> 2,6 to 4,6 => search for at least 1 symbol from 1,5 to 5,7 (+ at 5,5)
// 755 -> 6,7 to 8,7 => search for at least 1 symbol from 5,6 to 9,8 (* at 5,8)
// 664 -> 1,9 to 3,9 => search for at least 1 symbol from 0,8 to 4,10 ($ at 3,8)
// 598 -> 5,9 to 7,9 => search for at least 1 symbol from 4,8 to 8,10 (* at 5,8)

// Ideas: always keep previous line in memory and always read ahead one line

pub fn main() !u8 {
    const stdin_file = io.getStdIn();
    if (stdin_file.isTty()) {
        try print_syntax();
        return 1;
    }
    return 0;
}
