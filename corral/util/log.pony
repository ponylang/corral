use "logger"

primitive SimpleLogFormatter is LogFormatter
  fun apply(msg: String, loc: SourceLoc): String =>
    msg
