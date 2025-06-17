const std = @import("std");
const Parser = @import("root.zig").Parser;
const Statement = @import("ast").Statement;
const Expression = @import("ast").Expression;
const TokenType = @import("lexer").TokenType;
const Token = @import("lexer").Token;
const ExpressionParsers = @import("expression.zig");

pub const BindingPower = enum(u8) {
    deafult_bp,
    comma,
    assignment,
    logical,
    relational,
    additive,
    multiplicative,
    unary,
    call,
    member,
    primary,
};

const StatementHandler = fn (*Parser) error.IndexOutOfBounds!Statement;
const NudHandler = fn (*Parser) error.IndexOutOfBounds!Expression;
const LedHandler = fn (*Parser, Expression, BindingPower) error.IndexOutOfBounds!Expression;

pub var statementLookup: ?std.AutoHashMap(TokenType, StatementHandler) = null;
pub var nudLookup: ?std.AutoHashMap(TokenType, NudHandler) = null;
pub var ledLookup: ?std.AutoHashMap(TokenType, LedHandler) = null;
pub var bpLookup: ?std.AutoHashMap(TokenType, BindingPower) = null;

fn led(Ttype: TokenType, bp: BindingPower, ledFn: LedHandler) !void {
    try bpLookup.?.put(Ttype, bp);
    try ledLookup.?.put(Ttype, ledFn);
}

fn nud(Ttype: TokenType, bp: BindingPower, nudFn: NudHandler) !void {
    try bpLookup.?.put(Ttype, bp); //TODO: may need to change this one to .primary
    try nudLookup.?.put(Ttype, nudFn);
}

fn statement(Ttype: TokenType, statementFn: StatementHandler) !void {
    try bpLookup.?.put(Ttype, .deafult_bp);
    try statementLookup.?.put(Ttype, statementFn);
}

pub fn initTables(allocator: std.mem.Allocator) !void {
    statementLookup = std.AutoHashMap(TokenType, StatementHandler).init(allocator);
    nudLookup = std.AutoHashMap(TokenType, NudHandler).init(allocator);
    ledLookup = std.AutoHashMap(TokenType, LedHandler).init(allocator);
    bpLookup = std.AutoHashMap(TokenType, BindingPower).init(allocator);

    // logical
    led(.and_, .logical, ExpressionParsers.parseBinaryExpression);
    led(.or_, .logical, ExpressionParsers.parseBinaryExpression);

    // relational
    led(.less, .relational, ExpressionParsers.parseBinaryExpression);
    led(.less_equals, .relational, ExpressionParsers.parseBinaryExpression);
    led(.greater, .relational, ExpressionParsers.parseBinaryExpression);
    led(.greater_equals, .relational, ExpressionParsers.parseBinaryExpression);
    led(.equality_check, .relational, ExpressionParsers.parseBinaryExpression);
    led(.inequality_check, .relational, ExpressionParsers.parseBinaryExpression);

    // additive && multiplicative
    led(.plus, .additive, ExpressionParsers.parseBinaryExpression);
    led(.subtract, .additive, ExpressionParsers.parseBinaryExpression);
    led(.multiply, .multiplicative, ExpressionParsers.parseBinaryExpression);
    led(.divide, .multiplicative, ExpressionParsers.parseBinaryExpression);

    // literals && symbols
    nud(.number, .primary, ExpressionParsers.parsePrimaryExpression);
    nud(.string, .primary, ExpressionParsers.parsePrimaryExpression);
    nud(.identifier, .primary, ExpressionParsers.parsePrimaryExpression);
}
