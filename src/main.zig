pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var lexer = Lexer{
        .rootfile = "lang-snippets/test-imports.noasm",
        .allocator = allocator,
    };

    lexer.tokenize() catch |err| {
        std.debug.print("Lexer error: {s} at line {}\n", .{ @errorName(err), lexer.currLine + 1 });
        return err;
    };

    for (lexer.tokens.?.items) |tok| {
        const formatted = try tok.toString(allocator);
        defer allocator.free(formatted);
        std.debug.print("{s}", .{formatted});
    }
}

const std = @import("std");
const Lexer = @import("lexer").Lexer;
