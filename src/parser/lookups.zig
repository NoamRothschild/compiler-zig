const std = @import("std");
const Parser = @import("root.zig").Parser;
const Statement = @import("ast").Statement;
const Expression = @import("ast").Expression;
const TokenType = @import("lexer").TokenType;
const Token = @import("lexer").Token;
const ExpressionParsers = @import("expression.zig");

pub const BindingPower = enum(u8) {
    default_bp,
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

pub const parserErrors = error{ IndexOutOfBounds, OutOfMemory };
const StatementHandler = *const fn (*Parser) parserErrors!Statement;
const NudHandler = *const fn (*Parser) parserErrors!Expression;
const LedHandler = *const fn (*Parser, Expression, BindingPower) parserErrors!Expression;

pub var statementLookup: ?std.AutoHashMap(TokenType, StatementHandler) = null;
pub var nudLookup: ?std.AutoHashMap(TokenType, NudHandler) = null;
pub var ledLookup: ?std.AutoHashMap(TokenType, LedHandler) = null;
pub var bpLookup: ?std.AutoHashMap(TokenType, BindingPower) = null;

fn led(Ttype: TokenType, bp: BindingPower, ledFn: LedHandler) !void {
    try bpLookup.?.put(Ttype, bp);
    try ledLookup.?.put(Ttype, ledFn);
}

fn nud(Ttype: TokenType, _: BindingPower, nudFn: NudHandler) !void {
    try bpLookup.?.put(Ttype, .primary);
    try nudLookup.?.put(Ttype, nudFn);
}

fn statement(Ttype: TokenType, statementFn: StatementHandler) !void {
    try bpLookup.?.put(Ttype, .default_bp);
    try statementLookup.?.put(Ttype, statementFn);
}

pub fn initTables(allocator: std.mem.Allocator) !void {
    statementLookup = std.AutoHashMap(TokenType, StatementHandler).init(allocator);
    nudLookup = std.AutoHashMap(TokenType, NudHandler).init(allocator);
    ledLookup = std.AutoHashMap(TokenType, LedHandler).init(allocator);
    bpLookup = std.AutoHashMap(TokenType, BindingPower).init(allocator);

    // logical
    try led(.and_, .logical, ExpressionParsers.parseBinaryExpression);
    try led(.or_, .logical, ExpressionParsers.parseBinaryExpression);

    // relational
    try led(.less, .relational, ExpressionParsers.parseBinaryExpression);
    try led(.less_equals, .relational, ExpressionParsers.parseBinaryExpression);
    try led(.greater, .relational, ExpressionParsers.parseBinaryExpression);
    try led(.greater_equals, .relational, ExpressionParsers.parseBinaryExpression);
    try led(.equality_check, .relational, ExpressionParsers.parseBinaryExpression);
    try led(.inequality_check, .relational, ExpressionParsers.parseBinaryExpression);

    // additive && multiplicative
    try led(.plus, .additive, ExpressionParsers.parseBinaryExpression);
    try led(.subtract, .additive, ExpressionParsers.parseBinaryExpression);
    try led(.multiply, .multiplicative, ExpressionParsers.parseBinaryExpression);
    try led(.divide, .multiplicative, ExpressionParsers.parseBinaryExpression);

    // literals && symbols
    try nud(.number, .primary, ExpressionParsers.parsePrimaryExpression);
    try nud(.string, .primary, ExpressionParsers.parsePrimaryExpression);
    try nud(.identifier, .primary, ExpressionParsers.parsePrimaryExpression);
}
