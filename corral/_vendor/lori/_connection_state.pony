use "ssl/net"

trait _ConnectionState
  fun ref own_event(conn: TCPConnection ref, flags: U32, arg: U32)
  fun ref foreign_event(conn: TCPConnection ref, event: AsioEventID,
    flags: U32, arg: U32)
  fun ref send(conn: TCPConnection ref,
    data: (ByteSeq | ByteSeqIter)): (SendToken | SendError)
  fun ref close(conn: TCPConnection ref)
  fun ref hard_close(conn: TCPConnection ref)
  fun ref start_tls(conn: TCPConnection ref, ssl_ctx: SSLContext val,
    host: String): (None | StartTLSError)
  fun ref read_again(conn: TCPConnection ref)
  fun ref ssl_handshake_complete(conn: TCPConnection ref,
    s: EitherLifecycleEventReceiver ref)
  fun is_open(): Bool
  fun is_closed(): Bool
  fun sends_allowed(): Bool

class _ConnectionNone is _ConnectionState
  fun ref own_event(conn: TCPConnection ref, flags: U32, arg: U32) =>
    _Unreachable()

  fun ref foreign_event(conn: TCPConnection ref, event: AsioEventID,
    flags: U32, arg: U32)
  =>
    if not (AsioEvent.writeable(flags) or AsioEvent.readable(flags)) then
      return
    end

    // The message flags and the event struct's disposable status can
    // disagree: a stale message may carry writeable/readable flags while
    // the event struct has already been marked disposable by a prior
    // unsubscribe. Check the struct before unsubscribing.
    if not PonyAsio.get_disposable(event) then
      PonyAsio.unsubscribe(event)
    end
    PonyTCP.close(PonyAsio.event_fd(event))

  fun ref send(conn: TCPConnection ref,
    data: (ByteSeq | ByteSeqIter)): (SendToken | SendError)
  =>
    _Unreachable()
    SendErrorNotConnected

  fun ref close(conn: TCPConnection ref) =>
    _Unreachable()

  fun ref hard_close(conn: TCPConnection ref) =>
    _Unreachable()

  fun ref start_tls(conn: TCPConnection ref, ssl_ctx: SSLContext val,
    host: String): (None | StartTLSError)
  =>
    _Unreachable()
    StartTLSNotConnected

  fun ref read_again(conn: TCPConnection ref) =>
    _Unreachable()

  fun ref ssl_handshake_complete(conn: TCPConnection ref,
    s: EitherLifecycleEventReceiver ref)
  =>
    _Unreachable()

  fun is_open(): Bool => false
  fun is_closed(): Bool => false
  fun sends_allowed(): Bool => false

class _ClientConnecting is _ConnectionState
  fun ref own_event(conn: TCPConnection ref, flags: U32, arg: U32) =>
    _Unreachable()

  fun ref foreign_event(conn: TCPConnection ref, event: AsioEventID,
    flags: U32, arg: U32)
  =>
    if not (AsioEvent.writeable(flags) or AsioEvent.readable(flags)) then
      return
    end

    let fd = PonyAsio.event_fd(event)
    conn._decrement_inflight()

    if conn._is_socket_connected(fd) then
      conn._establish_connection(event, fd)
    else
      conn._connecting_event_failed(event, fd)
    end

  fun ref send(conn: TCPConnection ref,
    data: (ByteSeq | ByteSeqIter)): (SendToken | SendError)
  =>
    SendErrorNotConnected

  fun ref close(conn: TCPConnection ref) =>
    conn._set_state(_UnconnectedClosing)

  fun ref hard_close(conn: TCPConnection ref) =>
    conn._set_state(_Closed)
    conn._hard_close_connecting()

  fun ref start_tls(conn: TCPConnection ref, ssl_ctx: SSLContext val,
    host: String): (None | StartTLSError)
  =>
    StartTLSNotConnected

  fun ref read_again(conn: TCPConnection ref) =>
    None

  fun ref ssl_handshake_complete(conn: TCPConnection ref,
    s: EitherLifecycleEventReceiver ref)
  =>
    _Unreachable()

  fun is_open(): Bool => false
  fun is_closed(): Bool => false
  fun sends_allowed(): Bool => false

