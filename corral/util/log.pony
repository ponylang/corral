use "logger"

primitive DebugLevel
  fun apply(lvl: U64): LogLevel =>
    match lvl
    | 0 => Error
    | 1 => Warn
    | 2 => Info
    | 3 => Fine
    else
      Fine
    end

primitive SimpleLogFormatter is LogFormatter
  fun apply(msg: String, loc: SourceLoc): String =>
    msg
