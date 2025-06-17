const Expression = @import("root.zig").Expression;
const Token = @import("lexer").Token;

// litteral expressions
pub const NumberExpression = struct { val: f32 };

pub const StringExpression = struct { val: []const u8 };

pub const SymbolExpression = struct { val: []const u8 };

pub const BinaryExpression = struct { Left: Expression, Operator: Token, Right: Expression };
