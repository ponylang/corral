interface tag CmdResultReceiver
  """
  Receives notification when a command completes.
  """

  be cmd_completed()
  """
  Called when the command has finished executing.
  """

primitive NoOpResultReceiver
  """
  A no-op result receiver that discards notifications.
  """

  fun tag cmd_completed() =>
    None
