const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;
const eql = std.mem.eql;
const indexOf = std.mem.indexOf;

pub const TokenType = @import("token.zig").TokenType;
pub const Token = @import("token.zig").Token;
pub const LexerErrors = @import("errors.zig").LexerErrors;

pub const Lexer = struct {
    rootfile: []const u8,
    allocator: std.mem.Allocator,
    filedata: ?[]u8 = null,
    tokens: ?std.ArrayList(Token) = null,
    currLine: u32 = 0,

    pub fn tokenize(self: *Lexer) !void {
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

    pub fn stringHandler(self: *Lexer, start_index: usize) LexerErrors!usize {
        var end_index: usize = start_index + 1;
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

        try self.tokens.?.append(Token{ .Type = .string, .Data = filedata[start_index + 1 .. end_index - 1], .Line = self.currLine });
        return end_index - 1;
    }

    pub fn importHandler(self: *Lexer, start_index: usize) LexerErrors!usize {
        const relEnd = indexOf(u8, self.filedata.?[start_index + 1 ..], " ").?;
        const tokenEnd = relEnd + 1 + start_index;
        const tokenSlice = self.filedata.?[start_index..tokenEnd];

        const importType = TokenType.fromString(tokenSlice);
        if (importType == TokenType.identifier)
            return LexerErrors.UnknownToken;

        try self.tokens.?.append(Token{ .Type = importType, .Data = tokenSlice, .Line = self.currLine });
        return tokenEnd;
    }
};
