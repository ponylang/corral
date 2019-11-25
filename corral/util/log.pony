type LogLevel is
  ( LvlFine
  | LvlInfo
  | LvlWarn
  | LvlErrr
  | LvlNone )

primitive LvlFine
  fun apply(): U32 => 0
  fun string(): String => "FINE"

primitive LvlInfo
  fun apply(): U32 => 1
  fun string(): String => "INFO"

primitive LvlWarn
  fun apply(): U32 => 2
  fun string(): String => "WARN"

primitive LvlErrr
  fun apply(): U32 => 3
  fun string(): String => "ERRR"

primitive LvlNone
  fun apply(): U32 => 4
  fun string(): String => "-"

class val Log
  """
  A wrapped output stream for use in logging. It supports logging at four
  levels: err, warn, info and fine.
  Log level is checked behind the call for convenience at the tradeoff of
  performance. The formatter can also be selected to customize the log line
  content and format.
  """
  let _level: LogLevel
  let _out: OutStream
  let _formatter: LogFormatter

  new val create(
    level: LogLevel,
    out: OutStream,
    formatter: LogFormatter)
  =>
    _level = level
    _out = out
    _formatter = formatter

  fun log(level: LogLevel, msg: String, loc: SourceLoc = __loc) =>
    if (level() >= _level()) then
      _out.print(_formatter(level, msg, loc))
    end

  fun fine(msg: String, loc: SourceLoc = __loc) =>
    log(LvlFine, msg, loc)

  fun info(msg: String, loc: SourceLoc = __loc) =>
    log(LvlInfo, msg, loc)

  fun warn(msg: String, loc: SourceLoc = __loc) =>
    log(LvlWarn, msg, loc)

  fun err(msg: String, loc: SourceLoc = __loc) =>
    log(LvlErrr, msg, loc)

interface val LogFormatter
  fun apply(level: LogLevel, msg: String, loc: SourceLoc): String

primitive CodeLogFormatter is LogFormatter
  fun apply(level: LogLevel, msg: String, loc: SourceLoc): String =>
    let file_name: String = loc.file()
    let file_linenum: String  = loc.line().string()
    let file_linepos: String  = loc.pos().string()
    (recover String(file_name.size()
      + file_linenum.size()
      + file_linepos.size()
      + msg.size()
      + 4)
    end)
     .> append(file_name)
     .> append(":")
     .> append(file_linenum)
     .> append(":")
     .> append(file_linepos)
     .> append(": ")
     .> append(msg)

primitive LevelLogFormatter is LogFormatter
  fun apply(level: LogLevel, msg: String, loc: SourceLoc): String =>
    (recover String(level.string().size()
      + msg.size()
      + 4)
    end)
     .> append(level.string())
     .> append(": ")
     .> append(msg)

primitive SimpleLogFormatter is LogFormatter
  fun apply(level: LogLevel, msg: String, loc: SourceLoc): String =>
    msg
