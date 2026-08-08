use "../logger"

primitive DebugLevel
  """
  Converts a numeric debug level to a LogLevel.
  """

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
  """
  A log formatter that passes messages through unchanged.
  """

  fun apply(msg: String, loc: SourceLoc): String =>
    msg
