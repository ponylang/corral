use lori = "lori"
use ssl_net = "ssl/net"

primitive _Idle
primitive _AwaitingResponse

class HTTPClientConnection is
  (lori.ClientLifecycleEventReceiver & _ResponseParserNotify)
  """
  HTTP protocol handler that manages request serialization, response parsing,
  and connection lifecycle for a single HTTP client connection.

  Stored as a field inside an `HTTPClientConnectionActor`. Handles all
  HTTP-level concerns — serializing outgoing requests, parsing incoming
  responses, idle timeout scheduling, and backpressure — and delivers
  HTTP events to the actor via `HTTPClientLifecycleEventReceiver` callbacks.

  The protocol class implements lori's `ClientLifecycleEventReceiver`
  to receive TCP-level events from the connection, and
  `_ResponseParserNotify` to receive parser callbacks. It forwards
  HTTP-level events to the owning actor.

  Use `none()` as the field default so that `this` is `ref` in the
  actor constructor body, then replace with `create()` or `ssl()`:

  ```pony
  actor MyClient is HTTPClientConnectionActor
    var _http: HTTPClientConnection = HTTPClientConnection.none()

    new create(auth: lori.TCPConnectAuth, host: String, port: String,
      config: ClientConnectionConfig)
    =>
      _http = HTTPClientConnection(auth, host, port, this, config)
  ```
  """
  let _lifecycle_event_receiver:
    (HTTPClientLifecycleEventReceiver ref | None)
  let _config: (ClientConnectionConfig | None)
  let _host: String
  let _port: String
  var _tcp_connection: lori.TCPConnection = lori.TCPConnection.none()
  var _state: _ConnectionState = _Active
  var _request_state: (_Idle | _AwaitingResponse) = _Idle
  var _parser: (_ResponseParser | None) = None

  new none() =>
    """
    Create a placeholder protocol instance.

    Used as the default value for the `_http` field in
    `HTTPClientConnectionActor` implementations, allowing `this` to be `ref`
    in the actor constructor body. The placeholder is immediately replaced
    by `create()` or `ssl()` — its methods must never be called.
    """
    _lifecycle_event_receiver = None
    _config = None
    _host = ""
    _port = ""

  new create(
    auth: lori.TCPConnectAuth,
    host: String,
    port: String,
    client_actor: HTTPClientConnectionActor ref,
    config: ClientConnectionConfig)
  =>
    """
    Create the protocol handler for a plain HTTP connection.

    Called inside the `HTTPClientConnectionActor` constructor. The
    `client_actor` parameter must be the actor's `this` — it provides the
    `HTTPClientLifecycleEventReceiver ref` for synchronous HTTP callbacks.
    """
    _lifecycle_event_receiver = client_actor
    _config = config
    _host = host
    _port = port
    _parser = _ResponseParser(this, config._parser_config())
    _tcp_connection =
      lori.TCPConnection.client(
        auth,
        host,
        port,
        config.from,
        client_actor,
        this
        where connection_timeout = config.connection_timeout)

  new ssl(
    auth: lori.TCPConnectAuth,
    ssl_ctx: ssl_net.SSLContext val,
    host: String,
    port: String,
    client_actor: HTTPClientConnectionActor ref,
    config: ClientConnectionConfig)
  =>
    """
    Create the protocol handler for an HTTPS connection.

    Like `create`, but wraps the TCP connection in SSL using the provided
    `SSLContext`. Called inside the `HTTPClientConnectionActor` constructor
    for HTTPS connections.
    """
    _lifecycle_event_receiver = client_actor
    _config = config
    _host = host
    _port = port
    _parser = _ResponseParser(this, config._parser_config())
    _tcp_connection =
      lori.TCPConnection.ssl_client(
        auth,
        ssl_ctx,
        host,
        port,
        config.from,
        client_actor,
        this
        where connection_timeout = config.connection_timeout)

  fun ref _connection(): lori.TCPConnection =>
    """
    Return the underlying TCP connection.
    """
    _tcp_connection

  fun ref send_request(request: HTTPRequest val): SendRequestResult =>
    """
    Serialize and send an HTTP request.

    Returns `SendRequestOK` on success, `ConnectionClosed` if the connection
    is not open, or `ResponsePending` if a response to a previous request
    is still in progress.

    Auto-sets `Host` and `Content-Length` headers during serialization if
    they are not already present in the request.
    """
    match _state
    | let _: _Closed => return ConnectionClosed
    end

    match _request_state
    | let _: _AwaitingResponse => return ResponsePending
    end

    match _parser
    | let p: _ResponseParser => p.expect_response(request.method)
    end

    let serialized = _RequestSerializer(request, _host, _port)
    match _tcp_connection.send(consume serialized)
    | let _: lori.SendError =>
      _close_connection()
      return ConnectionClosed
    end

    _request_state = _AwaitingResponse
    SendRequestOK

  fun ref close() =>
    """
    Close the connection.

    Safe to call at any time; idempotent due to the `_Active` state guard
    in `_close_connection()`.
    """
    _close_connection()

  fun ref yield_read() =>
    """
    Exit the read loop after the current callback, giving other actors a
    chance to run. Reading resumes automatically on the next scheduler turn.

    Intended for use inside `on_body_chunk()` to prevent a single large
    response from starving other actors. Granularity is per-TCP-read, not
    per-HTTP-chunk — one TCP read may contain multiple chunks, and they will
    all be parsed before yielding. This is a one-shot flag; there is no
    corresponding "unmute" needed.

    No state guard is needed — if the connection is closed, the read loop
    is not running and the flag is harmless.
    """
    _tcp_connection.yield_read()

  fun ref set_timer(duration: lori.TimerDuration)
    : (lori.TimerToken | lori.SetTimerError)
  =>
    """
    Create a one-shot timer that fires `on_timer()` after the configured
    duration. Returns a `TimerToken` on success, or a `SetTimerError` on
    failure.

    Unlike idle timeout, this timer has no I/O-reset behavior — it fires
    unconditionally after the duration elapses, regardless of send/receive
    activity. There is no automatic re-arming; call `set_timer()` again from
    `on_timer()` for repetition.

    Only one timer can be active at a time. Setting a timer while one is
    already active returns `SetTimerAlreadyActive` — call `cancel_timer()`
    first. Requires the connection to be open; returns `SetTimerNotOpen` if
    not.

    Use `lori.MakeTimerDuration(milliseconds)` to create the duration value.
    `MakeTimerDuration` returns `(TimerDuration | ValidationFailure)`, so
    match on the result before passing it here.
    """
    _tcp_connection.set_timer(duration)

  fun ref cancel_timer(token: lori.TimerToken) =>
    """
    Cancel an active timer. No-op if the token doesn't match the active timer
    (already fired, already cancelled, wrong token). Safe to call with stale
    tokens.
    """
    _tcp_connection.cancel_timer(token)

  //
  // ClientLifecycleEventReceiver
  //
  fun ref _on_connected() =>
    match _config
    | let c: ClientConnectionConfig =>
      _tcp_connection.idle_timeout(c.idle_timeout)
    end
    match _lifecycle_event_receiver
    | let r: HTTPClientLifecycleEventReceiver ref => r.on_connected()
    end

  fun ref _on_connection_failure(reason: lori.ConnectionFailureReason) =>
    _state = _Closed
    let courier_reason: ConnectionFailureReason =
      match \exhaustive\ reason
      | lori.ConnectionFailedDNS => ConnectionFailedDNS
      | lori.ConnectionFailedTCP => ConnectionFailedTCP
      | lori.ConnectionFailedSSL => ConnectionFailedSSL
      | lori.ConnectionFailedTimeout => ConnectionFailedTimeout
      end
    match _lifecycle_event_receiver
    | let r: HTTPClientLifecycleEventReceiver ref =>
      r.on_connection_failure(courier_reason)
    end

  fun ref _on_received(data: Array[U8] iso) =>
    _state.on_received(this, consume data)

  fun ref _on_closed() =>
    _state.on_closed(this)

  fun ref _on_throttled() =>
    _state.on_throttled(this)

  fun ref _on_unthrottled() =>
    _state.on_unthrottled(this)

  fun ref _on_idle_timeout() =>
    _state.on_idle_timeout(this)

  fun ref _on_timer(token: lori.TimerToken) =>
    _state.on_timer(this, token)

  //
  // _ResponseParserNotify — forwarding parser events to receiver
  //
  fun ref response_received(
    status: U16,
    reason: String val,
    version: Version,
    headers: Headers val)
  =>
    match _lifecycle_event_receiver
    | let r: HTTPClientLifecycleEventReceiver ref =>
      r.on_response(Response(version, status, reason, headers))
    end

  fun ref body_chunk(data: Array[U8] val) =>
    match _lifecycle_event_receiver
    | let r: HTTPClientLifecycleEventReceiver ref =>
      r.on_body_chunk(data)
    end

  fun ref response_complete() =>
    _request_state = _Idle
    match _lifecycle_event_receiver
    | let r: HTTPClientLifecycleEventReceiver ref =>
      r.on_response_complete()
    end

  fun ref parse_error(err: ParseError) =>
    match _lifecycle_event_receiver
    | let r: HTTPClientLifecycleEventReceiver ref =>
      r.on_parse_error(err)
    end
    _close_connection()

  //
  // Internal methods called by state classes
  //
  fun ref _feed_parser(data: Array[U8] iso) =>
    """
    Feed incoming data to the response parser.
    """
    match _parser
    | let p: _ResponseParser => p.parse(consume data)
    end

  fun ref _handle_closed() =>
    """
    Handle remote connection close.

    For close-delimited bodies, `parser.connection_closed()` completes the
    response. For all other states, this just cleans up.
    """
    match _parser
    | let p: _ResponseParser =>
      p.connection_closed()
      p.stop()
    end
    match _lifecycle_event_receiver
    | let r: HTTPClientLifecycleEventReceiver ref => r.on_closed()
    end
    _state = _Closed

  fun ref _handle_throttled() =>
    """
    Apply backpressure: mute the TCP connection and notify the receiver.
    """
    _tcp_connection.mute()
    match _lifecycle_event_receiver
    | let r: HTTPClientLifecycleEventReceiver ref => r.on_throttled()
    end

  fun ref _handle_unthrottled() =>
    """
    Release backpressure: unmute the TCP connection and notify.
    """
    _tcp_connection.unmute()
    match _lifecycle_event_receiver
    | let r: HTTPClientLifecycleEventReceiver ref => r.on_unthrottled()
    end

  fun ref _handle_idle_timeout() =>
    """
    Close the connection on idle timeout.
    """
    _close_connection()

  fun ref _handle_timer(token: lori.TimerToken) =>
    """
    Forward one-shot timer firing to the receiver.
    """
    match \exhaustive\ _lifecycle_event_receiver
    | let r: HTTPClientLifecycleEventReceiver ref => r.on_timer(token)
    | None => _Unreachable()
    end

  fun ref _close_connection() =>
    """
    Close the connection and clean up all resources.

    User-initiated close does NOT call `parser.connection_closed()` — the
    user knows the response is abandoned. Remote close goes through
    `_handle_closed()` which does call `parser.connection_closed()`.

    Safe to call from within parser callbacks — the `_Active` state guard
    prevents double-close.
    """
    match _state
    | let _: _Active =>
      match _parser
      | let p: _ResponseParser => p.stop()
      end
      match _lifecycle_event_receiver
      | let r: HTTPClientLifecycleEventReceiver ref => r.on_closed()
      end
      _tcp_connection.close()
      _state = _Closed
    end
