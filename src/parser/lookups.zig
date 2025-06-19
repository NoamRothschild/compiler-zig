const std = @import("std");
const Parser = @import("root.zig").Parser;
const Statement = @import("ast").Statement;
const Expression = @import("ast").Expression;
const TokenType = @import("lexer").TokenType;
const Token = @import("lexer").Token;
const ExpressionParsers = @import("expression.zig");
const ParserErrors = @import("errors.zig").ParserErrors;

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

const statementHandler = *const fn (*Parser) ParserErrors!Statement;
const nudHandler = *const fn (*Parser) ParserErrors!Expression;
const ledHandler = *const fn (*Parser, Expression, BindingPower) ParserErrors!Expression;

pub var statement_lookup: ?std.AutoHashMap(TokenType, statementHandler) = null;
pub var nud_lookup: ?std.AutoHashMap(TokenType, nudHandler) = null;
pub var led_lookup: ?std.AutoHashMap(TokenType, ledHandler) = null;
pub var bp_lookup: ?std.AutoHashMap(TokenType, BindingPower) = null;

fn led(Ttype: TokenType, bp: BindingPower, ledFn: ledHandler) !void {
    try bp_lookup.?.put(Ttype, bp);
    try led_lookup.?.put(Ttype, ledFn);
}

fn nud(Ttype: TokenType, bp: BindingPower, nudFn: nudHandler) !void {
    try bp_lookup.?.put(Ttype, bp);
    try nud_lookup.?.put(Ttype, nudFn);
}

fn statement(Ttype: TokenType, statementFn: statementHandler) !void {
    try bp_lookup.?.put(Ttype, .default_bp);
    try statement_lookup.?.put(Ttype, statementFn);
}

pub fn initTables(allocator: std.mem.Allocator) !void {
    statement_lookup = std.AutoHashMap(TokenType, statementHandler).init(allocator);
    nud_lookup = std.AutoHashMap(TokenType, nudHandler).init(allocator);
    led_lookup = std.AutoHashMap(TokenType, ledHandler).init(allocator);
    bp_lookup = std.AutoHashMap(TokenType, BindingPower).init(allocator);

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
