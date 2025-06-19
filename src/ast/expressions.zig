const Token = @import("lexer").Token;

pub const ExpressionNode = union(enum) {
    number: NumberExpression,
    string: StringExpression,
    symbol: SymbolExpression,
    binary: BinaryExpression,
};

// litteral expressions
pub const NumberExpression = struct { val: f64 };

pub const StringExpression = struct { val: []const u8 };

pub const SymbolExpression = struct { val: []const u8 };

pub const BinaryExpression = struct { left: *const ExpressionNode, operator: Token, right: *const ExpressionNode };
