const Token = @import("lexer").Token;
const TokenType = @import("lexer").TokenType;
const Statement = @import("ast").Statement;
const Expression = @import("ast").Expression;
const std = @import("std");
const parseStatement = @import("statement.zig").parseStatement;
const Lookups = @import("lookups.zig");
const parseExpression = @import("expression.zig").parseExpression;
const BindingPower = @import("lookups.zig").BindingPower;
const parserErrors = @import("lookups.zig").parserErrors;

pub const Parser = struct {
    Tokens: []const Token,
    Pos: usize,
    Allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, tokens: []Token) !Parser {
        try Lookups.initTables(allocator);

        return Parser{
            .Tokens = tokens,
            .Pos = 0,
            .Allocator = allocator,
        };
    }

    pub fn parse(self: *Parser) !Statement {
        _ = try parseExpression(self, .deafult_bp);

        // NOTE: we return body.items but the arraylist was never free'ed
        const Body = std.ArrayList(Statement).init(self.Allocator);

        // while (try hasTokens(self)) {
        //     try Body.append(parseStatement(self));
        // }

        // return a scope statement
        return Statement{ .Scope = .{
            .Body = Body.items,
        } };
    }

    /// returns the current token
    pub fn currentToken(self: *Parser) parserErrors!Token {
        if (self.Pos >= self.Tokens.len)
            return error.IndexOutOfBounds;
        return self.Tokens[self.Pos];
    }

    /// returns the current tokens type
    pub fn currentTokenType(self: *Parser) parserErrors!TokenType {
        const token = try currentToken(self);
        return token.Type;
    }

    /// returns the current token and advances forward
    pub fn consumeToken(self: *Parser) parserErrors!Token {
        const tok = try currentToken(self);
        self.Pos += 1;
        return tok;
    }

    /// returns if we still have tokens remaining to parse
    pub fn hasTokens(self: *Parser) !bool {
        return self.Pos < self.Tokens.len;
    }
};
