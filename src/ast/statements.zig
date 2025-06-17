const Statement = @import("root.zig").Statement;
const Expression = @import("root.zig").Expression;

pub const ScopeStatement = struct { Body: []Statement };

pub const ExpressionStatement = struct { Expression: Expression };
