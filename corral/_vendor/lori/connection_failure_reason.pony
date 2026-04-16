primitive ConnectionFailedDNS
  """
  Name resolution failed — no IP addresses could be resolved for the
  given host. No TCP connections were attempted.
  """

primitive ConnectionFailedTCP
  """
  Name resolution succeeded but all TCP connection attempts failed. At least
  one IP address was resolved, but no connection could be established.
  """

primitive ConnectionFailedSSL
  """
  The TCP connection was established but the SSL handshake failed. This
  covers both SSL session creation failures (e.g. bad `SSLContext`) and
  handshake protocol errors before `_on_connected` would have fired.
  """

primitive ConnectionFailedTimeout
  """
  The connection attempt timed out before completing. The timer covers
  TCP Happy Eyeballs and (for SSL connections) the TLS handshake. The
  timeout is configured via the `connection_timeout` parameter on the
  `client` or `ssl_client` constructor.
  """

type ConnectionFailureReason is
  ( ConnectionFailedDNS
  | ConnectionFailedTCP
  | ConnectionFailedSSL
  | ConnectionFailedTimeout )
