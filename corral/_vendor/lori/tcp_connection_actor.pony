trait tag TCPConnectionActor is AsioEventNotify
  fun ref _connection(): TCPConnection

  be dispose() =>
    """
    Close connection
    """
    // hard_close() — disposal is unconditional teardown, not graceful shutdown.
    // See #229 for the edge-triggered race that makes close() unreliable here.
    _connection().hard_close()

  be _event_notify(event: AsioEventID, flags: U32, arg: U32) =>
    _connection()._event_notify(event, flags, arg)

  be _read_again() =>
    """
    Resume reading. On POSIX, re-enters the read loop which processes buffered
    data and reads from the socket. On Windows, processes buffered data first
    then submits a new IOCP read.
    """
    _connection().read_again()

  be _register_spawner(listener: TCPListenerActor) =>
    """
    Register the listener as the spawner of this connection
    """
    _connection()._register_spawner(listener)

  be _notify_sent(token: SendToken) =>
    """
    Deferred delivery of _on_sent to the lifecycle event receiver.
    """
    _connection()._fire_on_sent(token)

  be _notify_send_failed(token: SendToken) =>
    """
    Deferred delivery of _on_send_failed to the lifecycle event receiver.
    """
    _connection()._fire_on_send_failed(token)

  be _finish_initialization() =>
    _connection()._finish_initialization()
