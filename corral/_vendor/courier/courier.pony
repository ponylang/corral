"""
courier — HTTP client for Pony.

Courier is an HTTP/1.1 client library built on
[lori](https://github.com/ponylang/lori). It follows the same architectural
pattern as lori and [stallion](https://github.com/ponylang/stallion): a
protocol handler class (`HTTPClientConnection`) owned by the user's actor,
with synchronous `fun ref` callbacks. No hidden actors.

## Getting Started

Implement `HTTPClientConnectionActor` on your actor, store an
`HTTPClientConnection` as a field, and override the lifecycle callbacks
you need:

```pony
use "courier"
use lori = "lori"

actor MyClient is HTTPClientConnectionActor
  var _http: HTTPClientConnection = HTTPClientConnection.none()
  let _out: OutStream

  new create(auth: lori.TCPConnectAuth, host: String, port: String,
    out: OutStream)
  =>
    _out = out
    _http = HTTPClientConnection(auth, host, port, this,
      ClientConnectionConfig)

  fun ref _http_client_connection(): HTTPClientConnection => _http

  fun ref on_connected() =>
    _http.send_request(HTTPRequest(GET, "/"))

  fun ref on_response(response: Response val) =>
    _out.print(response.status.string() + " " + response.reason)

  fun ref on_body_chunk(data: Array[U8] val) =>
    _out.write(data)

  fun ref on_response_complete() =>
    _out.print("")
    _http.close()
```

For HTTPS, use `HTTPClientConnection.ssl()` instead of
`HTTPClientConnection()`.

## One-Shot Timers

For response deadlines or application-level timeouts, use
`HTTPClientConnection.set_timer()`. Unlike idle timeout, this timer fires
unconditionally — I/O activity does not reset it. Only one timer can be active
per connection at a time. The typical pattern is a response deadline: set a
timer
after sending a request, cancel it when the response completes, close the
connection if the timer fires:

```pony
actor MyClient is HTTPClientConnectionActor
  var _http: HTTPClientConnection = HTTPClientConnection.none()
  var _timer: (lori.TimerToken | None) = None
  let _out: OutStream

  // ... constructor ...

  fun ref _http_client_connection(): HTTPClientConnection => _http

  fun ref on_connected() =>
    _http.send_request(Request.get("/slow-endpoint").build())
    match lori.MakeTimerDuration(5_000)
    | let d: lori.TimerDuration =>
      match _http.set_timer(d)
      | let t: lori.TimerToken => _timer = t
      | let err: lori.SetTimerError => None
      end
    end

  fun ref on_response_complete() =>
    match _timer
    | let t: lori.TimerToken =>
      _http.cancel_timer(t)
      _timer = None
    end
    // process response...
    _http.close()

  fun ref on_timer(token: lori.TimerToken) =>
    match _timer
    | let t: lori.TimerToken if t == token =>
      _timer = None
      _out.print("Response timed out")
      _http.close()
    end
```

## Key Types

- `HTTPClientConnectionActor` — trait for your actor
- `HTTPClientConnection` — protocol handler class (stored as actor field)
- `HTTPClientLifecycleEventReceiver` — callback trait (default no-ops)
- `HTTPRequest` — request data (method, path, headers, body)
- `Response` — parsed response metadata (version, status, reason, headers)
- `ClientConnectionConfig` — parser limits, idle timeout, connection timeout,
  bind address
- `SendRequestResult` — result of `send_request()` (success or error)
- `ConnectionFailureReason` — reason a connection attempt failed
  (`ConnectionFailedDNS`, `ConnectionFailedTCP`, `ConnectionFailedSSL`,
  `ConnectionFailedTimeout`)
- `lori.TimerToken` — opaque token for timer cancellation and matching
- `lori.TimerDuration` — validated timer duration (use
  `lori.MakeTimerDuration(milliseconds)` to create)
- `lori.SetTimerError` — timer setup failure (`lori.SetTimerAlreadyActive`,
  `lori.SetTimerNotOpen`)
- `HTTPResponse` — buffered response with complete body
  (from `ResponseCollector`)
- `ResponseCollector` — accumulates streaming callbacks into `HTTPResponse`
- `QueryParams` — RFC 3986 query string encoding
- `FormEncoder` — `application/x-www-form-urlencoded` body encoding
- `BasicAuth` — HTTP Basic authentication header
- `BearerAuth` — HTTP Bearer token authentication header
- `Request` — factory for typed step-builder request construction
- `RequestOptions` — builder interface for all methods (headers, query, auth)
- `RequestOptionsWithBody` — builder interface with body methods (POST, etc.)
- `MultipartFormData` — `multipart/form-data` builder for file uploads and
  mixed form submissions; use with `multipart_body()` on the request builder.
  For simple key-value form data without files, use `FormEncoder`/`form_body()`
  instead.
- `URL` — parse URL strings into `ParsedURL` components
- `ParsedURL` — parsed URL with scheme, host, port, path, and optional query
- `Scheme` — URL scheme (`SchemeHTTP` or `SchemeHTTPS`)
- `URLParseError` — error encountered during URL parsing
- `ResponseJSON` — parse `HTTPResponse` body as JSON
- `JSONDecoder` — interface for typed JSON decoders
- `JSONDecodeError` — decode failure with descriptive message
- `DecodeJSON` — parse and decode an HTTP response body in one step

## Design

See [Discussion #2](https://github.com/ponylang/courier/discussions/2) for
the full design rationale.
"""