class _Open is _ConnectionState
  fun ref own_event(conn: TCPConnection ref, flags: U32, arg: U32) =>
    conn._dispatch_io_event(flags, arg)

  fun ref foreign_event(conn: TCPConnection ref, event: AsioEventID,
    flags: U32, arg: U32)
  =>
    // Removing this guard causes the test suite to hang.
    if PonyAsio.get_disposable(event) then return end
    if not (AsioEvent.writeable(flags) or AsioEvent.readable(flags)) then
      return
    end

    // Happy Eyeballs straggler — clean up
    conn._decrement_inflight()
    conn._straggler_cleanup(event)

  fun ref send(conn: TCPConnection ref,
    data: (ByteSeq | ByteSeqIter)): (SendToken | SendError)
  =>
    conn._do_send(data)

  fun ref close(conn: TCPConnection ref) =>
    conn._set_state(_Closing)
    conn._initiate_shutdown()

  fun ref hard_close(conn: TCPConnection ref) =>
    conn._set_state(_Closed)
    conn._hard_close_connected()

  fun ref start_tls(conn: TCPConnection ref, ssl_ctx: SSLContext val,
    host: String): (None | StartTLSError)
  =>
    conn._do_start_tls(ssl_ctx, host)

  fun ref read_again(conn: TCPConnection ref) =>
    conn._do_read_again()

  fun ref ssl_handshake_complete(conn: TCPConnection ref,
    s: EitherLifecycleEventReceiver ref)
  =>
    _Unreachable()

  fun is_open(): Bool => true
  fun is_closed(): Bool => false
  fun sends_allowed(): Bool => true

class _Closing is _ConnectionState
  fun ref own_event(conn: TCPConnection ref, flags: U32, arg: U32) =>
    conn._dispatch_io_event(flags, arg)

  fun ref foreign_event(conn: TCPConnection ref, event: AsioEventID,
    flags: U32, arg: U32)
  =>
    // Removing this guard causes the test suite to hang.
    if PonyAsio.get_disposable(event) then return end
    if not (AsioEvent.writeable(flags) or AsioEvent.readable(flags)) then
      return
    end

    // Happy Eyeballs straggler — clean up
    conn._decrement_inflight()
    conn._straggler_cleanup(event)

    // Inflight drained — can now send FIN
    conn._initiate_shutdown()
    conn._check_shutdown_complete()

  fun ref send(conn: TCPConnection ref,
    data: (ByteSeq | ByteSeqIter)): (SendToken | SendError)
  =>
    SendErrorNotConnected

  fun ref close(conn: TCPConnection ref) =>
    None

  fun ref hard_close(conn: TCPConnection ref) =>
    conn._set_state(_Closed)
    conn._hard_close_connected()

  fun ref start_tls(conn: TCPConnection ref, ssl_ctx: SSLContext val,
    host: String): (None | StartTLSError)
  =>
    StartTLSNotConnected

  fun ref read_again(conn: TCPConnection ref) =>
    conn._do_read_again()

  fun ref ssl_handshake_complete(conn: TCPConnection ref,
    s: EitherLifecycleEventReceiver ref)
  =>
    _Unreachable()

  fun is_open(): Bool => false
  fun is_closed(): Bool => true
  fun sends_allowed(): Bool => false

class _UnconnectedClosing is _ConnectionState
  """
  Draining inflight Happy Eyeballs connections after close() during the
  connecting phase. The failure callback is deferred until all inflight
  connections drain. hard_close() can interrupt this drain (e.g., connection
  timeout fires during drain), transitioning to _Closed immediately.
  """
  fun ref own_event(conn: TCPConnection ref, flags: U32, arg: U32) =>
    _Unreachable()

  fun ref foreign_event(conn: TCPConnection ref, event: AsioEventID,
    flags: U32, arg: U32)
  =>
    if not (AsioEvent.writeable(flags) or AsioEvent.readable(flags)) then
      return
    end

    let remaining = conn._decrement_inflight()
    conn._straggler_cleanup(event)

    if remaining == 0 then
      conn._set_state(_Closed)
      conn._hard_close_connecting()
    end

  fun ref send(conn: TCPConnection ref,
    data: (ByteSeq | ByteSeqIter)): (SendToken | SendError)
  =>
    SendErrorNotConnected

  fun ref close(conn: TCPConnection ref) =>
    None

  fun ref hard_close(conn: TCPConnection ref) =>
    conn._set_state(_Closed)
    conn._hard_close_connecting()

  fun ref start_tls(conn: TCPConnection ref, ssl_ctx: SSLContext val,
    host: String): (None | StartTLSError)
  =>
    StartTLSNotConnected

  fun ref read_again(conn: TCPConnection ref) =>
    None

  fun ref ssl_handshake_complete(conn: TCPConnection ref,
    s: EitherLifecycleEventReceiver ref)
  =>
    _Unreachable()

  fun is_open(): Bool => false
  fun is_closed(): Bool => true
  fun sends_allowed(): Bool => false

