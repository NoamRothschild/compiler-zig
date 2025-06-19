pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var lexer = Lexer{
        // .rootfile = "lang-snippets/test-imports.noasm",
        .rootfile = "lang-snippets/test-ast.noams",
        .allocator = allocator,
    };

    lexer.tokenize() catch |err| {
        std.debug.print("Lexer error: {s} at line {}\n", .{ @errorName(err), lexer.currLine + 1 });
        return err;
    };

    for (lexer.tokens.items) |tok| {
        const formatted = try tok.toString(allocator);
        defer allocator.free(formatted);
        std.debug.print("{s}", .{formatted});
    }

    var parser = try Parser.init(allocator, lexer.tokens.items);
    const resultingAst = try parser.parse();
    printAst(resultingAst, 0);
}

const std = @import("std");
const Lexer = @import("lexer").Lexer;
const Parser = @import("parser").Parser;
const printAst = @import("parser").printStatementTree;
