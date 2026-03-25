use lori = "lori"

primitive _DefaultIdleTimeout
  """
  60-second idle timeout, the default for HTTP client connections.
  """
  fun apply(): (lori.IdleTimeout | None) =>
    match lori.MakeIdleTimeout(60_000)
    | let t: lori.IdleTimeout => t
    else
      _Unreachable()
      None
    end

class val ClientConnectionConfig
  """
  Configuration for an HTTP client connection.

  Parser limits control the maximum size of response components. Idle timeout
  controls how long the connection can sit without I/O activity before the
  library closes it. Connection timeout bounds how long the initial connection
  handshake is allowed to take. `from` specifies the local bind address (empty
  string means any interface).

  ```pony
  // All defaults (60-second idle timeout, 10 MB max body)
  ClientConnectionConfig

  // Custom idle timeout via MakeIdleTimeout (milliseconds)
  let timeout = match lori.MakeIdleTimeout(30_000)
  | let t: lori.IdleTimeout => t
  end
  ClientConnectionConfig(where
    max_body_size' = 52_428_800,  // 50 MB
    idle_timeout' = timeout)

  // Disable idle timeout
  ClientConnectionConfig(where idle_timeout' = None)

  // Set a 5-second connection timeout
  let ct = match lori.MakeConnectionTimeout(5_000)
  | let t: lori.ConnectionTimeout => t
  end
  ClientConnectionConfig(where connection_timeout' = ct)
  ```
  """
  let max_status_line_size: USize
  let max_header_size: USize
  let max_chunk_header_size: USize
  let max_body_size: USize
  let idle_timeout: (lori.IdleTimeout | None)
  let connection_timeout: (lori.ConnectionTimeout | None)
  let from: String

  new val create(
    max_status_line_size': USize = 8192,
    max_header_size': USize = 8192,
    max_chunk_header_size': USize = 128,
    max_body_size': USize = 10_485_760,
    idle_timeout': (lori.IdleTimeout | None) = _DefaultIdleTimeout(),
    connection_timeout': (lori.ConnectionTimeout | None) = None,
    from': String = "")
  =>
    """
    Create client connection configuration.

    Parser limits default to sensible values. `idle_timeout'` is an
    `IdleTimeout` (milliseconds) or `None` to disable idle timeout. Defaults
    to 60 seconds. `connection_timeout'` is a `ConnectionTimeout`
    (milliseconds) or `None` to disable connection timeout. Defaults to
    `None`. `from'` specifies the local bind address (empty string means any
    interface).
    """
    max_status_line_size = max_status_line_size'
    max_header_size = max_header_size'
    max_chunk_header_size = max_chunk_header_size'
    max_body_size = max_body_size'
    idle_timeout = idle_timeout'
    connection_timeout = connection_timeout'
    from = from'

  fun _parser_config(): _ParserConfig val =>
    """
    Create a parser config from the parser limit fields.
    """
    _ParserConfig(
      max_status_line_size,
      max_header_size,
      max_chunk_header_size,
      max_body_size)
