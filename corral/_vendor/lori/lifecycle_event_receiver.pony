trait ServerLifecycleEventReceiver
  """
  Application-level callbacks for server-side TCP connections.
  One receiver per connection, no chaining.
  """
  fun ref _connection(): TCPConnection

  fun ref _on_started() =>
    """
    Called when a server connection is ready for application data.
    """
    None

  fun ref _on_closed() =>
    """
    Called when the connection is closed.
    """
    None

  fun ref _on_received(data: Array[U8] iso) =>
    """
    Called each time data is received on this connection.
    """
    None

  fun ref _on_throttled() =>
    """
    Called when we start experiencing backpressure.
    """
    None

  fun ref _on_unthrottled() =>
    """
    Called when backpressure is released.
    """
    None

  fun ref _on_sent(token: SendToken) =>
    """
    Called when data from a successful `send()` has been fully handed to
    the OS. The token matches the one returned by the `send()` call.

    Always fires in a subsequent behavior turn, never synchronously during
    `send()`. This guarantees the caller has received and processed the
    `SendToken` return value before the callback arrives.
    """
    None

  fun ref _on_send_failed(token: SendToken) =>
    """
    Called when data from a successful `send()` could not be delivered to
    the OS. The token matches the one returned by the `send()` call. This
    happens when a connection closes while a partial write is still pending.

    Always fires in a subsequent behavior turn, never synchronously during
    `hard_close()`. Always arrives after `_on_closed`, which fires
    synchronously during `hard_close()`.
    """
    None

  fun ref _on_start_failure(reason: StartFailureReason) =>
    """
    Called when a server connection fails to start. This covers failures
    that occur before _on_started would have fired, such as an SSL
    handshake failure. The application was never notified of the connection
    via _on_started.

    The `reason` parameter identifies the cause of the failure. Currently
    the only reason is `StartFailedSSL` (SSL session creation or handshake
    failure).
    """
    None

  fun ref _on_tls_ready() =>
    """
    Called when a TLS handshake initiated by `start_tls()` completes
    successfully. The connection is now encrypted and ready for
    application data over TLS.
    """
    None

  fun ref _on_tls_failure(reason: TLSFailureReason) =>
    """
    Called when a TLS handshake initiated by `start_tls()` fails. Fires
    synchronously during `hard_close()`, immediately before `_on_closed()`.
    The connection was already established (the application received
    `_on_started` earlier), so `_on_closed` always follows to signal
    connection teardown.

    The `reason` parameter distinguishes authentication failures
    (`TLSAuthFailed`) from other protocol errors (`TLSGeneralError`).
    """
    None

  fun ref _on_idle_timeout() =>
    """
    Called when no successful send or receive has occurred for the duration
    configured by `idle_timeout()`. This measures application-level inactivity,
    not wire-level: pending OS write buffer drains and failed sends
    (`SendErrorNotWriteable`) do not count as activity.

    The timer automatically re-arms after each firing. Call
    `idle_timeout(None)` to disable it. The application decides what action
    to take — close the connection, send a keepalive, log a warning, etc.
    """
    None

  fun ref _on_timer(token: TimerToken) =>
    """
    Called when a one-shot timer created by `set_timer()` fires. The token
    matches the one returned by `set_timer()`.

    Fires once per `set_timer()` call. The timer is consumed before the
    callback, so it is safe to call `set_timer()` from within `_on_timer()`
    to re-arm. No automatic re-arming occurs.
    """
    None

trait ClientLifecycleEventReceiver
  """
  Application-level callbacks for client-side TCP connections.
  One receiver per connection, no chaining.
  """
  fun ref _connection(): TCPConnection

  fun ref _on_connecting(inflight_connections: U32) =>
    """
    Called if name resolution succeeded for a TCPConnection and we are now
    waiting for a connection to the server to succeed. The count is the number
    of connections we're trying. This callback will be called each time the
    count changes, until a connection is made or _on_connection_failure is
    called.
    """
    None

  fun ref _on_connected() =>
    """
    Called when a connection is ready for application data.
    """
    None

  fun ref _on_connection_failure(reason: ConnectionFailureReason) =>
    """
    Called when a connection fails to open. For SSL connections, this is
    also called when the SSL handshake fails before _on_connected would
    have been delivered, since the application was never notified of the
    connection.

    The `reason` parameter identifies the failure stage:
    `ConnectionFailedDNS` (name resolution failed), `ConnectionFailedTCP`
    (resolved but all TCP attempts failed), `ConnectionFailedSSL`
    (TCP connected but SSL handshake failed), or `ConnectionFailedTimeout`
    (the connection attempt timed out before completing).
    """
    None

  fun ref _on_closed() =>
    """
    Called when the connection is closed.
    """
    None

  fun ref _on_received(data: Array[U8] iso) =>
    """
    Called each time data is received on this connection.
    """
    None

  fun ref _on_throttled() =>
    """
    Called when we start experiencing backpressure.
    """
    None

  fun ref _on_unthrottled() =>
    """
    Called when backpressure is released.
    """
    None

  fun ref _on_sent(token: SendToken) =>
    """
    Called when data from a successful `send()` has been fully handed to
    the OS. The token matches the one returned by the `send()` call.

    Always fires in a subsequent behavior turn, never synchronously during
    `send()`. This guarantees the caller has received and processed the
    `SendToken` return value before the callback arrives.
    """
    None

  fun ref _on_send_failed(token: SendToken) =>
    """
    Called when data from a successful `send()` could not be delivered to
    the OS. The token matches the one returned by the `send()` call. This
    happens when a connection closes while a partial write is still pending.

    Always fires in a subsequent behavior turn, never synchronously during
    `hard_close()`. Always arrives after `_on_closed`, which fires
    synchronously during `hard_close()`.
    """
    None

  fun ref _on_tls_ready() =>
    """
    Called when a TLS handshake initiated by `start_tls()` completes
    successfully. The connection is now encrypted and ready for
    application data over TLS.
    """
    None

  fun ref _on_tls_failure(reason: TLSFailureReason) =>
    """
    Called when a TLS handshake initiated by `start_tls()` fails. Fires
    synchronously during `hard_close()`, immediately before `_on_closed()`.
    The connection was already established (the application received
    `_on_connected` earlier), so `_on_closed` always follows to signal
    connection teardown.

    The `reason` parameter distinguishes authentication failures
    (`TLSAuthFailed`) from other protocol errors (`TLSGeneralError`).
    """
    None

  fun ref _on_idle_timeout() =>
    """
    Called when no successful send or receive has occurred for the duration
    configured by `idle_timeout()`. This measures application-level inactivity,
    not wire-level: pending OS write buffer drains and failed sends
    (`SendErrorNotWriteable`) do not count as activity.

    The timer automatically re-arms after each firing. Call
    `idle_timeout(None)` to disable it. The application decides what action
    to take — close the connection, send a keepalive, log a warning, etc.
    """
    None

  fun ref _on_timer(token: TimerToken) =>
    """
    Called when a one-shot timer created by `set_timer()` fires. The token
    matches the one returned by `set_timer()`.

    Fires once per `set_timer()` call. The timer is consumed before the
    callback, so it is safe to call `set_timer()` from within `_on_timer()`
    to re-arm. No automatic re-arming occurs.
    """
    None

type EitherLifecycleEventReceiver is
  (ServerLifecycleEventReceiver | ClientLifecycleEventReceiver)
