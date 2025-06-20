const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;
const eql = std.mem.eql;
const indexOf = std.mem.indexOf;

pub const TokenType = @import("token.zig").TokenType;
pub const Token = @import("token.zig").Token;
pub const LexerErrors = @import("errors.zig").LexerErrors;

pub const Lexer = struct {
    rootfile: []const u8 = undefined,
    allocator: std.mem.Allocator,
    filedata: ?[]const u8 = null,
    force_file: bool = true,
    tokens: std.ArrayList(Token) = undefined,
    curr_line: u32 = 0,
    index: usize = 0,

    pub fn tokenize(self: *Lexer) !void {
        if (self.force_file) {
            const file = try std.fs.cwd().openFile(self.rootfile, .{});
            defer file.close();
            self.filedata = try file.readToEndAlloc(self.allocator, std.math.maxInt(usize));
        }
        self.tokens = ArrayList(Token).init(self.allocator);

        const filedata = self.filedata.?;
        var char: u8 = undefined;
        while (self.index < filedata.len) : (self.index += 1) {
            char = filedata[self.index];
            switch (char) {
                '"' => try stringHandler(self),
                '@' => try importHandler(self),
                32, 9 => undefined, // ignore spaces and tabs
                '+', '!', '-', '*', '/', '%', '=' => try symbolHandler(self),
                'a'...'z', 'A'...'Z', '_' => try identifierHandler(self),
                '0'...'9' => try numberHandler(self),
                ';' => try addToken(self, .line_terminator, null),
                '(' => try addToken(self, .open_args, null),
                ')' => try addToken(self, .end_args, null),
                '\r' => if (filedata[self.index + 1] == '\n') {
                    self.curr_line += 1;
                    self.index += 1;
                },
                '\n' => self.curr_line += 1,
                else => std.debug.print("Unknown token type: {c}, ord: {d}\n", .{ char, char }),
            }
        }
        try addToken(self, .end_of_file, null);
    }

    pub fn addToken(self: *Lexer, Type: TokenType, Data: ?[]const u8) LexerErrors!void {
        try self.tokens.append(Token{ .type = Type, .data = Data, .line = self.curr_line });
    }

    pub fn identifierHandler(self: *Lexer) LexerErrors!void {
        var end_index: usize = self.index + 1;
        const filedata = self.filedata.?;

        while ((filedata[end_index] != ' ') and (filedata[end_index] != ';')) : (end_index += 1) {
            if (end_index + 1 >= filedata.len)
                break;
        }

        var identifier = filedata[self.index..end_index];
        if (eql(u8, identifier, "section")) {
            while (filedata[end_index] != ':') : (end_index += 1) {
                if (end_index + 1 >= filedata.len)
                    break;
            }
            end_index += 1;
            identifier = filedata[self.index..end_index];
        }

        try addToken(self, TokenType.fromString(identifier), identifier);
        self.index = end_index - 1;
    }

    pub fn symbolHandler(self: *Lexer) LexerErrors!void {
        var end_index: usize = self.index + 1;
        const filedata = self.filedata.?;

        if (self.index + 1 < filedata.len) {
            if (switch (filedata[self.index + 1]) {
                '+', '-', '=' => true,
                else => false,
            }) {
                end_index += 1;
            }
        }
        const operator = filedata[self.index..end_index];
        const operator_type = try TokenType.operatorFromString(operator);
        try addToken(self, operator_type, operator);
        self.index = end_index - 1;
    }

    pub fn numberHandler(self: *Lexer) LexerErrors!void {
        var end_index: usize = self.index;
        const filedata = self.filedata.?;

        while ((end_index + 1 < filedata.len) and
            (std.ascii.isDigit(filedata[end_index + 1]) or filedata[end_index + 1] == '.'))
        {
            end_index += 1;
        }

        const num = filedata[self.index .. end_index + 1];

        try addToken(self, .number, num);
        self.index = end_index;
    }

    pub fn stringHandler(self: *Lexer) LexerErrors!void {
        var end_index: usize = self.index + 1;
        const filedata = self.filedata.?;

        while (!((filedata[end_index] == '"') and (filedata[end_index - 1] != '\\'))) : (end_index += 1) {
            if (filedata[end_index] == '\r' or
                filedata[end_index] == '\n' or
                end_index + 1 >= filedata.len)
            {
                return LexerErrors.UnterminatedString;
            }
        }
        end_index += 1;

        try addToken(self, .string, filedata[self.index + 1 .. end_index - 1]);
        self.index = end_index - 1;
    }

    pub fn importHandler(self: *Lexer) LexerErrors!void {
        const start_index: usize = self.index;
        const rel_end = indexOf(u8, self.filedata.?[start_index + 1 ..], " ").?;
        const token_end = rel_end + 1 + start_index;
        const token_slice = self.filedata.?[start_index..token_end];

        const import_type = TokenType.fromString(token_slice);
        if (import_type == TokenType.identifier)
            return LexerErrors.UnknownToken;

        try addToken(self, import_type, token_slice);
        self.index = token_end;
    }
};

// lets leave it here until I figure out how to make this system work 0-0
//
// test "std imports" {
//     const allocator = testing.allocator;
//     const fileData =
//         \\@std.import "common/general.asm";
//         \\@rel.import "common/debug.asm";
//         \\
//     ;
//     var lexer = Lexer{ .allocator = allocator, .forceFile = false, .filedata = fileData[0..] };
//     var expected = std.ArrayList(Token).init(allocator);
//     defer expected.deinit();
//     try expected.append(Token{ .type = .import_std, .data = "@std.import", .line = 1 });
//     try expected.append(Token{ .type = .string, .data = "common/general.asm", .line = 1 });
//     try expected.append(Token{ .type = .line_terminator, .line = 1 });
//     try expected.append(Token{ .type = .import_relative, .data = "@rel.import", .line = 2 });
//     try expected.append(Token{ .type = .string, .data = "common/debug.asm", .line = 2 });
//     try expected.append(Token{ .type = .line_terminator, .line = 2 });

//     lexer.tokenize() catch |err| {
//         std.debug.print("Lexer error: {s} at line {}\n", .{ @errorName(err), lexer.curr_line + 1 });
//         return err;
//     };

//     for (lexer.tokens.items) |tok| {
//         const formatted = try tok.toString(allocator);
//         defer allocator.free(formatted);
//         std.debug.print("{s}", .{formatted});
//     }

//     defer lexer.tokens.deinit();
//     try testing.expect(std.mem.eql(Token, expected.items[0..], lexer.tokens.items[0..]));
// }
