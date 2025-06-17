pub const LexerErrors = error{
    UnterminatedString,
    UnknownToken,
    InvalidImport,
    FileError,
    OutOfMemory,
    UnknownIdentifier,
};
