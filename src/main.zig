pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var lexer = Lexer{
        // .rootfile = "D:/Projects/ziglang/compiler/lang-snippets/test-ast.noams",
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
    const resultingAst = parser.parse() catch |err| {
        std.debug.print("Parser error: {s}\n", .{@errorName(err)});
        return err;
    };
    printAst(resultingAst, 0);
}

const std = @import("std");
const Lexer = @import("lexer").Lexer;
const Parser = @import("parser").Parser;
const printAst = @import("parser").printStatementTree;
