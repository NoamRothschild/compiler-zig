const Expression = @import("root.zig").Expression;
const Token = @import("lexer").Token;

// litteral expressions
pub const NumberExpression = struct { val: f64 };

pub const StringExpression = struct { val: []const u8 };

pub const SymbolExpression = struct { val: []const u8 };

pub const BinaryExpression = struct { Left: *const Expression, Operator: Token, Right: *const Expression };
