const lookups = @import("lookups.zig");
const parserErrors = lookups.parserErrors;
const BindingPower = lookups.BindingPower;
const Parser = @import("root.zig").Parser;
const Token = @import("lexer").Token;
const TokenType = @import("lexer").TokenType;
const Expression = @import("ast").Expression;
const std = @import("std");

pub fn parseExpression(parser: *Parser, bp: BindingPower) parserErrors!Expression {
    const tok: Token = try parser.consumeToken();
    const nudLookup = lookups.nudLookup;
    const bpLookup = lookups.bpLookup;
    const ledLookup = lookups.ledLookup;

    const val = nudLookup.?.get(tok.Type);
    if (val == null) {
        std.debug.print("nud handler expected for token {s}\n", .{@tagName(tok.Type)});
        unreachable;
    }
    const nudFn = val.?;
    var left = try nudFn(parser);

    while (@intFromEnum(bpLookup.?.get(try parser.currentTokenType()).?) > @intFromEnum(bp)) {
        const newTok: Token = try parser.currentToken();
        const val2 = ledLookup.?.get(newTok.Type);

        if (val2 == null) {
            std.debug.print("nud handler expected for token {s}\n", .{@tagName(tok.Type)});
            unreachable;
        }

        const ledFn = val2.?;
        left = try ledFn(parser, left, bp);
    }

    return left;
}

pub fn parsePrimaryExpression(parser: *Parser) parserErrors!Expression {
    const tok: Token = try parser.currentToken();
    switch (tok.Type) {
        .number => {
            const num: f64 = std.fmt.parseFloat(f64, tok.Data.?) catch {
                return parserErrors.IndexOutOfBounds;
            };
            return Expression{ .Number = .{ .val = num } };
        },
        .string => {
            return Expression{ .String = .{ .val = tok.Data.? } };
        },
        .identifier => {
            return Expression{ .Symbol = .{ .val = tok.Data.? } };
        },
        else => {
            std.debug.print(
                \\panic at `src/parser/expression.zig`
                \\cannot create primary expression from {s}
                \\
            , .{@tagName(tok.Type)});
            unreachable;
        },
    }
}

pub fn parseBinaryExpression(parser: *Parser, left: Expression, bp: BindingPower) parserErrors!Expression {
    const operatorToken: Token = try parser.consumeToken();
    const right = try parseExpression(parser, bp);

    return Expression{ .Binary = .{
        .Left = &left,
        .Operator = operatorToken,
        .Right = &right,
    } };
}
