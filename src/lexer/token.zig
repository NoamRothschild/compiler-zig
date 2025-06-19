pub const TokenType = enum {
    import_std,
    import_relative,
    data_section,
    bss_section,
    constant_declare, // `equ` in asm
    byte_declare,
    word_declare,
    dword_declare,
    function_declare,
    open_scope,
    end_scope,
    open_args,
    end_args,
    line_terminator,
    identifier,
    stack_variable,
    plus,
    plus_equals,
    increment,
    subtract,
    subtract_equals,
    decrement,
    multiply,
    multiply_equals,
    divide,
    divide_equals,
    assign,
    equality_check,
    inequality_check,
    number,
    and_,
    or_,
    less,
    less_equals,
    greater,
    greater_equals,

    // TODO: ADD BELLOW TO NEXT FUNCTIONS
    string,

    // for identifiers
    pub fn fromString(str: []const u8) TokenType {
        const tokens = [_]struct { []const u8, TokenType }{
            .{ "@std.import", .import_std },
            .{ "@rel.import", .import_relative },
            .{ "section .data:", .data_section },
            .{ "section .bss:", .bss_section },
            .{ "const", .constant_declare },
            .{ "byte", .byte_declare },
            .{ "word", .word_declare },
            .{ "dword", .dword_declare },
            .{ "let", .stack_variable },
            .{ "fn", .function_declare },
        };

        for (tokens) |pair| {
            if (std.mem.eql(u8, pair[0], str)) {
                return pair[1];
            }
        }
        return .identifier;
    }

    pub fn operatorFromString(str: []const u8) LexerErrors!TokenType {
        const tokens = [_]struct { []const u8, TokenType }{
            .{ "+", .plus },
            .{ "+=", .plus_equals },
            .{ "++", .increment },
            .{ "-", .subtract },
            .{ "-=", .subtract_equals },
            .{ "--", .decrement },
            .{ "*", .multiply },
            .{ "*=", .multiply_equals },
            .{ "/", .divide },
            .{ "/=", .divide_equals },
            .{ "=", .assign },
            .{ "==", .equality_check },
            .{ "!=", .inequality_check },
            .{ "<", .less },
            .{ "<=", .less_equals },
            .{ ">", .greater },
            .{ ">=", .greater_equals },
            .{ "&&", .and_ },
            .{ "||", .or_ },
        };

        for (tokens) |pair| {
            if (std.mem.eql(u8, pair[0], str)) {
                return pair[1];
            }
        }
        return LexerErrors.UnknownIdentifier;
    }
};

pub const Token = struct {
    Type: TokenType,
    Data: ?[]const u8 = null,
    Line: u32 = 0,
    Column: u32 = 0,

    pub fn toString(self: *const Token, allocator: std.mem.Allocator) LexerErrors![]const u8 {
        // return allocPrint(allocator, "{{ Type: {s}, Data: {s}, Line: {d}, Column: 0 }}\n", .{ @tagName(self.Type), self.Data orelse "", self.Line + 1 });
        return allocPrint(allocator, "{s}: {s} ({d},0)\n", .{ @tagName(self.Type), self.Data orelse "", self.Line + 1 });
    }

    pub fn show(self: *const Token) void {
        std.debug.print("{s}: {s} ({d},0)\n", .{ @tagName(self.Type), self.Data orelse "", self.Line + 1 });
    }
};

const std = @import("std");
const allocPrint = std.fmt.allocPrint;
const LexerErrors = @import("errors.zig").LexerErrors;
