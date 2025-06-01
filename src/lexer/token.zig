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
    line_terminator,
    identifier,
    // TODO: ADD BELLOW TO NEXT FUNCTIONS
    string,

    pub fn fromString(str: []const u8) TokenType {
        const tokens = [_]struct { []const u8, TokenType }{
            .{ "@std.import", .import_std },
            .{ "@rel.import", .import_relative },
            .{ "section .data", .data_section },
            .{ "section .bss", .bss_section },
            .{ "const", .constant_declare },
            .{ "byte", .byte_declare },
            .{ "word", .word_declare },
            .{ "dword", .dword_declare },
            .{ "fn", .function_declare },
            .{ "{", .open_scope },
            .{ "}", .end_scope },
            .{ ";", .line_terminator },
        };

        for (tokens) |pair| {
            if (std.mem.eql(u8, pair[0], str)) {
                return pair[1];
            }
        }
        return .identifier;
    }
};

pub const Token = struct {
    Type: TokenType,
    Data: ?[]const u8 = null,
    Line: u32 = 0,
    Column: u32 = 0,

    pub fn toString(self: *const Token, allcator: std.mem.Allocator) LexerErrors![]const u8 {
        return allocPrint(allcator, "{{ Type: {s}, Data: {s}, Line: {d}, Column: 0 }}\n", .{ @tagName(self.Type), self.Data orelse "", self.Line });
    }
};

const std = @import("std");
const allocPrint = std.fmt.allocPrint;
const LexerErrors = @import("errors.zig").LexerErrors;
