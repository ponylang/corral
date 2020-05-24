interface tag CmdResultReceiver
  be cmd_completed()

primitive NoOpResultReceiver
  fun tag cmd_completed() =>
    None
