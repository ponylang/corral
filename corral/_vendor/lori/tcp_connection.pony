use net = "net"
use "ssl/net"

use @printf[I32](fmt: Pointer[U8] tag, ...)

class TCPConnection
  var _state: _ConnectionState ref = _ConnectionNone
  var _shutdown: Bool = false
  var _shutdown_peer: Bool = false
  var _throttled: Bool = false
  var _readable: Bool = false
  var _writeable: Bool = false
  var _muted: Bool = false
  var _yield_read: Bool = false
  // Happy Eyeballs
  var _inflight_connections: U32 = 0

  var _fd: U32 = -1
  var _event: AsioEventID = AsioEvent.none()
  var _spawned_by: (TCPListenerActor | None) = None
  let _lifecycle_event_receiver: (ClientLifecycleEventReceiver ref | ServerLifecycleEventReceiver ref | None)
  let _enclosing: (TCPConnectionActor ref | None)
  // COUPLING: _pending_first_buffer_offset points into the buffer owned by
  // _pending_data(0). Trimming _pending_data without resetting the offset
  // causes a dangling pointer. _manage_pending_buffer maintains both.
  embed _pending_data: Array[ByteSeq] = _pending_data.create()
  var _pending_writev_total: USize = 0
  var _pending_first_buffer_offset: USize = 0
  var _pending_sent: USize = 0
  var _read_buffer: Array[U8] iso = recover Array[U8] end
  var _bytes_in_read_buffer: USize = 0
  var _read_buffer_size: USize = 16384
  var _read_buffer_min: USize = 16384
  var _buffer_until: (BufferSize | Streaming) = Streaming

  // Send token tracking
  var _next_token_id: USize = 0
  var _pending_token: (SendToken | None) = None

  // Built-in SSL support
  var _ssl: (SSL ref | None) = None
  var _ssl_ready: Bool = false
  var _ssl_failed: Bool = false
  // Set when PonyTCP.connect returned > 0, meaning at least one TCP
  // connection attempt was made. Used by the failure callback to distinguish
  // DNS failure (no attempts) from TCP failure (all attempts failed).
  var _had_inflight: Bool = false
  // Set when _ssl_poll() sees SSLAuthFail before calling hard_close().
  // _hard_close_tls_upgrading() reads this to pass TLSAuthFailed vs
  // TLSGeneralError.
  var _ssl_auth_failed: Bool = false

  // Per-connection idle timeout via ASIO timer
  var _timer_event: AsioEventID = AsioEvent.none()
  var _idle_timeout_nsec: U64 = 0

  // Per-connection connect timeout via ASIO timer (one-shot)
  var _connect_timer_event: AsioEventID = AsioEvent.none()
  var _connect_timeout_nsec: U64 = 0
  // COUPLING: Set by _fire_connect_timeout() before calling hard_close().
  // Read by _hard_close_connecting() and _hard_close_ssl_handshaking() to
  // route the failure reason to ConnectionFailedTimeout. Same pattern as
  // _ssl_auth_failed.
  var _connect_timed_out: Bool = false

  // Per-connection user timer via ASIO timer (one-shot, no I/O reset)
  var _user_timer_event: AsioEventID = AsioEvent.none()
  var _next_timer_id: USize = 0
  var _user_timer_token: (TimerToken | None) = None

  // client startup state
  var _host: String = ""
  var _port: String = ""
  var _from: String = ""
  var _ip_version: IPVersion = DualStack

  new client(auth: TCPConnectAuth,
    host: String,
    port: String,
    from: String,
    enclosing: TCPConnectionActor ref,
    ler: ClientLifecycleEventReceiver ref,
    read_buffer_size: ReadBufferSize = DefaultReadBufferSize(),
    ip_version: IPVersion = DualStack,
    connection_timeout: (ConnectionTimeout | None) = None)
  =>
    """
    Create a client-side plaintext connection. An optional `connection_timeout`
    bounds the TCP Happy Eyeballs phase. If the timeout fires before
    `_on_connected`, the connection fails with `ConnectionFailedTimeout`.
    """
    _lifecycle_event_receiver = ler
    _enclosing = enclosing
    _host = host
    _port = port
    _from = from
    _read_buffer_size = read_buffer_size()
    _read_buffer_min = read_buffer_size()
    _ip_version = ip_version
    match connection_timeout
    | let ct: ConnectionTimeout => _connect_timeout_nsec = ct() * 1_000_000
    end

    _resize_read_buffer_if_needed()

    enclosing._finish_initialization()

  new server(auth: TCPServerAuth,
    fd': U32,
    enclosing: TCPConnectionActor ref,
    ler: ServerLifecycleEventReceiver ref,
    read_buffer_size: ReadBufferSize = DefaultReadBufferSize())
  =>
    _fd = fd'
    _lifecycle_event_receiver = ler
    _enclosing = enclosing
    _read_buffer_size = read_buffer_size()
    _read_buffer_min = read_buffer_size()

    _resize_read_buffer_if_needed()

    enclosing._finish_initialization()

  new ssl_client(auth: TCPConnectAuth,
    ssl_ctx: SSLContext val,
    host: String,
    port: String,
    from: String,
    enclosing: TCPConnectionActor ref,
    ler: ClientLifecycleEventReceiver ref,
    read_buffer_size: ReadBufferSize = DefaultReadBufferSize(),
    ip_version: IPVersion = DualStack,
    connection_timeout: (ConnectionTimeout | None) = None)
  =>
    """
    Create a client-side SSL connection. The SSL session is created from the
    provided SSLContext. If session creation fails, the connection reports
    failure asynchronously via _on_connection_failure(ConnectionFailedSSL).
    An optional `connection_timeout` bounds the connect-to-ready phase
    (TCP Happy Eyeballs + TLS handshake). If the timeout fires before
    `_on_connected`, the connection fails with `ConnectionFailedTimeout`.
    """
    _lifecycle_event_receiver = ler
    _enclosing = enclosing
    _host = host
    _port = port
    _from = from
    _read_buffer_size = read_buffer_size()
    _read_buffer_min = read_buffer_size()
    _ip_version = ip_version
    match connection_timeout
    | let ct: ConnectionTimeout => _connect_timeout_nsec = ct() * 1_000_000
    end

    try
      _ssl = ssl_ctx.client(host)?
    else
      _ssl_failed = true
    end

    _resize_read_buffer_if_needed()

    enclosing._finish_initialization()

  new ssl_server(auth: TCPServerAuth,
    ssl_ctx: SSLContext val,
    fd': U32,
    enclosing: TCPConnectionActor ref,
    ler: ServerLifecycleEventReceiver ref,
    read_buffer_size: ReadBufferSize = DefaultReadBufferSize())
  =>
    """
    Create a server-side SSL connection. The SSL session is created from the
    provided SSLContext. If session creation fails, the connection reports
    failure asynchronously via _on_start_failure(StartFailedSSL) and closes the
    fd.
    """
    _fd = fd'
    _lifecycle_event_receiver = ler
    _enclosing = enclosing
    _read_buffer_size = read_buffer_size()
    _read_buffer_min = read_buffer_size()

    try
      _ssl = ssl_ctx.server()?
    else
      _ssl_failed = true
    end

    _resize_read_buffer_if_needed()

    enclosing._finish_initialization()

  new none() =>
    _enclosing = None
    _lifecycle_event_receiver = None

  fun keepalive(secs: U32) =>
    """
    Sets the TCP keepalive timeout to approximately `secs` seconds. Exact
    timing is OS dependent. If `secs` is zero, TCP keepalive is disabled. TCP
    keepalive is disabled by default. This can only be set on a connected
    socket.
    """
    if _state.is_open() then
      PonyTCP.keepalive(_fd, secs)
    end

  fun set_nodelay(state: Bool): U32 =>
    """
    Turn Nagle on/off. Defaults to on (Nagle enabled, nodelay off). When
    enabled (`state = true`), small writes are sent immediately without
    waiting to coalesce — useful for latency-sensitive protocols. When
    disabled (`state = false`), the OS may buffer small writes.

    Returns 0 on success, or a non-zero errno on failure. Only meaningful
    on a connected socket — returns non-zero if the connection is not open.
    """
    if not is_open() then return 1 end
    _OSSocket.setsockopt_u32(_fd, OSSockOpt.ipproto_tcp(),
      OSSockOpt.tcp_nodelay(), if state then 1 else 0 end)

  fun get_so_rcvbuf(): (U32, U32) =>
    """
    Get the OS receive buffer size for this socket.

    Returns a 2-tuple: (errno, value). On success, errno is 0 and value is
    the buffer size in bytes. On failure, errno is non-zero and value should
    be ignored. Only meaningful on a connected socket — returns (1, 0) if
    the connection is not open.
    """
    if not is_open() then return (1, 0) end
    _OSSocket.get_so_rcvbuf(_fd)

  fun set_so_rcvbuf(bufsize: U32): U32 =>
    """
    Set the OS receive buffer size for this socket. The OS may round the
    requested size up to a minimum or clamp it to a maximum.

    Returns 0 on success, or a non-zero errno on failure. Only meaningful
    on a connected socket — returns non-zero if the connection is not open.
    """
    if not is_open() then return 1 end
    _OSSocket.set_so_rcvbuf(_fd, bufsize)

  fun get_so_sndbuf(): (U32, U32) =>
    """
    Get the OS send buffer size for this socket.

    Returns a 2-tuple: (errno, value). On success, errno is 0 and value is
    the buffer size in bytes. On failure, errno is non-zero and value should
    be ignored. Only meaningful on a connected socket — returns (1, 0) if
    the connection is not open.
    """
    if not is_open() then return (1, 0) end
    _OSSocket.get_so_sndbuf(_fd)

  fun set_so_sndbuf(bufsize: U32): U32 =>
    """
    Set the OS send buffer size for this socket. The OS may round the
    requested size up to a minimum or clamp it to a maximum.

    Returns 0 on success, or a non-zero errno on failure. Only meaningful
    on a connected socket — returns non-zero if the connection is not open.
    """
    if not is_open() then return 1 end
    _OSSocket.set_so_sndbuf(_fd, bufsize)

  fun getsockopt(level: I32, option_name: I32,
    option_max_size: USize = 4): (U32, Array[U8] iso^)
  =>
    """
    General interface to `getsockopt(2)` for accessing any socket option.

    The `option_max_size` argument is the maximum number of bytes the caller
    expects the kernel to return. This method allocates a buffer of that size
    before calling `getsockopt(2)`.

    Returns a 2-tuple: on success, `(0, data)` where `data` is the bytes
    returned by the kernel, sized to the actual length the kernel wrote. On
    failure, `(errno, undefined)` — the second element must be ignored. Only
    meaningful on a connected socket — returns `(1, empty)` if the connection
    is not open.

    For commonly-tuned options, prefer the dedicated convenience methods
    (`set_nodelay`, `get_so_rcvbuf`, etc.). Do not change the socket's
    non-blocking mode — lori's event-driven I/O requires non-blocking
    sockets.
    """
    if not is_open() then return (1, recover Array[U8] end) end
    _OSSocket.getsockopt(_fd, level, option_name, option_max_size)

  fun getsockopt_u32(level: I32, option_name: I32): (U32, U32) =>
    """
    Wrapper for `getsockopt(2)` where the kernel returns a C `uint32_t`.

    Returns a 2-tuple: on success, `(0, value)`. On failure,
    `(errno, undefined)` — the second element must be ignored. Only
    meaningful on a connected socket — returns `(1, 0)` if the connection
    is not open.

    For commonly-tuned options, prefer the dedicated convenience methods
    (`get_so_rcvbuf`, `get_so_sndbuf`, etc.). Do not change the socket's
    non-blocking mode — lori's event-driven I/O requires non-blocking
    sockets.
    """
    if not is_open() then return (1, 0) end
    _OSSocket.getsockopt_u32(_fd, level, option_name)

  fun setsockopt(level: I32, option_name: I32, option: Array[U8]): U32 =>
    """
    General interface to `setsockopt(2)` for setting any socket option.

    The caller is responsible for the correct size, byte contents, and
    byte order of the `option` array for the requested `level` and
    `option_name`.

    Returns 0 on success, or the value of `errno` on failure. Only
    meaningful on a connected socket — returns non-zero if the connection
    is not open.

    For commonly-tuned options, prefer the dedicated convenience methods
    (`set_nodelay`, `set_so_rcvbuf`, etc.). Do not change the socket's
    non-blocking mode — lori's event-driven I/O requires non-blocking
    sockets.
    """
    if not is_open() then return 1 end
    _OSSocket.setsockopt(_fd, level, option_name, option)

  fun setsockopt_u32(level: I32, option_name: I32, option: U32): U32 =>
    """
    Wrapper for `setsockopt(2)` where the kernel expects a C `uint32_t`.

    Returns 0 on success, or the value of `errno` on failure. Only
    meaningful on a connected socket — returns non-zero if the connection
    is not open.

    For commonly-tuned options, prefer the dedicated convenience methods
    (`set_nodelay`, `set_so_rcvbuf`, etc.). Do not change the socket's
    non-blocking mode — lori's event-driven I/O requires non-blocking
    sockets.
    """
    if not is_open() then return 1 end
    _OSSocket.setsockopt_u32(_fd, level, option_name, option)

  fun ref idle_timeout(duration: (IdleTimeout | None)) =>
    """
    Set or disable the idle timeout. Idle timeout is disabled by default.

    When `duration` is an `IdleTimeout`, the timer fires when no successful
    send or receive occurs for that duration, delivering
    `_on_idle_timeout()` to the lifecycle event receiver. When `duration`
    is `None`, the idle timeout is disabled.

    The timer automatically re-arms after each firing until disabled or
    the connection closes.

    Can be called before the connection is established — the value is
    stored and the timer starts when the connection is ready.

    This is independent of TCP keepalive (`keepalive()`). TCP keepalive
    is a transport-level probe that detects dead peers. Idle timeout is
    application-level inactivity detection — it fires whether or not the
    peer is alive.
    """
    match \exhaustive\ duration
    | let t: IdleTimeout =>
      _idle_timeout_nsec = t() * 1_000_000
      // _SSLHandshaking.is_open() = false blocks arming; the timer starts
      // at ssl_handshake_complete. _TLSUpgrading.is_open() = true allows
      // arming — the timer is already running from the plaintext phase.
      if _state.is_open() then
        if _timer_event.is_null() then
          _arm_idle_timer()
        else
          _reset_idle_timer()
        end
      end
    | None =>
      _idle_timeout_nsec = 0
      if _state.is_open() then
        _cancel_idle_timer()
      end
    end

  fun ref set_timer(duration: TimerDuration): (TimerToken | SetTimerError) =>
    """
    Create a one-shot timer that fires `_on_timer()` after the configured
    duration. Returns a `TimerToken` on success, or a `SetTimerError` on
    failure.

    Unlike `idle_timeout()`, this timer has no I/O-reset behavior — it fires
    unconditionally after the duration elapses, regardless of send/receive
    activity. There is no automatic re-arming; call `set_timer()` again from
    `_on_timer()` for repetition.

    Only one user timer can be active at a time. Setting a timer while one is
    already active returns `SetTimerAlreadyActive` — call `cancel_timer()`
    first. This prevents silent token invalidation.

    Requires the connection to be application-level connected: `is_open()` must
    be true and the initial SSL handshake (if any) must have completed. TLS
    upgrades via `start_tls()` do not block timer creation.

    The timer survives `close()` (graceful shutdown) but is cancelled by
    `hard_close()`.
    """
    // _SSLHandshaking.is_open() = false blocks timers during initial SSL
    // handshake. _TLSUpgrading.is_open() = true allows them — the
    // application already received _on_connected/_on_started.
    if not is_open() then return SetTimerNotOpen end
    if _user_timer_token isnt None then return SetTimerAlreadyActive end

    let nsec = duration() * 1_000_000
    match \exhaustive\ _enclosing
    | let e: TCPConnectionActor ref =>
      _user_timer_event = PonyAsio.create_timer_event(e, nsec)
    | None =>
      _Unreachable()
    end
    let token = TimerToken._create(_next_timer_id = _next_timer_id + 1)
    _user_timer_token = token
    token

  fun ref cancel_timer(token: TimerToken) =>
    """
    Cancel an active timer. No-op if the token doesn't match the active timer
    (already fired, already cancelled, wrong token). Safe to call with stale
    tokens.

    No connection state check — timers can be cancelled during graceful
    shutdown (`_Closing`) since they remain active until `hard_close()`.
    """
    match _user_timer_token
    | let t: TimerToken if t == token =>
      PonyAsio.unsubscribe(_user_timer_event)
      _user_timer_event = AsioEvent.none()
      _user_timer_token = None
    end

  fun ref set_read_buffer_minimum(new_min: ReadBufferSize):
    (ReadBufferResized | ReadBufferResizeBelowBufferSize)
  =>
    """
    Set the shrink-back floor for the read buffer to exactly `new_min` bytes.
    When the read buffer is empty and larger than the minimum, it shrinks back
    to this size automatically. If the current buffer allocation is smaller
    than `new_min`, the buffer is grown to match.

    Returns `ReadBufferResizeBelowBufferSize` if `new_min` is less than the
    current buffer-until value.
    """
    let min = new_min()

    if min < _user_buffer_until() then
      return ReadBufferResizeBelowBufferSize
    end

    _read_buffer_min = min

    if _read_buffer_size < min then
      _read_buffer_size = min
      _read_buffer.undefined(_read_buffer_size)
    end

    ReadBufferResized

  fun ref resize_read_buffer(size': ReadBufferSize): ReadBufferResizeResult =>
    """
    Force the read buffer to exactly `size'` bytes, reallocating if different.
    If `size'` is below the current minimum, the minimum is lowered to match.

    Returns `ReadBufferResizeBelowBufferSize` if `size'` is less than the
    current buffer-until value, or `ReadBufferResizeBelowUsed` if `size'` is
    less than the amount of unprocessed data currently in the buffer.
    """
    let size = size'()

    if size < _user_buffer_until() then
      return ReadBufferResizeBelowBufferSize
    end

    if size < _bytes_in_read_buffer then
      return ReadBufferResizeBelowUsed
    end

    if size < _read_buffer_min then
      _read_buffer_min = size
    end

    _read_buffer_size = size

    let old_buffer = _read_buffer = recover Array[U8] end
    _read_buffer = recover iso
      let a = Array[U8](size)
      a.undefined(size)
      if _bytes_in_read_buffer > 0 then
        (consume old_buffer).copy_to(a, 0, 0, _bytes_in_read_buffer)
      end
      a
    end

    ReadBufferResized

  fun local_address(): net.NetAddress =>
    """
    Return the local IP address. If this TCPConnection is closed then the
    address returned is invalid.
    """
    recover
      let ip: net.NetAddress ref = net.NetAddress
      PonyTCP.sockname(_fd, ip)
      ip
    end

  fun remote_address(): net.NetAddress =>
    """
    Return the remote IP address. If this TCPConnection is closed then the
    address returned is invalid.
    """
    recover
      let ip: net.NetAddress ref = net.NetAddress
      PonyTCP.peername(_fd, ip)
      ip
    end

  fun ref mute() =>
    """
    Temporarily suspend reading off this TCPConnection until such time as
    `unmute` is called.
    """
    _muted = true

  fun ref unmute() =>
    """
    Start reading off this TCPConnection again after having been muted.
    """
    _muted = false
    // Trigger a read in case we ignored any previous ASIO notifications
    _queue_read()

  fun ref yield_read() =>
    """
    Request the read loop to exit after the current `_on_received` callback
    returns, giving other actors a chance to run. Reading resumes automatically
    in the next scheduler turn — no explicit `unmute()` is needed.

    Call this from within `_on_received()` to implement application-level yield
    policies (e.g. yield after N messages, after N bytes, or after a time
    threshold). Unlike `mute()`/`unmute()`, which persistently stop reading
    until reversed, `yield_read()` is a one-shot pause: the read loop resumes
    on its own.

    For SSL connections, `yield_read()` operates at TCP-read granularity. All
    SSL-decrypted messages from a single TCP read are delivered before the yield
    takes effect, because the inner dispatch loop runs exactly once per TCP read
    when SSL is active.
    """
    _yield_read = true

  fun _user_buffer_until(): USize =>
    """
    The user's requested buffer-until value, regardless of whether SSL is
    active. Returns 0 when `Streaming`, since 0 < any valid buffer min — the
    correct behavior for invariant checks when no buffer-until constraint is
    active.
    """
    match \exhaustive\ _buffer_until
    | let e: BufferSize => e()
    | Streaming => 0
    end

  fun _tcp_buffer_until(): (BufferSize | Streaming) =>
    """
    The buffer-until value for the TCP read layer. When SSL is active, returns
    `Streaming` because SSL record framing doesn't align with application
    framing — the TCP layer reads all available data and lets `_ssl_poll()`
    handle chunking via `_buffer_until`. When SSL is not active, returns the
    user's `_buffer_until` value directly.
    """
    match _ssl
    | let _: SSL box => Streaming
    | None => _buffer_until
    end

  fun ref buffer_until(qty: (BufferSize | Streaming)): BufferUntilResult =>
    """
    Set the number of bytes to buffer before delivering data via
    `_on_received`. When `qty` is `Streaming`, all available data is delivered
    as it arrives.

    Returns `BufferSizeAboveMinimum` if `qty` exceeds the current read
    buffer minimum. Raise the buffer minimum first, then set buffer_until.
    """
    match qty
    | let e: BufferSize =>
      if e() > _read_buffer_min then
        return BufferSizeAboveMinimum
      end
    end

    match \exhaustive\ _lifecycle_event_receiver
    | let _: EitherLifecycleEventReceiver =>
      _buffer_until = qty
    | None =>
      _Unreachable()
    end

    BufferUntilSet

  fun ref close() =>
    """
    Attempt to perform a graceful shutdown. Don't accept new writes.

    During the connecting phase (Happy Eyeballs in progress), transitions to
    `_UnconnectedClosing` to drain inflight connection attempts. Each
    straggler event is cleaned up as it arrives. Once all inflight connections
    have drained, `_on_connection_failure` fires.

    If the connection is established and not muted, we won't finish closing
    until we get a zero length read. If the connection is muted, perform a
    hard close and shut down immediately.
    """
    if _muted then
      hard_close()
    else
      _state.close(this)
    end

  fun ref hard_close() =>
    """
    When an error happens, do a non-graceful close.
    """
    _state.hard_close(this)

  fun ref _hard_close_connecting() =>
    """
    Hard close during the connecting phase. Disposes SSL, fires the
    appropriate failure callback, and cancels the idle, connect, and user
    timers. The caller must set `_state = _Closed` before calling this.
    """
    _shutdown = true
    _shutdown_peer = true
    match _ssl
    | let ssl: SSL ref =>
      ssl.dispose()
      _ssl = None
    end
    match _lifecycle_event_receiver
    | let c: ClientLifecycleEventReceiver ref =>
      let reason = if _connect_timed_out then
        ConnectionFailedTimeout
      elseif _had_inflight then
        ConnectionFailedTCP
      else
        ConnectionFailedDNS
      end
      c._on_connection_failure(reason)
    end
    _cancel_idle_timer()
    _cancel_connect_timer()
    _cancel_user_timer()

  fun ref _hard_close_cleanup() =>
    """
    Common teardown for hard-closing an established connection. Handles
    shutdown flags, send_failed for pending token, clearing pending buffers,
    cancelling all timers, unsubscribing the event, closing the fd, and
    disposing SSL. Order is load-bearing: timer cancel before event
    unsubscribe, SSL dispose after fd close.

    Does NOT set `_ssl = None` — the connection is terminal and nothing
    accesses it afterward. The caller must set `_state = _Closed` before
    calling this.
    """
    _shutdown = true
    _shutdown_peer = true

    // Fire _on_send_failed for any accepted-but-undelivered send before
    // clearing the pending buffer. This is deferred via _notify_send_failed
    // so it arrives in a subsequent turn, after _on_closed.
    match (_pending_token, _enclosing)
    | (let t: SendToken, let e: TCPConnectionActor ref) =>
      e._notify_send_failed(t)
    end

    _pending_data.clear()
    _pending_writev_total = 0
    _pending_first_buffer_offset = 0
    ifdef windows then
      _pending_sent = 0
    end
    _pending_token = None

    _cancel_idle_timer()
    _cancel_connect_timer()
    _cancel_user_timer()
    PonyAsio.unsubscribe(_event)
    _set_unreadable()
    _set_unwriteable()

    // On windows, this will also cancel all outstanding IOCP operations.
    PonyTCP.close(_fd)
    _fd = -1

    match _ssl
    | let ssl: SSL ref =>
      ssl.dispose()
    end

  fun ref _spawner_notification() =>
    """
    Notify the spawning listener (if any) that this server connection has
    closed. For client connections, this is a no-op.
    """
    match _lifecycle_event_receiver
    | let e: ServerLifecycleEventReceiver ref =>
      match \exhaustive\ _spawned_by
      | let spawner: TCPListenerActor =>
        spawner._connection_closed()
        _spawned_by = None
      | None =>
        // It is possible that we didn't yet receive the message giving us
        // our spawner. Do nothing in that case.
        None
      end
    end

  fun ref _hard_close_connected() =>
    """
    Hard close for an established connection where the application has been
    notified (i.e., _on_connected/_on_started has already fired). Only
    reachable from `_Open` and `_Closing` — handshake states have their own
    hard-close methods. Fires `_on_closed` and notifies the spawner. The
    caller must set `_state = _Closed` before calling this.
    """
    _hard_close_cleanup()

    match \exhaustive\ _lifecycle_event_receiver
    | let s: EitherLifecycleEventReceiver ref =>
      s._on_closed()
    | None =>
      _Unreachable()
    end

    _spawner_notification()

  fun ref _hard_close_ssl_handshaking() =>
    """
    Hard close during the initial SSL handshake (state: `_SSLHandshaking`).
    The application has not been notified — fires `_on_connection_failure`
    (client) or `_on_start_failure` (server). The caller must set
    `_state = _Closed` before calling this.
    """
    _hard_close_cleanup()

    match \exhaustive\ _lifecycle_event_receiver
    | let s: EitherLifecycleEventReceiver ref =>
      match \exhaustive\ s
      | let c: ClientLifecycleEventReceiver ref =>
        if _connect_timed_out then
          c._on_connection_failure(ConnectionFailedTimeout)
        else
          c._on_connection_failure(ConnectionFailedSSL)
        end
      | let srv: ServerLifecycleEventReceiver ref =>
        srv._on_start_failure(StartFailedSSL)
      end
    | None =>
      _Unreachable()
    end

    _spawner_notification()

  fun ref _hard_close_tls_upgrading() =>
    """
    Hard close during a TLS upgrade handshake (state: `_TLSUpgrading`).
    The application was already notified of the plaintext connection, so
    `_on_tls_failure` fires followed by `_on_closed`. The caller must set
    `_state = _Closed` before calling this.
    """
    _hard_close_cleanup()

    let reason = if _ssl_auth_failed then
      TLSAuthFailed
    else
      TLSGeneralError
    end

    match \exhaustive\ _lifecycle_event_receiver
    | let s: EitherLifecycleEventReceiver ref =>
      s._on_tls_failure(reason)
      s._on_closed()
    | None =>
      _Unreachable()
    end

    _spawner_notification()

  fun is_open(): Bool =>
    _state.is_open()

  fun is_closed(): Bool =>
    _state.is_closed()

  fun is_writeable(): Bool =>
    """
    Returns whether the connection can currently accept a `send()` call.
    Checks that the state allows sends and the socket is writeable.
    """
    _state.sends_allowed() and _writeable

  fun ref start_tls(ssl_ctx: SSLContext val, host: String = ""):
    (None | StartTLSError)
  =>
    """
    Initiate a TLS handshake on an established plaintext connection. Returns
    `None` when the handshake has been started, or a `StartTLSError` if the
    upgrade cannot proceed (the connection is unchanged in that case).

    Preconditions: the connection must be open, not already TLS, not muted,
    have no unprocessed data in the read buffer, and have no pending writes.
    The read buffer check prevents a man-in-the-middle from injecting pre-TLS
    data that the application would process as post-TLS (CVE-2021-23222).

    On success, `_on_tls_ready()` fires when the handshake completes. During
    the handshake, `send()` returns `SendErrorNotConnected`. If the handshake
    fails, `_on_tls_failure` fires followed by `_on_closed()`.

    The `host` parameter is used for SNI (Server Name Indication) on client
    connections. Pass an empty string for server connections or when SNI is
    not needed.
    """
    _state.start_tls(this, ssl_ctx, host)

  fun ref _do_start_tls(ssl_ctx: SSLContext val, host: String):
    (None | StartTLSError)
  =>
    match _ssl
    | let _: SSL ref => return StartTLSAlreadyTLS
    end

    // On POSIX, _has_pending_writes() checks whether any data remains
    // unsent (writev is synchronous — returns bytes written or EWOULDBLOCK).
    // On Windows IOCP, submitted-but-unconfirmed writes are already in the
    // kernel's send buffer, so only un-submitted entries block TLS upgrade.
    // After send("OK") + _iocp_submit_pending(), _pending_writev_total > 0
    // but _pending_data.size() == _pending_sent — the data is in the kernel
    // and TLS can safely proceed.
    let has_unsent_writes: Bool = ifdef windows then
      _pending_data.size() > _pending_sent
    else
      _has_pending_writes()
    end

    if _muted or (_bytes_in_read_buffer > 0) or has_unsent_writes then
      return StartTLSNotReady
    end

    let ssl = try
      match \exhaustive\ _lifecycle_event_receiver
      | let _: ClientLifecycleEventReceiver ref =>
        ssl_ctx.client(host)?
      | let _: ServerLifecycleEventReceiver ref =>
        ssl_ctx.server()?
      | None =>
        _Unreachable()
        return StartTLSSessionFailed
      end
    else
      return StartTLSSessionFailed
    end

    _ssl = consume ssl
    _state = _TLSUpgrading
    _ssl_flush_sends()
    None

  fun ref send(data: (ByteSeq | ByteSeqIter)): (SendToken | SendError) =>
    """
    Send data on this connection. Accepts a single buffer (`ByteSeq`) or
    multiple buffers (`ByteSeqIter`). When multiple buffers are provided,
    they are sent in a single writev syscall — avoiding both per-buffer
    syscall overhead and the cost of copying into a contiguous buffer.

    Returns a `SendToken` on success, or a `SendError` explaining the
    failure. When successful, `_on_sent(token)` will fire in a subsequent
    behavior turn once the data has been fully handed to the OS.
    """
    _state.send(this, data)

  fun ref _do_send(data: (ByteSeq | ByteSeqIter)): (SendToken | SendError) =>
    // Only reachable from _Open.send() — the handshake states return
    // SendErrorNotConnected directly without calling this method.
    if not _writeable then
      return SendErrorNotWriteable
    end

    _next_token_id = _next_token_id + 1
    let token = SendToken._create(_next_token_id)

    match \exhaustive\ _ssl
    | let ssl: SSL ref =>
      match \exhaustive\ data
      | let d: ByteSeq =>
        try ssl.write(d)? end
      | let d: ByteSeqIter =>
        for v in d.values() do
          try ssl.write(v)? end
        end
      end
      _ssl_flush_sends()

      // Check if SSL error triggered close
      if not is_open() then
        return SendErrorNotConnected
      end
    | None =>
      match \exhaustive\ data
      | let d: ByteSeq =>
        _enqueue(d)
      | let d: ByteSeqIter =>
        for v in d.values() do
          _enqueue(v)
        end
      end
      ifdef windows then
        _iocp_submit_pending()
      else
        _send_pending_writes()
      end
    end

    _reset_idle_timer()

    // Determine when to fire _on_sent
    if not _has_pending_writes() then
      // All data sent to OS immediately; defer _on_sent
      match \exhaustive\ _enclosing
      | let e: TCPConnectionActor ref =>
        e._notify_sent(token)
      | None =>
        _Unreachable()
      end
    else
      // Partial write; _on_sent fires when pending list drains
      _pending_token = token
    end

    token

  fun ref _initiate_shutdown() =>
    """
    Send FIN to the peer if not already shutdown and no inflight connections
    remain. Called when entering _Closing or when inflight connections drain
    during _Closing.
    """
    if not _shutdown and (_inflight_connections == 0) then
      _shutdown = true
      PonyTCP.shutdown(_fd)
    end

  fun ref _check_shutdown_complete() =>
    """
    If both sides have shut down, perform a hard close.
    """
    if _shutdown and _shutdown_peer then
      hard_close()
    end

  fun ref _enqueue(data: ByteSeq) =>
    """
    Add a buffer to the pending write queue. Callers must call the
    platform-specific flush after enqueuing: `_send_pending_writes()` on
    POSIX, `_iocp_submit_pending()` on Windows.

    Uses `not is_closed()` rather than `is_open()` because `_ssl_flush_sends()`
    calls `_enqueue()` during `_SSLHandshaking` (where `is_open() = false`)
    to push handshake protocol data. The wider guard allows handshake data
    through while still blocking enqueue after the connection closes.
    """
    if data.size() == 0 then return end
    if not is_closed() then
      _pending_data.push(data)
      _pending_writev_total = _pending_writev_total + data.size()
    end

  fun ref _manage_pending_buffer(bytes_sent: USize): USize =>
    """
    Account for `bytes_sent` by walking `_pending_data` entries. Returns
    the number of fully-sent entries. Updates `_pending_first_buffer_offset`,
    `_pending_writev_total`, and trims `_pending_data`.
    """
    if bytes_sent == 0 then return 0 end

    var remaining = bytes_sent
    var num_fully_sent: USize = 0
    var new_offset: USize = 0

    while remaining > 0 do
      try
        let entry = _pending_data(num_fully_sent)?
        let start = if num_fully_sent == 0 then
          _pending_first_buffer_offset
        else
          USize(0)
        end
        let effective_size = entry.size() - start

        if effective_size <= remaining then
          // Fully sent
          num_fully_sent = num_fully_sent + 1
          remaining = remaining - effective_size
        else
          // Partially sent — this entry becomes the new entry 0 after trim
          new_offset = start + remaining
          remaining = 0
        end
      else
        _Unreachable()
      end
    end

    _pending_writev_total = _pending_writev_total - bytes_sent
    _pending_data.trim_in_place(num_fully_sent)
    _pending_first_buffer_offset = new_offset

    num_fully_sent

  fun ref _send_pending_writes() =>
    """
    Flush pending write data using writev.
    This is POSIX only.
    """
    ifdef posix then
      let writev_batch_size: USize = PonyTCP.writev_max().usize()

      while _writeable and (_pending_writev_total > 0) do
        try
          // Determine batch size and byte count
          let num_to_send: USize =
            _pending_data.size().min(writev_batch_size)

          let bytes_to_send: USize =
            if num_to_send == _pending_data.size() then
              _pending_writev_total
            else
              var total: USize = 0
              var i: USize = 0
              while i < num_to_send do
                let s = _pending_data(i)?.size()
                total = total +
                  if i == 0 then s - _pending_first_buffer_offset else s end
                i = i + 1
              end
              total
            end

          // writev syscall — returns bytes sent, 0 on EWOULDBLOCK
          let len = PonyTCP.writev(_event, _pending_data,
            0, num_to_send, _pending_first_buffer_offset)?

          if len < bytes_to_send then
            _manage_pending_buffer(len)
            _apply_backpressure()
          else
            _manage_pending_buffer(bytes_to_send)
          end
        else
          // writev error — non-graceful shutdown
          hard_close()
          return
        end
      end

      if _pending_writev_total == 0 then
        _release_backpressure()

        match _pending_token
        | let t: SendToken =>
          _pending_token = None
          match \exhaustive\ _enclosing
          | let e: TCPConnectionActor ref =>
            e._notify_sent(t)
          | None =>
            _Unreachable()
          end
        end
      end
    else
      _Unreachable()
    end

  fun ref _iocp_submit_pending() =>
    """
    Submit all pending write buffers to IOCP in a single WSASend.
    Only one IOCP write is outstanding at a time — if a previous WSASend
    hasn't completed yet, this is a no-op and the data waits in
    `_pending_data` until `_write_completed` resubmits.
    This is Windows only.
    """
    ifdef windows then
      if _pending_sent > 0 then return end

      let num_to_send = _pending_data.size()
      if num_to_send == 0 then return end

      try
        let len = PonyTCP.writev(_event, _pending_data,
          0, num_to_send, _pending_first_buffer_offset)?

        if len == 0 then
          _apply_backpressure()
        else
          _pending_sent = len
        end
      else
        hard_close()
      end
    else
      _Unreachable()
    end

  fun ref _write_completed(len: U32) =>
    """
    The OS has informed us that `len` bytes of pending writes have completed.
    This occurs only with IOCP on Windows.

    A single WSASend call covers all submitted entries. When the IOCP
    completion fires, the entire operation is done — none of the entries
    are in-flight anymore. We reset `_pending_sent` to 0 and resubmit
    any remaining data.
    """
    ifdef windows then
      if len == 0 then
        hard_close()
        return
      end

      _manage_pending_buffer(len.usize())
      // The WSASend IOCP operation has completed. All entries covered by
      // this operation are no longer in-flight.
      _pending_sent = 0

      if _pending_writev_total == 0 then
        _release_backpressure()

        match _pending_token
        | let t: SendToken =>
          _pending_token = None
          match \exhaustive\ _enclosing
          | let e: TCPConnectionActor ref =>
            e._notify_sent(t)
          | None =>
            _Unreachable()
          end
        end
      else
        // Resubmit remaining data
        _iocp_submit_pending()
        if _pending_sent < 16 then
          _release_backpressure()
        end
      end
    else
      _Unreachable()
    end

  fun ref _deliver_received(s: EitherLifecycleEventReceiver ref,
    data: Array[U8] iso)
  =>
    """
    Route incoming data through SSL decryption (if present) or directly
    to the lifecycle event receiver.
    """
    match \exhaustive\ _ssl
    | let ssl: SSL ref =>
      ssl.receive(consume data)
      _ssl_poll(s)
    | None =>
      s._on_received(consume data)
    end

  fun ref _read() =>
    ifdef posix then
      _reset_idle_timer()
      match \exhaustive\ _lifecycle_event_receiver
      | let s: EitherLifecycleEventReceiver ref =>
        try
          var total_bytes_read: USize = 0

          while _readable do
            // exit if muted
            if _muted then
              return
            end

            // Handle any data already in the read buffer
            while not _muted and _there_is_buffered_read_data() do
              let bytes_to_consume = match \exhaustive\ _tcp_buffer_until()
              | let e: BufferSize => e()
              | Streaming => _bytes_in_read_buffer
              end

              let x = _read_buffer = recover Array[U8] end
              (let data', _read_buffer) = (consume x).chop(bytes_to_consume)
              _bytes_in_read_buffer = _bytes_in_read_buffer - bytes_to_consume

              _deliver_received(s, consume data')

              // COUPLING: This check must remain immediately after
              // _deliver_received() — moving it would change when the yield
              // takes effect relative to application callbacks.
              if _yield_read then
                _yield_read = false
                match \exhaustive\ _enclosing
                | let e: TCPConnectionActor ref => e._read_again()
                | None => _Unreachable()
                end
                return
              end
            end

            // Yield after reading a buffer's worth of data to allow GC and
            // other actors to run. _queue_read() schedules _read_again to
            // resume.
            if total_bytes_read >= _read_buffer_size then
              _queue_read()
              return
            end

            _resize_read_buffer_if_needed()

            let bytes_read = PonyTCP.receive(_event,
              _read_buffer.cpointer(_bytes_in_read_buffer),
              _read_buffer.size() - _bytes_in_read_buffer)?

            if bytes_read == 0 then
              // would block. try again later
              _set_unreadable()
              PonyAsio.resubscribe_read(_event)
              return
            end

            _bytes_in_read_buffer = _bytes_in_read_buffer + bytes_read
            total_bytes_read = total_bytes_read + bytes_read
          end
        else
          // The socket has been closed from the other side.
          hard_close()
        end
      | None =>
        _Unreachable()
      end
    else
      _Unreachable()
    end

  fun ref _iocp_read() =>
    ifdef windows then
      try
        PonyTCP.receive(_event,
          _read_buffer.cpointer(_bytes_in_read_buffer),
          _read_buffer.size() - _bytes_in_read_buffer)?
      else
        close()
      end
    else
      _Unreachable()
    end

  fun ref _read_completed(len: U32) =>
    """
    The OS has informed us that `len` bytes of data has been read and is now
    available.
    """
    ifdef windows then
      _reset_idle_timer()
      match \exhaustive\ _lifecycle_event_receiver
      | let s: EitherLifecycleEventReceiver ref =>
        if len == 0 then
          // The socket has been closed from the other side, or a hard close has
          // cancelled the queued read.
          _set_unreadable()
          _shutdown_peer = true
          close()
          return
        end

        // Handle the data
        _bytes_in_read_buffer = _bytes_in_read_buffer + len.usize()

        while not _muted and _there_is_buffered_read_data()
        do
          // get data to be distributed and update `_bytes_in_read_buffer`
          let chop_at = match \exhaustive\ _tcp_buffer_until()
          | let e: BufferSize => e()
          | Streaming => _bytes_in_read_buffer
          end
          (let data, _read_buffer) = (consume _read_buffer).chop(chop_at)
          _bytes_in_read_buffer = _bytes_in_read_buffer - chop_at

          _deliver_received(s, consume data)

          // COUPLING: This check must remain immediately after
          // _deliver_received() — moving it would change when the yield
          // takes effect relative to application callbacks.
          if _yield_read then
            _yield_read = false
            match \exhaustive\ _enclosing
            | let e: TCPConnectionActor ref => e._read_again()
            | None => _Unreachable()
            end
            return
          end

          _resize_read_buffer_if_needed()
        end

        _resize_read_buffer_if_needed()
        _queue_read()
      | None =>
        _Unreachable()
      end
    else
      _Unreachable()
    end

  fun ref _windows_resume_read() =>
    """
    Resume reading after a yield on Windows. Processes any buffered data first,
    then submits an IOCP read for new data. Without this, yielding with
    unprocessed buffered data and calling `_queue_read()` directly would leave
    the buffered data unprocessed until new data arrives from the peer — which
    might be never.

    Called via `_do_read_again()` from the `_read_again()` behavior, which is
    deferred. The state machine guards against calling this after hard_close():
    `_Closed.read_again()` is a no-op. `_Closing.read_again()` correctly
    calls this because the socket is still connected and we need an IOCP read
    to detect the peer's FIN.
    """
    ifdef windows then
      match \exhaustive\ _lifecycle_event_receiver
      | let s: EitherLifecycleEventReceiver ref =>
        while not _muted and _there_is_buffered_read_data() do
          let chop_at = match \exhaustive\ _tcp_buffer_until()
          | let e: BufferSize => e()
          | Streaming => _bytes_in_read_buffer
          end
          (let data, _read_buffer) = (consume _read_buffer).chop(chop_at)
          _bytes_in_read_buffer = _bytes_in_read_buffer - chop_at

          _deliver_received(s, consume data)

          // COUPLING: This check must remain immediately after
          // _deliver_received() — moving it would change when the yield
          // takes effect relative to application callbacks.
          if _yield_read then
            _yield_read = false
            match \exhaustive\ _enclosing
            | let e: TCPConnectionActor ref => e._read_again()
            | None => _Unreachable()
            end
            return
          end

          _resize_read_buffer_if_needed()
        end

        _resize_read_buffer_if_needed()
        _queue_read()
      | None =>
        _Unreachable()
      end
    else
      _Unreachable()
    end

  fun _there_is_buffered_read_data(): Bool =>
    match \exhaustive\ _tcp_buffer_until()
    | let e: BufferSize => _bytes_in_read_buffer >= e()
    | Streaming => _bytes_in_read_buffer > 0
    end

  fun ref _resize_read_buffer_if_needed() =>
    """
    Resize the read buffer if it's smaller than the buffer-until threshold, or
    shrink it back to the minimum when empty and oversized.
    """
    let needs_grow = match \exhaustive\ _tcp_buffer_until()
    | let e: BufferSize => _read_buffer.size() <= e()
    | Streaming => _read_buffer.size() == 0
    end
    if needs_grow then
      _read_buffer.undefined(_read_buffer_size)
    elseif (_bytes_in_read_buffer == 0)
      and (_read_buffer_size > _read_buffer_min)
    then
      _read_buffer_size = _read_buffer_min
      _read_buffer = recover iso
        let a = Array[U8](_read_buffer_size)
        a.undefined(_read_buffer_size)
        a
      end
    end

  fun ref _queue_read() =>
    ifdef posix then
      // Trigger a read in case we ignored any previous ASIO notifications
      match \exhaustive\ _enclosing
      | let e: TCPConnectionActor ref =>
        e._read_again()
        return
      | None =>
        _Unreachable()
      end
    else
      _iocp_read()
    end

  fun ref _apply_backpressure() =>
    match \exhaustive\ _lifecycle_event_receiver
    | let s: EitherLifecycleEventReceiver =>
      if not _throttled then
        _throttled = true
        // throttled means we are also unwriteable
        // being unthrottled doesn't however mean we are writable
        _set_unwriteable()
        ifdef not windows then
          PonyAsio.resubscribe_write(_event)
        end
        s._on_throttled()
      end
    | None =>
      _Unreachable()
    end

  fun ref _release_backpressure() =>
    match \exhaustive\ _lifecycle_event_receiver
    | let s: EitherLifecycleEventReceiver =>
      if _throttled then
        _throttled = false
        s._on_unthrottled()
      end
    | None =>
      _Unreachable()
    end

  fun ref _fire_on_sent(token: SendToken) =>
    """
    Dispatch _on_sent to the lifecycle event receiver. Called from
    _notify_sent behavior on TCPConnectionActor.
    """
    match \exhaustive\ _lifecycle_event_receiver
    | let s: EitherLifecycleEventReceiver ref =>
      s._on_sent(token)
    | None =>
      _Unreachable()
    end

  fun ref _fire_on_send_failed(token: SendToken) =>
    """
    Dispatch _on_send_failed to the lifecycle event receiver. Called from
    _notify_send_failed behavior on TCPConnectionActor.
    """
    match \exhaustive\ _lifecycle_event_receiver
    | let s: EitherLifecycleEventReceiver ref =>
      s._on_send_failed(token)
    | None =>
      _Unreachable()
    end

  fun ref _arm_idle_timer() =>
    """
    Create the ASIO timer event for idle timeout. Called when the connection
    establishes and `_idle_timeout_nsec > 0`, or when `idle_timeout()` is
    called on an established connection.

    Idempotent — if a timer already exists, this is a no-op. Prevents ASIO
    timer event leaks from double-arm scenarios.
    """
    if _idle_timeout_nsec == 0 then return end
    if not _timer_event.is_null() then return end
    match \exhaustive\ _enclosing
    | let e: TCPConnectionActor ref =>
      _timer_event = PonyAsio.create_timer_event(e, _idle_timeout_nsec)
    | None =>
      _Unreachable()
    end

  fun ref _reset_idle_timer() =>
    """
    Reset the idle timer to the configured duration. Called on I/O activity
    (successful send, data received). Only resets an existing timer — does
    not create one.
    """
    if not _timer_event.is_null() then
      PonyAsio.set_timer(_timer_event, _idle_timeout_nsec)
    end

  fun ref _cancel_idle_timer() =>
    """
    Cancel the idle timer. Unsubscribes and clears `_timer_event`
    immediately. The stale disposable notification (if any) no longer
    matches `_timer_event` and is destroyed by `_event_notify`'s else
    branch disposable check.
    """
    if not _timer_event.is_null() then
      PonyAsio.unsubscribe(_timer_event)
      _timer_event = AsioEvent.none()
      _idle_timeout_nsec = 0
    end

  fun ref _fire_idle_timeout() =>
    """
    Dispatch _on_idle_timeout to the lifecycle event receiver, then re-arm
    the timer if the connection is still open and the timeout is still
    configured.
    """
    match \exhaustive\ _lifecycle_event_receiver
    | let s: EitherLifecycleEventReceiver ref =>
      s._on_idle_timeout()
    | None =>
      _Unreachable()
    end
    if is_open() and (_idle_timeout_nsec > 0) then
      _reset_idle_timer()
    end

  fun ref _arm_connect_timer() =>
    """
    Create the ASIO timer event for the connect timeout. Called after
    `PonyTCP.connect` succeeds (at least one connection attempt is inflight).
    No-op when `_connect_timeout_nsec == 0` (no timeout configured).
    """
    if _connect_timeout_nsec == 0 then return end
    match \exhaustive\ _enclosing
    | let e: TCPConnectionActor ref =>
      _connect_timer_event =
        PonyAsio.create_timer_event(e, _connect_timeout_nsec)
    | None =>
      _Unreachable()
    end

  fun ref _cancel_connect_timer() =>
    """
    Cancel the connect timeout timer. Unsubscribes and clears
    `_connect_timer_event` immediately. Stale disposable notifications
    no longer match `_connect_timer_event` and are destroyed by
    `_event_notify`'s else branch disposable check.
    """
    if not _connect_timer_event.is_null() then
      PonyAsio.unsubscribe(_connect_timer_event)
      _connect_timer_event = AsioEvent.none()
      _connect_timeout_nsec = 0
    end

  fun ref _fire_connect_timeout() =>
    """
    The connect timeout has fired. Sets `_connect_timed_out` so that
    `hard_close()` routes the failure to `ConnectionFailedTimeout`, then
    cancels the timer and hard-closes the connection.
    """
    _connect_timed_out = true
    _cancel_connect_timer()
    hard_close()

  fun ref _fire_user_timer() =>
    """
    Dispatch `_on_timer` to the lifecycle event receiver. Called from
    `_event_notify` when the user timer event fires.

    The token and event are cleared before the callback. If the callback
    calls `set_timer()`, it creates a fresh ASIO event. The old event's
    disposable notification arrives later, doesn't match
    `_user_timer_event`, and is destroyed by `_event_notify`'s else
    branch disposable check.
    """
    let token = _user_timer_token
    _user_timer_token = None
    PonyAsio.unsubscribe(_user_timer_event)
    _user_timer_event = AsioEvent.none()
    match (token, _lifecycle_event_receiver)
    | (let t: TimerToken, let s: EitherLifecycleEventReceiver ref) =>
      s._on_timer(t)
    | (None, _) =>
      _Unreachable()
    | (_, None) =>
      _Unreachable()
    end

  fun ref _cancel_user_timer() =>
    """
    Cancel the user timer without firing the callback. Called from both
    hard-close paths during cleanup. Stale disposable notifications no
    longer match `_user_timer_event` and are destroyed by
    `_event_notify`'s else branch disposable check.
    """
    if not _user_timer_event.is_null() then
      PonyAsio.unsubscribe(_user_timer_event)
      _user_timer_event = AsioEvent.none()
      _user_timer_token = None
    end

  fun ref _ssl_flush_sends() =>
    """
    Flush any pending encrypted data from the SSL session to the wire.
    Called after SSL operations that may produce output (handshake, write).
    Enqueues all SSL chunks, then flushes once via writev.
    """
    match _ssl
    | let ssl: SSL ref =>
      try
        while ssl.can_send() do
          _enqueue(ssl.send()?)
        end
      end
      ifdef windows then
        _iocp_submit_pending()
      else
        _send_pending_writes()
      end
    end

  fun ref _ssl_poll(s: EitherLifecycleEventReceiver ref) =>
    """
    Check SSL state after receiving data. Handles handshake completion,
    error detection, decrypted data delivery, and protocol data flushing.
    """
    match _ssl
    | let ssl: SSL ref =>
      match ssl.state()
      | SSLReady =>
        if not _ssl_ready then
          _ssl_ready = true
          _state.ssl_handshake_complete(this, s)
        end
      | SSLAuthFail =>
        _ssl_auth_failed = true
        hard_close()
        return
      | SSLError =>
        hard_close()
        return
      end

      // Read all available decrypted data
      let ssl_read_buffer_until: USize = match \exhaustive\ _buffer_until
      | let e: BufferSize => e()
      | Streaming => 0
      end
      while true do
        match \exhaustive\ ssl.read(ssl_read_buffer_until)
        | let d: Array[U8] iso => s._on_received(consume d)
        | None => break
        end
      end

      // Flush any SSL protocol data (handshake responses, etc.)
      _ssl_flush_sends()
    end

  fun _has_pending_writes(): Bool =>
    _pending_writev_total > 0

  fun ref read_again() =>
    _state.read_again(this)

  fun ref _dispatch_io_event(flags: U32, arg: U32) =>
    """
    Common I/O dispatch logic for socket events. Shared by all states that
    have a connected socket and need to process I/O notifications.
    """
    if AsioEvent.writeable(flags) then
      _set_writeable()
      ifdef windows then
        _write_completed(arg)
      else
        _send_pending_writes()
      end
    end

    if AsioEvent.readable(flags) then
      _set_readable()
      ifdef windows then
        _read_completed(arg)
      else
        _read()
      end
    end

  fun ref _do_read_again() =>
    ifdef posix then
      _read()
    else
      _windows_resume_read()
    end

  fun ref _set_state(state: _ConnectionState ref) =>
    _state = state

  fun ref _decrement_inflight(): U32 =>
    _inflight_connections = _inflight_connections - 1
    _inflight_connections

  fun ref _establish_connection(event: AsioEventID, fd: U32) =>
    """
    Called by _ClientConnecting when a Happy Eyeballs connection succeeds.
    Promotes the event to the connection's own event, transitions to the
    appropriate state, and sets up the connection for I/O.
    """
    _event = event
    _fd = fd
    _set_writeable()
    _set_readable()

    match \exhaustive\ _ssl
    | let _: SSL ref =>
      _state = _SSLHandshaking
      // Flush ClientHello to initiate SSL handshake.
      // _on_connected() and _arm_idle_timer() deferred until
      // ssl_handshake_complete.
      _ssl_flush_sends()
    | None =>
      _state = _Open
      _arm_idle_timer()
      _cancel_connect_timer()
      match _lifecycle_event_receiver
      | let c: ClientLifecycleEventReceiver ref =>
        c._on_connected()
      end
    end

    ifdef windows then
      _queue_read()
    else
      _read()
      if _has_pending_writes() then
        _send_pending_writes()
      end
    end

  fun ref _connecting_event_failed(event: AsioEventID, fd: U32) =>
    """
    Called by _ClientConnecting when a Happy Eyeballs connection attempt
    fails. Closes the fd and fires the connecting callback. Only
    unsubscribes if the event hasn't already been unsubscribed — on
    non-Windows systems, a race can cause the event to already be
    disposable by the time we process it (see stdlib TCPConnection).
    """
    // The message flags and the event struct's disposable status can
    // disagree: a stale message may carry writeable/readable flags while
    // the event struct has already been marked disposable by a prior
    // unsubscribe. Check the struct before unsubscribing.
    if not PonyAsio.get_disposable(event) then
      PonyAsio.unsubscribe(event)
    end
    PonyTCP.close(fd)
    _connecting_callback()

  fun ref _straggler_cleanup(event: AsioEventID) =>
    """
    Clean up a Happy Eyeballs straggler event after the winner has been
    chosen. Unsubscribes (if not already disposable) and closes the fd.
    Does NOT decrement _inflight_connections — caller handles that.
    """
    // The message flags and the event struct's disposable status can
    // disagree: a stale message may carry writeable/readable flags while
    // the event struct has already been marked disposable by a prior
    // unsubscribe. Check the struct before unsubscribing.
    if not PonyAsio.get_disposable(event) then
      PonyAsio.unsubscribe(event)
    end
    PonyTCP.close(PonyAsio.event_fd(event))

  fun ref _event_notify(event: AsioEventID, flags: U32, arg: U32) =>
    // Explicit dispatch on event identity. Timer identity checks must come
    // before `event is _event`. The else branch checks disposable first
    // (stale timer disposables, straggler disposables), otherwise dispatches
    // to foreign_event for Happy Eyeballs stragglers.
    if event is _connect_timer_event then
      _fire_connect_timeout()
    elseif event is _timer_event then
      _fire_idle_timeout()
    elseif event is _user_timer_event then
      _fire_user_timer()
    elseif event is _event then
      _state.own_event(this, flags, arg)
      // A callback during own_event (e.g., _read_completed(0) → close()) can
      // transition to _Closing and set _shutdown/_shutdown_peer, but
      // _Open.own_event() won't check for shutdown completion. This ensures
      // the check runs after every own-event dispatch, regardless of which
      // state handled it.
      _check_shutdown_complete()
      if AsioEvent.disposable(flags) then
        PonyAsio.destroy(event)
        _event = AsioEvent.none()
      end
    else
      // AsioEvent.disposable(flags)
      if AsioEvent.disposable(flags) then
        PonyAsio.destroy(event)
      else
        _state.foreign_event(this, event, flags, arg)
      end

      // if AsioEvent.disposable(flags) then
      //   PonyAsio.destroy(event)
      // end
    end

  fun ref _connecting_callback() =>
    match \exhaustive\ _lifecycle_event_receiver
    | let c: ClientLifecycleEventReceiver ref =>
      if _inflight_connections > 0 then
        c._on_connecting(_inflight_connections)
      else
        hard_close()
      end
    | let s: ServerLifecycleEventReceiver ref =>
      _Unreachable()
    | None =>
      _Unreachable()
    end

  fun _is_socket_connected(fd: U32): Bool =>
    ifdef windows then
      (let errno: U32, let value: U32) = _OSSocket.get_so_connect_time(fd)
      (errno == 0) and (value != 0xffffffff)
    else
      (let errno: U32, let value: U32) = _OSSocket.get_so_error(fd)
      (errno == 0) and (value == 0)
    end

  fun ref _register_spawner(listener: TCPListenerActor) =>
    if _spawned_by is None then
      if not _state.is_closed() then
        // We were connected by the time the spawner was registered,
        // so, let's let it know we were connected
        _spawned_by = listener
      else
        // We were closed by the time the spawner was registered,
        // so, let's let it know we were closed, And leave our "spawned by" as
        // None.
        listener._connection_closed()
      end
    else
      _Unreachable()
    end

  fun ref _finish_initialization() =>
    match \exhaustive\ _lifecycle_event_receiver
    | let s: ServerLifecycleEventReceiver ref =>
      _complete_server_initialization(s)
    | let c: ClientLifecycleEventReceiver ref =>
      _complete_client_initialization(c)
    | None =>
      _Unreachable()
    end

  fun ref _complete_client_initialization(
    s: ClientLifecycleEventReceiver ref)
  =>
    if _ssl_failed then
      _state = _Closed
      s._on_connection_failure(ConnectionFailedSSL)
      return
    end

    match \exhaustive\ _enclosing
    | let e: TCPConnectionActor ref =>
      _state = _ClientConnecting

      let asio_flags = ifdef windows then
        AsioEvent.read_write()
      else
        AsioEvent.read_write_oneshot()
      end

      _inflight_connections = PonyTCP.connect(e, _host, _port, _from,
        asio_flags where ip_version = _ip_version)
      _had_inflight = _inflight_connections > 0
      if _had_inflight then
        _arm_connect_timer()
      end
      _connecting_callback()
    | None =>
      _Unreachable()
    end

  fun ref _complete_server_initialization(
    s: ServerLifecycleEventReceiver ref)
  =>
    if _ssl_failed then
      PonyTCP.close(_fd)
      _fd = -1
      _state = _Closed
      s._on_start_failure(StartFailedSSL)
      return
    end

    match \exhaustive\ _enclosing
    | let e: TCPConnectionActor ref =>
      _event = PonyAsio.create_event(e, _fd)
      _set_readable()
      _set_writeable()

      match \exhaustive\ _ssl
      | let _: SSL ref =>
        _state = _SSLHandshaking
        // Flush any initial SSL data (usually no-op for servers).
        // _on_started() and _arm_idle_timer() deferred until
        // ssl_handshake_complete.
        _ssl_flush_sends()
      | None =>
        _state = _Open
        _arm_idle_timer()
        s._on_started()
      end

      // Queue up reads as we are now connected
      // But might have been in a race with ASIO
      _queue_read()
    | None =>
      _Unreachable()
    end

  fun ref _set_readable() =>
    _readable = true
    PonyAsio.set_readable(_event)

  fun ref _set_unreadable() =>
    _readable = false
    PonyAsio.set_unreadable(_event)

  fun ref _set_writeable() =>
    _writeable = true
    PonyAsio.set_writeable(_event)

  fun ref _set_unwriteable() =>
    _writeable = false
    PonyAsio.set_unwriteable(_event)
