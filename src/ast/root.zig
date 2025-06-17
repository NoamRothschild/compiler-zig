const ExpressionTypes = @import("expressions.zig");
const StatementTypes = @import("statements.zig");

pub const Statement = union(enum) {
    Scope: StatementTypes.ScopeStatement,
    Expression: StatementTypes.ExpressionStatement,
};

pub const Expression = union(enum) {
    Number: ExpressionTypes.NumberExpression,
    String: ExpressionTypes.StringExpression,
    Symbol: ExpressionTypes.SymbolExpression,
    Binary: ExpressionTypes.BinaryExpression,
};
