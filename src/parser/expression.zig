const printExpressionTree = @import("statement.zig").printExpressionTree;
const lookups = @import("lookups.zig");
const ParserErrors = @import("errors.zig").ParserErrors;
const BindingPower = lookups.BindingPower;
const Parser = @import("root.zig").Parser;
const Token = @import("lexer").Token;
const TokenType = @import("lexer").TokenType;
const Expression = @import("ast").Expression;
const std = @import("std");

pub fn parseExpression(parser: *Parser, bp: BindingPower) ParserErrors!Expression {
    const tok: Token = try parser.currentToken();
    const nud_lookup = lookups.nud_lookup;
    const bp_lookup = lookups.bp_lookup;
    const led_lookup = lookups.led_lookup;
    // std.debug.print("Token {s} ({s}) (will call nud)\n", .{ tok.data orelse "", @tagName(tok.type) });

    const val = nud_lookup.?.get(tok.type);
    if (val == null) {
        std.debug.print("nud handler expected for token {s}\n", .{@tagName(tok.type)});
        unreachable;
    }
    const nudFn = val.?;
    var left = try nudFn(parser);

    while (@intFromEnum(bp_lookup.?.get(try parser.currentTokenType()) orelse BindingPower.default_bp) > @intFromEnum(bp)) {
        const new_tok: Token = try parser.currentToken();
        const val2 = led_lookup.?.get(new_tok.type);
        // std.debug.print("Token {s} ({s}) (will call led)\n", .{ new_tok.data orelse "", @tagName(new_tok.type) });

        if (val2 == null) {
            std.debug.print("led handler expected for token {s}, {s}\n", .{ @tagName(tok.type), tok.data orelse "" });
            unreachable;
        }

        const ledFn = val2.?;
        left = try ledFn(parser, left, bp_lookup.?.get(new_tok.type).?);
    }

    return left;
}

pub fn parsePrimaryExpression(parser: *Parser) ParserErrors!Expression {
    const tok: Token = try parser.consumeToken();
    switch (tok.type) {
        .number => {
            const num: f64 = std.fmt.parseFloat(f64, tok.data.?) catch {
                return ParserErrors.InvalidFloatConversion;
            };
            return Expression{ .number = .{ .val = num } };
        },
        .string => {
            return Expression{ .string = .{ .val = tok.data.? } };
        },
        .identifier => {
            return Expression{ .symbol = .{ .val = tok.data.? } };
        },
        .open_args => {
            const left = try parseExpression(parser, .default_bp);
            try parser.expect(.end_args);
            return left;
        },
        else => {
            std.debug.print(
                \\panic at `src/parser/expression.zig`
                \\cannot create primary expression from {s}
                \\
            , .{@tagName(tok.type)});
            unreachable;
        },
    }
}

pub fn parseBinaryExpression(parser: *Parser, left: Expression, bp: BindingPower) ParserErrors!Expression {
    const operator_token: Token = try parser.consumeToken();
    const right = try parseExpression(parser, bp);

    return Expression{ .binary = .{
        .left = &((try parser.allocator.dupe(Expression, &[_]Expression{left}))[0]),
        .operator = operator_token,
        .right = &((try parser.allocator.dupe(Expression, &[_]Expression{right}))[0]),
    } };
}
