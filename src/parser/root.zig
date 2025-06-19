const Token = @import("lexer").Token;
const TokenType = @import("lexer").TokenType;
const Statement = @import("ast").Statement;
const Expression = @import("ast").Expression;
const std = @import("std");
const parseStatement = @import("statement.zig").parseStatement;
const Lookups = @import("lookups.zig");
const parseExpression = @import("expression.zig").parseExpression;
const BindingPower = @import("lookups.zig").BindingPower;
const ParserErrors = @import("errors.zig").ParserErrors;
pub const printStatementTree = @import("statement.zig").printStatementTree;
pub const evalExpression = @import("statement.zig").evalExpression;

pub const Parser = struct {
    tokens: []const Token,
    pos: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, tokens: []Token) !Parser {
        try Lookups.initTables(allocator);

        return Parser{
            .tokens = tokens,
            .pos = 0,
            .allocator = allocator,
        };
    }

    pub fn parse(self: *Parser) !Statement {
        // NOTE: we return body.items but the arraylist was never free'ed
        var body = std.ArrayList(Statement).init(self.allocator);

        while (try hasTokens(self)) {
            try body.append(try parseStatement(self));
        }

        // return a scope statement
        return Statement{ .scope = .{
            .body = body.items,
        } };
    }

    pub fn expect(self: *Parser, expectedType: TokenType) ParserErrors!void {
        if (try self.currentTokenType() != expectedType) {
            std.debug.print("Expected {s} token but got {s} instead.\nToken: ", .{ @tagName(expectedType), @tagName(try self.currentTokenType()) });
            (try self.currentToken()).show();
            return ParserErrors.UnexpectedToken;
        } else {
            _ = try self.consumeToken();
        }
    }

    /// returns the current token
    pub fn currentToken(self: *Parser) ParserErrors!Token {
        if (self.pos >= self.tokens.len)
            return error.IndexOutOfBounds;
        return self.tokens[self.pos];
    }

    /// returns the current tokens type
    pub fn currentTokenType(self: *Parser) ParserErrors!TokenType {
        const token = try currentToken(self);
        return token.type;
    }

    /// returns the current token and advances forward
    pub fn consumeToken(self: *Parser) ParserErrors!Token {
        const tok = try currentToken(self);
        self.pos += 1;
        return tok;
    }

    /// returns if we still have tokens remaining to parse
    pub fn hasTokens(self: *Parser) !bool {
        return self.pos < self.tokens.len and (try self.currentTokenType()) != TokenType.end_of_file;
    }
};
