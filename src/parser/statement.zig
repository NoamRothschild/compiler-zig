// const Token = @import("lexer").Token;
const Statement = @import("ast").Statement;
// const Expression = @import("ast").Expression;
// const std = @import("std");
const Parser = @import("root.zig").Parser;

pub fn parseStatement(parser: *Parser) !Statement {
    _ = parser;
    return error{notImplemented};
}
