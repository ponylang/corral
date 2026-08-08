type LogLevel is
  ( Fine
  | Info
  | Warn
  | Error
  )

primitive Fine
  """
  Finest level of log output.
  """
  fun apply(): U32 => 0

primitive Info
  """
  Informational log level.
  """
  fun apply(): U32 => 1

primitive Warn
  """
  Warning log level.
  """
  fun apply(): U32 => 2

primitive Error
  """
  Error log level.
  """
  fun apply(): U32 => 3
