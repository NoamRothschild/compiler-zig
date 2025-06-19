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
    // printExpressionTree(expression, 0);
    // try parser.expect(.line_terminator);

    return Statement{
        .Expression = .{ .Expression = expression },
    };
}

pub fn printStatementTree(statement: Statement, base_padding: u32) void {
    const print = std.debug.print;
    const padding = base_padding;
    switch (statement) {
        .Expression => {
            printExpressionTree(statement.Expression.Expression, padding + 2);
        },
        .Scope => {
            var indent_buf: [256]u8 = undefined;
            const indent = indent_buf[0..padding];
            @memset(indent, ' ');
            print("{s}scopeStatement {{\n", .{indent});
            for (statement.Scope.Body) |line| {
                printStatementTree(line, padding + 2);
            }
            print("{s}}}\n", .{indent});
        },
    }
}

fn printExpressionTree(expression: Expression, base_padding: u32) void {
    const print = std.debug.print;
    const padding = base_padding;
    var indent_buf: [256]u8 = undefined;
    const indent = indent_buf[0..padding];
    @memset(indent, ' ');
    print("{s}expressionStatement {{\n", .{indent});
    switch (expression) {
        .Binary => {
            print("{s}binaryExpression {{\n", .{indent});
            print("{s}left: \n", .{indent});
            printExpressionTree(expression.Binary.Left.*, padding + 2);
            print("{s}}},\n", .{indent});

            print("{s}operator: \n", .{indent});
            print("{s} Type: {s}, Value: {s}\n", .{ indent, @tagName(expression.Binary.Operator.Type), expression.Binary.Operator.Data.? });
            print("{s}}},\n", .{indent});

            print("{s}right: \n", .{indent});
            printExpressionTree(expression.Binary.Right.*, padding + 2);
            print("{s}}},\n", .{indent});
        },
        .Number => {
            print("{s}numberExpression {{\n", .{indent});
            print("{s}value: {d}\n", .{ indent, expression.Number.val });
            print("{s}}},\n", .{indent});
        },
        .String => {
            print("{s}stringExpression {{\n", .{indent});
            print("{s}value: {s}\n", .{ indent, expression.String.val });
            print("{s}}},\n", .{indent});
        },
        .Symbol => {
            print("{s}symbolExpression {{\n", .{indent});
            print("{s}value: {s}\n", .{ indent, expression.Symbol.val });
            print("{s}}},\n", .{indent});
        },
    }
    print("{s}}}\n", .{indent});
}
