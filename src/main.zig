pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var parser = lexer.Parser{
        .rootfile = "lang-snippets/test-imports.noasm",
        .allocator = allocator,
    };

    if (parser.parse()) |_| {
        for (parser.tokens.?.items) |tok| {
            std.debug.print("{{ Type: {s}, Data: {s}, Line: {d}, Column: 0 }}\n", .{ lexer.TokenType.strRepr(tok.Type), tok.Data orelse "", tok.Line });
        }
    } else |err| {
        std.debug.print("Lexer error: {s} at line {}\n", .{ @errorName(err), parser.currLine + 1 });
    }
}

const std = @import("std");
const lexer = @import("lexer_lib");
