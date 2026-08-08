interface val LogFormatter
  """
  Interface required to implement custom log formatting.

  * `msg` is the logged message
  * `loc` is the location log was called from

  See `DefaultLogFormatter` for an example of how to
  implement a LogFormatter.
  """
  fun apply(msg: String, loc: SourceLoc): String
    """
    Format a log message.
    """

primitive DefaultLogFormatter is LogFormatter
  """
  Formats log messages as `file:line:pos: message`.
  """
  fun apply(msg: String, loc: SourceLoc): String =>
    """
    Format a log message with source location.
    """
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
