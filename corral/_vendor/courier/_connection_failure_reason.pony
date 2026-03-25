interface val _ConnectionFailureReason is Stringable

primitive ConnectionFailedDNS is _ConnectionFailureReason
  """
  DNS resolution failed. No TCP connection was attempted.
  """
  fun string(): String iso^ => "ConnectionFailedDNS".clone()

primitive ConnectionFailedTCP is _ConnectionFailureReason
  """
  TCP connection failed after DNS resolution succeeded.
  """
  fun string(): String iso^ => "ConnectionFailedTCP".clone()

primitive ConnectionFailedSSL is _ConnectionFailureReason
  """
  SSL handshake failed after TCP connection succeeded.
  """
  fun string(): String iso^ => "ConnectionFailedSSL".clone()

primitive ConnectionFailedTimeout is _ConnectionFailureReason
  """
  Connection attempt timed out before completing.
  """
  fun string(): String iso^ => "ConnectionFailedTimeout".clone()
