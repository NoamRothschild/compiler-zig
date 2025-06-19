// const Token = @import("lexer").Token;
const Statement = @import("ast").Statement;
const Expression = @import("ast").Expression;
const std = @import("std");
const BindingPower = @import("lookups.zig").BindingPower;
const Parser = @import("root.zig").Parser;
const lookups = @import("lookups.zig");
const parseExpression = @import("expression.zig").parseExpression;

pub fn parseStatement(parser: *Parser) !Statement {
    const statementLookup = lookups.statementLookup.?;

    if (statementLookup.get(try parser.currentTokenType())) |statementFn| {
        return statementFn(parser);
    }

    const expression = try parseExpression(parser, .default_bp);
    try parser.expect(.line_terminator);

    return Statement{
        .Expression = .{ .Expression = expression },
    };
}

pub fn printStatementTree(statement: Statement, base_padding: u32) void {
    switch (statement) {
        .Expression => {
            printIndented(base_padding, "expressionStatement {{\n", .{});
            printExpressionTree(statement.Expression.Expression, base_padding + 2);
            printIndented(base_padding, "}}\n", .{});
        },
        .Scope => {
            printIndented(base_padding, "scopeStatement {{\n", .{});
            for (statement.Scope.Body) |line| {
                printStatementTree(line, base_padding + 2);
            }
            printIndented(base_padding, "}}\n", .{});
        },
    }
}

pub fn printExpressionTree(expression: Expression, base_padding: u32) void {
    var padding = base_padding;
    switch (expression) {
        .Binary => {
            printIndented(padding, "binaryExpression {{\n", .{});
            padding += 2;
            printIndented(padding, "left: {{\n", .{});
            printExpressionTree(expression.Binary.Left.*, padding + 2);
            printIndented(padding, "}},\n", .{});

            printIndented(padding, "operator: {{\n", .{});
            printIndented(padding + 2, "type: {s}\n", .{@tagName(expression.Binary.Operator.Type)});
            printIndented(padding + 2, "value: {s}\n", .{expression.Binary.Operator.Data.?});
            printIndented(padding, "}},\n", .{});

            printIndented(padding, "right: {{\n", .{});
            printExpressionTree(expression.Binary.Right.*, padding + 2);
            printIndented(padding, "}}\n", .{});
            padding -= 2;
            printIndented(padding, "}}\n", .{});
        },
        .Number => {
            printIndented(padding, "numberExpression {{\n", .{});
            printIndented(padding + 2, "value: {d}\n", .{expression.Number.val});
            printIndented(padding, "}}\n", .{});
        },
        .String => {
            printIndented(padding, "stringExpression {{\n", .{});
            printIndented(padding, "value: {s}\n", .{expression.String.val});
            printIndented(padding, "}},\n", .{});
        },
        .Symbol => {
            printIndented(padding + 2, "symbolExpression {{\n", .{});
            printIndented(padding + 4, "value: {s}\n", .{expression.Symbol.val});
            printIndented(padding, "}},\n", .{});
        },
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
