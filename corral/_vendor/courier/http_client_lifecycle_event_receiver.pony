use lori = "lori"

trait ref HTTPClientLifecycleEventReceiver
  """
  HTTP response lifecycle callbacks delivered to the client actor.

  All callbacks have default no-op implementations. Override only the
  callbacks your actor needs. Callbacks are invoked synchronously inside
  the actor that owns the `HTTPClientConnection`.

  Typical usage: override `on_connected()` to send the first request,
  `on_response()` and `on_body_chunk()` to process the response, and
  `on_response_complete()` to send follow-up requests or close.
  """

  fun ref on_connected() =>
    """
    Called when the connection is ready for application data.

    For plain TCP connections, this fires after TCP connect. For SSL
    connections, this fires after the TLS handshake completes. Safe to call
    `send_request()` from this callback.
    """
    None

  fun ref on_connection_failure(reason: ConnectionFailureReason) =>
    """
    Called when a connection attempt fails.

    The `reason` indicates which stage failed: DNS resolution, TCP connect,
    SSL handshake, or connection timeout. The connection is unusable after
    this callback.
    """
    None

  fun ref on_response(response: Response val) =>
    """
    Called when the response status line and all headers have been parsed.

    For responses with a body, `on_body_chunk()` calls follow. For responses
    without a body (HEAD, 204, 304), `on_response_complete()` is called
    immediately after.
    """
    None

  fun ref on_body_chunk(data: Array[U8] val) =>
    """
    Called for each chunk of response body data as it arrives.

    Body data is delivered incrementally. Accumulate chunks manually if
    you need the complete body before processing.
    """
    None

  fun ref on_response_complete() =>
    """
    Called when the entire response (including any body) has been received.

    After this call, the connection is ready for another `send_request()`
    (connection reuse / keep-alive).
    """
    None

  fun ref on_parse_error(err: ParseError) =>
    """
    Called when a response parse error is encountered.

    The connection is closed after this callback. No further callbacks
    will be delivered except `on_closed()`.
    """
    None

  fun ref on_closed() =>
    """
    Called when the connection closes.

    Fires on remote disconnect, local close, idle timeout, or any other
    reason. Not called if the connection fails before connecting (use
    `on_connection_failure` for that case).
    """
    None

  fun ref on_throttled() =>
    """
    Called when backpressure is applied on the connection.

    The TCP send buffer is full — avoid sending more requests until
    `on_unthrottled()` is called.
    """
    None

  fun ref on_unthrottled() =>
    """
    Called when backpressure is released on the connection.

    The TCP send buffer has drained — request sending may resume.
    """
    None

  fun ref on_timer(token: lori.TimerToken) =>
    """
    Called when a one-shot timer created by `HTTPClientConnection.set_timer()`
    fires.

    The `token` matches the one returned by `set_timer()`. Fires once per
    `set_timer()` call. The timer is consumed before the callback, so it is
    safe to call `set_timer()` from within `on_timer()` to re-arm. No
    automatic re-arming occurs.

    Unlike idle timeout, this timer has no I/O-reset behavior — it fires
    unconditionally after the configured duration, regardless of send/receive
    activity.
    """
    None
