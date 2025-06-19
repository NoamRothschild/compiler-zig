pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var lexer = Lexer{
        // .rootfile = "D:/Projects/ziglang/compiler/lang-snippets/test-ast.noams",
        .rootfile = "lang-snippets/test-ast.noams",
        .allocator = allocator,
    };

    lexer.tokenize() catch |err| {
        std.debug.print("Lexer error: {s} at line {}\n", .{ @errorName(err), lexer.curr_line + 1 });
        return err;
    };

    for (lexer.tokens.items) |tok| {
        const formatted = try tok.toString(allocator);
        defer allocator.free(formatted);
        std.debug.print("{s}", .{formatted});
    }

    var parser = try Parser.init(allocator, lexer.tokens.items);
    const resulting_ast = parser.parse() catch |err| {
        std.debug.print("Parser error: {s}\n", .{@errorName(err)});
        return err;
    };
    printAst(resulting_ast, 0);
    std.debug.print("{s} = {d}", .{ lexer.filedata orelse "", evalExpression(resulting_ast.scope.body[0].expression) });
}

const std = @import("std");
const Lexer = @import("lexer").Lexer;
const Parser = @import("parser").Parser;
const printAst = @import("parser").printStatementTree;
const evalExpression = @import("parser").evalExpression;
