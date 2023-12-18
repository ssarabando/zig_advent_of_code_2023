const std = @import("std");
const io = std.io;
const fmt = std.fmt;
const mem = std.mem;
const process = std.process;

const Bag = struct {
    red: u8 = 0,
    green: u8 = 0,
    blue: u8 = 0,
};

fn print_syntax() !void {
    const stdout = io.getStdOut().writer();
    try stdout.print("Syntax: day02 <r> <g> <b>\n\n", .{});
    try stdout.print("Computes the result of AoC 2023 day 2.\n", .{});
    try stdout.print("- r (u8)\tnumber of red cubes\n", .{});
    try stdout.print("- g (u8)\tnumber of green cubes\n", .{});
    try stdout.print("- b (u8)\tnumber of blue cubes\n\n", .{});
    try stdout.print("Example:\n\tcat input.txt | day02 12 13 14\n", .{});
}

fn get_args(allocator: mem.Allocator) !Bag {
    var args = try process.argsWithAllocator(allocator);
    defer args.deinit();

    var bag = Bag{};
    var arg_number: isize = -1;
    while (args.next()) |arg| {
        arg_number += 1;
        switch (arg_number) {
            1 => bag.red = fmt.parseUnsigned(u8, arg, 10) catch {
                return error.InvalidSyntaxError;
            },
            2 => bag.green = fmt.parseUnsigned(u8, arg, 10) catch {
                return error.InvalidSyntaxError;
            },
            3 => bag.blue = fmt.parseUnsigned(u8, arg, 10) catch {
                return error.InvalidSyntaxError;
            },
            else => {},
        }
    }
    if (arg_number < 3) {
        return error.InvalidSyntaxError;
    }

    return bag;
}

pub fn main() !u8 {
    if (std.io.getStdIn().isTty()) {
        try print_syntax();
        return 1;
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const bag = get_args(gpa.allocator()) catch {
        try print_syntax();
        return 2;
    };

    const stdin_file = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(stdin_file);
    const stdin = br.reader();

    var line_buffer: [1024]u8 = undefined;

    var sum_of_ids_of_possible_games: u32 = 0;
    var pow: u64 = 0;
    while (true) {
        var result = try stdin.readUntilDelimiterOrEof(&line_buffer, '\n');
        var min_bag = Bag{};
        var is_possible = true;
        if (result) |line| {
            //
            // Find the game ID.
            //
            // Split the line into two parts: the one that has the game id
            // (the one to the left of the colon and that starts with
            // 'Game ') and the rest.
            var chunks = mem.splitScalar(u8, line, ':');
            // Put a 0 into the game_id in case of an error since that
            // should be impossible with the AoC's data.
            const game_id = try fmt.parseUnsigned(u8, chunks.first()[5..], 10);
            // Always presume that the game is possible.
            sum_of_ids_of_possible_games += game_id;
            //
            // Find out the number of reaches the elf made in this game.
            //
            // AoC's input ensures there is something after the colon, so it is
            // safe to ignore the optional.
            const reaches_chunk = chunks.next().?;
            // Split the reaches (ignoring the 1st char, which is always a
            // space) that were made during the game.
            var reaches = mem.splitSequence(u8, reaches_chunk[1..], "; ");
            while (reaches.next()) |cubes_in_reach| {
                // Split the reach into the different cubes fetched from the bag.
                var cubes = mem.splitSequence(u8, cubes_in_reach, ", ");
                while (cubes.next()) |cube_data| {
                    // Extract the number of cubes and their color.
                    // The number of cubes comes first, then a space and finally
                    // a color.
                    var cube_data_parts = mem.splitScalar(u8, cube_data, ' ');
                    const number_of_cubes = try fmt.parseUnsigned(u8, cube_data_parts.first(), 10);
                    const cube_color = cube_data_parts.rest();

                    // Since the line may end with a linefeed (\r), we may
                    // have to strip it so that we can compare the color.
                    const len = if (cube_color[cube_color.len - 1] == '\r') cube_color.len - 1 else cube_color.len;

                    var max: u8 = 0;
                    if (mem.eql(u8, "red", cube_color[0..len])) {
                        max = bag.red;
                        if (number_of_cubes > min_bag.red) {
                            min_bag.red = number_of_cubes;
                        }
                    } else if (mem.eql(u8, "green", cube_color[0..len])) {
                        max = bag.green;
                        if (number_of_cubes > min_bag.green) {
                            min_bag.green = number_of_cubes;
                        }
                    } else if (mem.eql(u8, "blue", cube_color[0..len])) {
                        max = bag.blue;
                        if (number_of_cubes > min_bag.blue) {
                            min_bag.blue = number_of_cubes;
                        }
                    }

                    if (is_possible and number_of_cubes > max) {
                        is_possible = false;
                        // Remove the game_id from the sum
                        sum_of_ids_of_possible_games -= game_id;
                    }
                }
            }
            pow += @as(u32, min_bag.red) * @as(u32, min_bag.green) * @as(u32, min_bag.blue);
        } else {
            break;
        }
    }

    try io.getStdOut().writer().print("Part 1: {d}\n", .{sum_of_ids_of_possible_games});
    try io.getStdOut().writer().print("Part 2: {d}\n", .{pow});

    return 0;
}
