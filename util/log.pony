
type LogLevel is
  ( Fine
  | Info
  | Warn
  | Error
  )

primitive Fine
  fun apply(): U32 => 0
  fun string(): String => "FINE"

primitive Info
  fun apply(): U32 => 1
  fun string(): String => "INFO"

primitive Warn
  fun apply(): U32 => 2
  fun string(): String => "WARN"

primitive Error
  fun apply(): U32 => 3
  fun string(): String => "ERRO"


class val Log
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
    log(Fine, msg, loc)

  fun info(msg: String, loc: SourceLoc = __loc) =>
    log(Info, msg, loc)

  fun warn(msg: String, loc: SourceLoc = __loc) =>
    log(Warn, msg, loc)

  fun err(msg: String, loc: SourceLoc = __loc) =>
    log(Error, msg, loc)

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
