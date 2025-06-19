const printExpressionTree = @import("statement.zig").printExpressionTree;
const lookups = @import("lookups.zig");
const parserErrors = @import("errors.zig").parserErrors;
const BindingPower = lookups.BindingPower;
const Parser = @import("root.zig").Parser;
const Token = @import("lexer").Token;
const TokenType = @import("lexer").TokenType;
const Expression = @import("ast").Expression;
const std = @import("std");

pub fn parseExpression(parser: *Parser, bp: BindingPower) parserErrors!Expression {
    const tok: Token = try parser.currentToken();
    const nudLookup = lookups.nudLookup;
    const bpLookup = lookups.bpLookup;
    const ledLookup = lookups.ledLookup;
    // std.debug.print("Token {s} ({s}) (will call nud)\n", .{ tok.Data orelse "", @tagName(tok.Type) });

    const val = nudLookup.?.get(tok.Type);
    if (val == null) {
        std.debug.print("nud handler expected for token {s}\n", .{@tagName(tok.Type)});
        unreachable;
    }
    const nudFn = val.?;
    var left = try nudFn(parser);

    while (@intFromEnum(bpLookup.?.get(try parser.currentTokenType()) orelse BindingPower.default_bp) > @intFromEnum(bp)) {
        const newTok: Token = try parser.currentToken();
        const val2 = ledLookup.?.get(newTok.Type);
        // std.debug.print("Token {s} ({s}) (will call led)\n", .{ newTok.Data orelse "", @tagName(newTok.Type) });

        if (val2 == null) {
            std.debug.print("led handler expected for token {s}, {s}\n", .{ @tagName(tok.Type), tok.Data orelse "" });
            unreachable;
        }

        const ledFn = val2.?;
        left = try ledFn(parser, left, bpLookup.?.get(try parser.currentTokenType()).?);
    }

    return left;
}

pub fn parsePrimaryExpression(parser: *Parser) parserErrors!Expression {
    const tok: Token = try parser.consumeToken();
    switch (tok.Type) {
        .number => {
            const num: f64 = std.fmt.parseFloat(f64, tok.Data.?) catch {
                return parserErrors.InvalidFloatConversion;
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
        .Left = &((try parser.Allocator.dupe(Expression, &[_]Expression{left}))[0]),
        .Operator = operatorToken,
        .Right = &((try parser.Allocator.dupe(Expression, &[_]Expression{right}))[0]),
    } };
}
