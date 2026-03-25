type ConnectionFailureReason is
  ( ConnectionFailedDNS
  | ConnectionFailedTCP
  | ConnectionFailedSSL
  | ConnectionFailedTimeout )
  """
  Reason a connection attempt failed, delivered via `on_connection_failure()`.
  """
