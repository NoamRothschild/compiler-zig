// const Token = @import("lexer").Token;
const Statement = @import("ast").Statement;
const Expression = @import("ast").Expression;
const std = @import("std");
const BindingPower = @import("lookups.zig").BindingPower;
const Parser = @import("root.zig").Parser;
const lookups = @import("lookups.zig");
const parseExpression = @import("expression.zig").parseExpression;

pub fn parseStatement(parser: *Parser) !Statement {
    const statement_lookup = lookups.statement_lookup.?;

    if (statement_lookup.get(try parser.currentTokenType())) |statementFn| {
        return statementFn(parser);
    }

    const expression = try parseExpression(parser, .default_bp);
    try parser.expect(.line_terminator);

    return Statement{
        .expression = expression,
    };
}

pub fn printStatementTree(statement: Statement, base_padding: u32) void {
    switch (statement) {
        .expression => {
            printIndented(base_padding, "expressionStatement {{\n", .{});
            printExpressionTree(statement.expression, base_padding + 2);
            printIndented(base_padding, "}}\n", .{});
        },
        .scope => {
            printIndented(base_padding, "scopeStatement {{\n", .{});
            for (statement.scope.body) |line| {
                printStatementTree(line, base_padding + 2);
            }
            printIndented(base_padding, "}}\n", .{});
        },
    }
}

pub fn printExpressionTree(expression: Expression, base_padding: u32) void {
    var padding = base_padding;
    switch (expression) {
        .binary => {
            printIndented(base_padding, "binaryExpression {{\n", .{});
            padding += 2;
            printIndented(padding, "left: {{\n", .{});
            printExpressionTree(expression.binary.left.*, padding + 2);
            printIndented(padding, "}},\n", .{});

            printIndented(padding, "operator: {{\n", .{});
            printIndented(padding + 2, "type: {s}\n", .{@tagName(expression.binary.operator.type)});
            printIndented(padding + 2, "value: {s}\n", .{expression.binary.operator.data.?});
            printIndented(padding, "}},\n", .{});

            printIndented(padding, "right: {{\n", .{});
            printExpressionTree(expression.binary.right.*, padding + 2);
            printIndented(padding, "}}\n", .{});
            printIndented(base_padding, "}}\n", .{});
        },
        .number => {
            printIndented(base_padding, "numberExpression {{\n", .{});
            printIndented(padding + 2, "value: {d}\n", .{expression.number.val});
            printIndented(base_padding, "}}\n", .{});
        },
        .string => {
            printIndented(base_padding, "stringExpression {{\n", .{});
            printIndented(padding, "value: {s}\n", .{expression.string.val});
            printIndented(base_padding, "}},\n", .{});
        },
        .symbol => {
            printIndented(base_padding + 2, "symbolExpression {{\n", .{});
            printIndented(padding + 4, "value: {s}\n", .{expression.symbol.val});
            printIndented(base_padding, "}},\n", .{});
        },
    }
}

pub fn evalExpression(expression: Expression) f64 {
    switch (expression) {
        .binary => {
            const left = evalExpression(expression.binary.left.*);
            const right = evalExpression(expression.binary.right.*);
            return switch (expression.binary.operator.type) {
                .plus => left + right,
                .subtract => left - right,
                .multiply => left * right,
                .divide => left / right,
                else => unreachable,
            };
        },
        .number => {
            return expression.number.val;
        },
        else => unreachable,
    }
}

fn indent(amount: u32) void {
    for (0..amount) |_| {
        std.debug.print(" ", .{});
    }
}

fn printIndented(amount: u32, comptime fmt: []const u8, args: anytype) void {
    indent(amount);
    std.debug.print(fmt, args);
}
