const statementLookup = @import("lookups.zig").statementLookup;
const nudLookup = @import("lookups.zig").nudLookup;
const ledLookup = @import("lookups.zig").ledLookup;
const bpLookup = @import("lookups.zig").bpLookup;
const BindingPower = @import("lookups.zig").BindingPower;
const Parser = @import("root.zig").Parser;
const Token = @import("lexer").Token;
const TokenType = @import("lexer").TokenType;
const Expression = @import("ast").Expression;
const std = @import("std");

pub fn parseExpression(parser: *Parser, bp: BindingPower) error.IndexOutOfBounds!Expression {
    const tok: Token = try parser.consumeToken();
    const val = nudLookup.?.get(tok.Type);
    if (!val) {
        std.debug.print("nud handler expected for token {s}\n", .{@tagName(tok.Type)});
        unreachable;
    }
    const nudFn = val.?;
    var left = nudFn(parser);

    while (bpLookup.?.get(parser.currentTokenType()).? > bp) {
        const newTok: Token = try parser.currentToken();
        const val2 = ledLookup.?.get(newTok.Type);

        if (!val2) {
            std.debug.print("nud handler expected for token {s}\n", .{@tagName(tok.Type)});
            unreachable;
        }

        const ledFn = val2.?;
        left = ledFn(parser, left, bp);
    }

    return left;
}

pub fn parsePrimaryExpression(parser: *Parser) error.IndexOutOfBounds!Expression {
    const tok: Token = parser.consumeToken() orelse unreachable;
    switch (parser.currentToken()) {
        .number => {
            const num: f64 = std.fmt.parseFloat(f64, tok.Data);
            return Expression{ .Number = .{ .val = num } };
        },
        .string => {
            return Expression{ .String = .{ .val = tok.Data } };
        },
        .identifier => {
            return Expression{ .Symbol = .{ .val = tok.Data } };
        },
        else => {
            std.debug.print(
                \\panic at `src/parser/expression.zig`\n
                \\cannot create primary expression from {s}\n
            , .{@tagName(tok.Type)});
            unreachable;
        },
    }
}

pub fn parseBinaryExpression(parser: *Parser, left: Expression, bp: BindingPower) error.IndexOutOfBounds!Expression {
    const operatorToken: Token = parser.consumeToken() orelse unreachable;
    const right = parseExpression(parser, bp);

    return Expression{ .Binary = .{
        .Left = left,
        .Operator = operatorToken,
        .Right = right,
    } };
}