class _Closed is _ConnectionState
  fun ref own_event(conn: TCPConnection ref, flags: U32, arg: U32) =>
    None

  fun ref foreign_event(conn: TCPConnection ref, event: AsioEventID,
    flags: U32, arg: U32)
  =>
    if not (AsioEvent.writeable(flags) or AsioEvent.readable(flags)) then
      return
    end

    // Happy Eyeballs straggler — clean up
    conn._decrement_inflight()
    conn._straggler_cleanup(event)

  fun ref send(conn: TCPConnection ref,
    data: (ByteSeq | ByteSeqIter)): (SendToken | SendError)
  =>
    SendErrorNotConnected

  fun ref close(conn: TCPConnection ref) =>
    None

  fun ref hard_close(conn: TCPConnection ref) =>
    None

  fun ref start_tls(conn: TCPConnection ref, ssl_ctx: SSLContext val,
    host: String): (None | StartTLSError)
  =>
    StartTLSNotConnected

  fun ref read_again(conn: TCPConnection ref) =>
    None

  fun ref ssl_handshake_complete(conn: TCPConnection ref,
    s: EitherLifecycleEventReceiver ref)
  =>
    _Unreachable()

  fun is_open(): Bool => false
  fun is_closed(): Bool => true
  fun sends_allowed(): Bool => false

class _SSLHandshaking is _ConnectionState
  """
  TCP connected, initial SSL handshake in progress. The application has not
  been notified yet — `_on_connected`/`_on_started` fires only after the
  handshake completes.
  """
  fun ref own_event(conn: TCPConnection ref, flags: U32, arg: U32) =>
    conn._dispatch_io_event(flags, arg)

  fun ref foreign_event(conn: TCPConnection ref, event: AsioEventID,
    flags: U32, arg: U32)
  =>
    // Removing this guard causes the test suite to hang.
    if PonyAsio.get_disposable(event) then return end
    if not (AsioEvent.writeable(flags) or AsioEvent.readable(flags)) then
      return
    end

    // Happy Eyeballs straggler — clean up
    conn._decrement_inflight()
    conn._straggler_cleanup(event)

  fun ref send(conn: TCPConnection ref,
    data: (ByteSeq | ByteSeqIter)): (SendToken | SendError)
  =>
    SendErrorNotConnected

  fun ref close(conn: TCPConnection ref) =>
    // Can't drain gracefully during handshake — nothing to FIN.
    conn.hard_close()

  fun ref hard_close(conn: TCPConnection ref) =>
    conn._set_state(_Closed)
    conn._hard_close_ssl_handshaking()

  fun ref start_tls(conn: TCPConnection ref, ssl_ctx: SSLContext val,
    host: String): (None | StartTLSError)
  =>
    StartTLSNotConnected

  fun ref read_again(conn: TCPConnection ref) =>
    conn._do_read_again()

  fun ref ssl_handshake_complete(conn: TCPConnection ref,
    s: EitherLifecycleEventReceiver ref)
  =>
    conn._set_state(_Open)
    conn._cancel_connect_timer()
    conn._arm_idle_timer()
    match \exhaustive\ s
    | let c: ClientLifecycleEventReceiver ref =>
      c._on_connected()
    | let srv: ServerLifecycleEventReceiver ref =>
      srv._on_started()
    end

  fun is_open(): Bool => false
  fun is_closed(): Bool => false
  fun sends_allowed(): Bool => false

class _TLSUpgrading is _ConnectionState
  """
  Established connection upgrading to TLS via `start_tls()`. The application
  has already been notified of the plaintext connection — `_on_tls_ready`
  fires when the handshake completes.
  """
  fun ref own_event(conn: TCPConnection ref, flags: U32, arg: U32) =>
    conn._dispatch_io_event(flags, arg)

  fun ref foreign_event(conn: TCPConnection ref, event: AsioEventID,
    flags: U32, arg: U32)
  =>
    // Removing this guard causes the test suite to hang.
    if PonyAsio.get_disposable(event) then return end
    if not (AsioEvent.writeable(flags) or AsioEvent.readable(flags)) then
      return
    end

    // Happy Eyeballs straggler — clean up
    conn._decrement_inflight()
    conn._straggler_cleanup(event)

  fun ref send(conn: TCPConnection ref,
    data: (ByteSeq | ByteSeqIter)): (SendToken | SendError)
  =>
    SendErrorNotConnected

  fun ref close(conn: TCPConnection ref) =>
    // Can't send FIN during TLS handshake.
    conn.hard_close()

  fun ref hard_close(conn: TCPConnection ref) =>
    conn._set_state(_Closed)
    conn._hard_close_tls_upgrading()

  fun ref start_tls(conn: TCPConnection ref, ssl_ctx: SSLContext val,
    host: String): (None | StartTLSError)
  =>
    StartTLSAlreadyTLS

  fun ref read_again(conn: TCPConnection ref) =>
    conn._do_read_again()

  fun ref ssl_handshake_complete(conn: TCPConnection ref,
    s: EitherLifecycleEventReceiver ref)
  =>
    // TLS upgrade handshake complete — no timer arm needed (timer is
    // already running from the plaintext phase).
    conn._set_state(_Open)
    s._on_tls_ready()

  fun is_open(): Bool => true
  fun is_closed(): Bool => false
  fun sends_allowed(): Bool => false
