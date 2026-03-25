interface val _Scheme is (Equatable[Scheme] & Stringable)

primitive SchemeHTTP is _Scheme
  """
  HTTP scheme (unencrypted).
  """
  fun string(): String iso^ => "http".clone()
  fun eq(that: Scheme): Bool => that is this

primitive SchemeHTTPS is _Scheme
  """
  HTTPS scheme (TLS-encrypted).
  """
  fun string(): String iso^ => "https".clone()
  fun eq(that: Scheme): Bool => that is this
