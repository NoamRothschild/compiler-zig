pub const ANSI = struct {
    pub const black = "\x1b[30m";
    pub const red = "\x1b[31m";
    pub const green = "\x1b[32m";
    pub const yellow = "\x1b[33m";
    pub const blue = "\x1b[34m";
    pub const magenta = "\x1b[35m";
    pub const cyan = "\x1b[36m";
    pub const white = "\x1b[37m";
    pub const reset = "\x1b[0m";

    pub const black_background = "\x1b[40m";
    pub const red_background = "\x1b[41m";
    pub const green_background = "\x1b[42m";
    pub const yellow_background = "\x1b[43m";
    pub const blue_background = "\x1b[44m";
    pub const magenta_background = "\x1b[45m";
    pub const cyan_background = "\x1b[46m";
    pub const white_background = "\x1b[47m";
    pub const reset_background = "\x1b[49m";
};
