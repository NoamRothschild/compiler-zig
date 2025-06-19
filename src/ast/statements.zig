const Expression = @import("root.zig").Expression;

pub const StatementNode = union(enum) {
    scope: ScopeStatement,
    expression: Expression,
};

pub const ScopeStatement = struct { body: []StatementNode };
