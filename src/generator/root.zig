const Statement = @import("ast").Statement;
const Expression = @import("ast").Expression;
const std = @import("std");

pub fn statementToAsm(statement: Statement) void {
    switch (statement) {
        .expression => {
            printIndented(2, "xor eax, eax\n", .{});
            expressionToAsm(statement.expression, "eax");
        },
        .scope => {
            for (statement.scope.body) |line| {
                statementToAsm(line);
            }
        },
    }
}

fn expressionToAsm(expression: Expression, reg: ?*const [3:0]u8) void {
    // TODO: Optimization:
    // - if next thing we do is div or mod, and left && right are number expr && primary of div will not be eax
    //   this would lead to something like
    //   `mov eax, left; mov ebx, right; swap(eax, ebx)` which could just be written as `mov ebx, right, mov eax, left`.
    var register = reg orelse "eax";
    var secondary_register = blk: {
        if (std.mem.eql(u8, register, "eax")) {
            break :blk "ebx";
        } else {
            break :blk "eax";
        }
    };
    switch (expression) {
        .binary => {
            expressionToAsm(expression.binary.left.*, register);
            if (expression.binary.right.* == .number) {
                expressionToAsm(expression.binary.right.*, secondary_register);
            } else {
                printIndented(2, "push {s}\n", .{register});
                expressionToAsm(expression.binary.right.*, secondary_register);
                printIndented(2, "pop {s}\n", .{register});
            }
            switch (expression.binary.operator.type) {
                .plus => {
                    printIndented(2, "add {s}, {s}\n", .{ register, secondary_register });
                },
                .subtract => {
                    printIndented(2, "sub {s}, {s}\n", .{ register, secondary_register });
                },
                .multiply => {
                    if (!std.mem.eql(u8, register, "eax")) {
                        // swapRegisters(&register, &secondary_register);
                        printIndented(2, "imul {s}\n", .{register});
                        // swapRegisters(&register, &secondary_register);
                    } else {
                        printIndented(2, "imul {s}\n", .{secondary_register});
                    }
                },
                .divide => {
                    if (!std.mem.eql(u8, register, "eax")) {
                        swapRegisters(&register, &secondary_register);
                        printIndented(2, "cdq\n  idiv {s}\n", .{secondary_register});
                        // printIndented(2, "mov {s}, eax\n", .{register});
                        swapRegisters(&register, &secondary_register);
                    } else {
                        printIndented(2, "cdq\n  idiv {s}\n", .{secondary_register});
                    }
                },
                .remainder => {
                    if (!std.mem.eql(u8, register, "eax")) {
                        swapRegisters(&register, &secondary_register);
                        printIndented(2, "cdq\n  idiv {s}\n", .{secondary_register});
                        // printIndented(2, "mov {s}, edx\n", .{register});
                        // swapRegisters(&register, &secondary_register);
                        printIndented(2, "mov {s}, edx\n", .{secondary_register});
                        const tmp = register;
                        register = secondary_register;
                        secondary_register = tmp;
                        // Instead of doing
                        // mov second, result
                        // swap first, second
                        //
                        // we can just do
                        // mov first, result
                        // and only swap the compiler variables
                    } else {
                        printIndented(2, "cdq\n  idiv {s}\n", .{secondary_register});
                        printIndented(2, "mov {s}, edx\n", .{register});
                    }
                },
                else => unreachable,
            }
        },
        .number => {
            printIndented(2, "mov {s}, {d}\n", .{ register, expression.number.val });
        },
        else => unreachable,
    }
}

fn swapRegisters(first: **const [3:0]u8, second: **const [3:0]u8) void {
    printIndented(2, "xor {s}, {s}\n  xor {s}, {s}\n  xor {s}, {s}\n", .{ first.*, second.*, second.*, first.*, first.*, second.* });
    const tmp = first.*;
    first.* = second.*;
    second.* = tmp;
}

fn indent(amount: u32) void {
    for (0..amount) |_| {
        std.debug.print(" ", .{});
    }
}

fn printIndented(amount: u32, comptime fmt: []const u8, args: anytype) void {
    indent(amount);
    std.debug.print(fmt, args);
}
