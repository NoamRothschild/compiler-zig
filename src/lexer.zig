const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;
const eql = std.mem.eql;
const indexOf = std.mem.indexOf;

const ParserErrors = error{ UnterminatedString, UnknownToken };

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

    pub fn strRepr(tok: TokenType) []const u8 {
        return switch (tok) {
            .import_std => "import_std",
            .import_relative => "import_relative",
            .data_section => "data_section",
            .bss_section => "bss_section",
            .constant_declare => "constant_declare",
            .byte_declare => "byte_declare",
            .word_declare => "word_declare",
            .dword_declare => "dword_declare",
            .function_declare => "function_declare",
            .open_scope => "open_scope",
            .end_scope => "end_scope",
            .line_terminator => "line_terminator",
            .identifier => "identifier",
            .string => "string",
        };
    }
};

pub const Token = struct { Type: TokenType, Data: ?[]const u8 = null, Line: u32 = 0, Column: u32 = 0 };

// fn getToken(buffer: []u8, index: usize) !Token {
//     if std.ascii.isAlphabetic(c: u8)
// }

pub const Parser = struct {
    rootfile: []const u8,
    allocator: std.mem.Allocator,
    filedata: ?[]u8 = null,
    tokens: ?std.ArrayList(Token) = null,
    currLine: u32 = 0,

    pub fn parse(self: *Parser) !void {
        const file = try std.fs.cwd().openFile(self.rootfile, .{});
        defer file.close();
        self.filedata = try file.readToEndAlloc(self.allocator, std.math.maxInt(usize));
        self.tokens = ArrayList(Token).init(self.allocator);

        const filedata = self.filedata.?;
        var i: usize = 0;
        var char: u8 = undefined;
        while (i < filedata.len) : (i += 1) {
            char = filedata[i];
            i = switch (char) {
                '"' => try stringHandler(self, i),
                '@' => try importHandler(self, i),
                32, 9 => i, // ignore spaces and tabs
                // 'a'...'z', 'A'...'Z' => std.debug.print("{any}\n", .{i}),
                ';' => blk: {
                    try self.tokens.?.append(Token{ .Type = .line_terminator, .Line = self.currLine });
                    break :blk i;
                },
                '\r' => blk1: {
                    if (filedata[i + 1] == '\n') {
                        self.currLine += 1;
                        break :blk1 i + 1;
                    }
                    break :blk1 i;
                },
                '\n' => blk2: {
                    self.currLine += 1;
                    break :blk2 i;
                },
                else => blk3: {
                    std.debug.print("Unknown token type: {c}, ord: {d}\n", .{ char, char });
                    break :blk3 i;
                },
            };
        }

        return;
    }

    pub fn stringHandler(self: *Parser, start_index: usize) !usize {
        var end_index: usize = start_index + 1;
        const filedata = self.filedata.?;

        while (!((filedata[end_index] == '"') and (filedata[end_index - 1] != '\\'))) : (end_index += 1) {
            if (filedata[end_index] == '\r' or
                filedata[end_index] == '\n' or
                end_index + 1 >= filedata.len)
            {
                return ParserErrors.UnterminatedString;
            }
        }
        end_index += 1;

        try self.tokens.?.append(Token{ .Type = .string, .Data = filedata[start_index + 1 .. end_index - 1], .Line = self.currLine });
        return end_index - 1;
    }

    pub fn importHandler(self: *Parser, start_index: usize) !usize {
        const relEnd = indexOf(u8, self.filedata.?[start_index + 1 ..], " ").?;
        const tokenEnd = relEnd + 1 + start_index;
        const tokenSlice = self.filedata.?[start_index..tokenEnd];

        const importType = TokenType.fromString(tokenSlice);
        if (importType == TokenType.identifier)
            return ParserErrors.UnknownToken;

        try self.tokens.?.append(Token{ .Type = importType, .Data = tokenSlice, .Line = self.currLine });
        return tokenEnd;
    }
};
