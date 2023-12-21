const std = @import("std");

pub fn Card() type {
    return struct {
        number: u8,
        numbers: std.ArrayList(u8),
        winning_numbers: std.ArrayList(u8),

        const Self = @This();

        pub fn init(card_number: u8, allocator: std.mem.Allocator) Self {
            return Self{
                .number = card_number,
                .numbers = std.ArrayList(u8).init(allocator),
                .winning_numbers = std.ArrayList(u8).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.numbers.deinit();
            self.winning_numbers.deinit();
            self.* = undefined;
        }

        pub fn addNumber(self: *Self, number: u8) !void {
            try self.numbers.append(number);
        }

        // Register a winning number.
        // If the card has this winning number, it will be added to the
        // winning_numbers field, otherwise it will be discarded.
        // This assumes all card numbers have already been added.
        pub fn addWinningNumber(self: *Self, number: u8) !void {
            for (self.numbers.items) |card_number| {
                if (card_number == number) {
                    try self.winning_numbers.append(number);
                }
            }
        }
    };
}

fn print_syntax(stdout: std.fs.File.Writer) !void {
    try stdout.print("Syntax: day04\n\n", .{});
    try stdout.print("Computes the result of AoC 2023 day 4.\n", .{});
    try stdout.print("Example:\n\tcat input.txt | day04\n", .{});
}

pub fn main() !u8 {
    const stdout = std.io.getStdOut().writer();

    const stdin_file = std.io.getStdIn();
    if (stdin_file.isTty()) {
        try print_syntax(stdout);
        return 1;
    }

    var br = std.io.bufferedReader(stdin_file.reader());
    const stdin = br.reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var points: usize = 0;

    var buffer: [1024]u8 = undefined;
    while (true) {
        var result = try stdin.readUntilDelimiterOrEof(&buffer, '\n');
        if (result) |line| {
            const colon_pos = std.mem.indexOf(u8, line, ":").?;
            var card_number_chunks = std.mem.tokenizeSequence(u8, line[0..colon_pos], " ");
            // Get rid of the 'Card' chunk
            _ = card_number_chunks.next();
            // The rest of the chunks is the card number
            const card_number = try std.fmt.parseUnsigned(
                u8,
                card_number_chunks.rest(),
                10,
            );

            var card = Card().init(card_number, gpa.allocator());
            defer card.deinit();

            const divider_pos = std.mem.indexOf(u8, line, "|").?;
            var number_chunks = std.mem.tokenizeSequence(
                u8,
                line[colon_pos + 2 .. divider_pos],
                " ",
            );
            while (number_chunks.next()) |number_repr| {
                const number = try std.fmt.parseUnsigned(u8, number_repr, 10);
                try card.addNumber(number);
            }

            var winning_number_chunks = std.mem.tokenizeSequence(
                u8,
                line[divider_pos + 2 ..],
                " ",
            );
            while (winning_number_chunks.next()) |number_repr| {
                const end = if (number_repr[number_repr.len - 1] == '\r') number_repr.len - 1 else number_repr.len;
                const number = try std.fmt.parseUnsigned(u8, number_repr[0..end], 10);
                try card.addWinningNumber(number);
            }

            if (card.winning_numbers.items.len > 0) {
                // std.debug.print("{d}\n", .{card.winning_numbers.items.len - 1});
                points += try std.math.powi(usize, 2, card.winning_numbers.items.len - 1);
            }
        } else break;
    }

    try stdout.print("Points: {d}\n", .{points});

    return 0;
}

test "card declaration" {
    var card = Card().init(1, std.testing.allocator);
    defer card.deinit();
    try std.testing.expect(card.number == 1);
}

test "adding numbers to a card" {
    var card = Card().init(1, std.testing.allocator);
    defer card.deinit();
    try card.addNumber(1);
    try std.testing.expect(card.numbers.items.len == 1);
    try std.testing.expect(card.numbers.items[0] == 1);
}

test "adding winning numbers to a card" {
    var card = Card().init(1, std.testing.allocator);
    defer card.deinit();
    try card.addNumber(1);
    try card.addWinningNumber(1);
    try std.testing.expect(card.winning_numbers.items.len == 1);
    try std.testing.expect(card.winning_numbers.items[0] == 1);
}

test "get card winning numbers" {
    var card = Card().init(1, std.testing.allocator);
    defer card.deinit();

    for ([_]u8{ 41, 48, 83, 86, 17 }) |number| {
        try card.addNumber(number);
    }

    for ([_]u8{ 83, 86, 6, 31, 17, 9, 48, 53 }) |winning_number| {
        try card.addWinningNumber(winning_number);
    }

    try std.testing.expect(card.winning_numbers.items.len == 4);

    var found = [_]bool{ false, false, false, false };
    for (card.winning_numbers.items) |winning_number| {
        if (winning_number == 17) found[0] = true;
        if (winning_number == 48) found[1] = true;
        if (winning_number == 83) found[2] = true;
        if (winning_number == 86) found[3] = true;
    }

    try std.testing.expect(found[0] == true and found[1] == true and found[2] == true and found[3] == true);
}
