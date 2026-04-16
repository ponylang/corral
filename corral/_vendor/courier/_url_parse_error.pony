interface val _URLParseError is Stringable

primitive MissingScheme is _URLParseError
  """
  URL has no `://` separator or the scheme portion is empty.
  """
  fun string(): String iso^ => "MissingScheme".clone()

primitive UnsupportedScheme is _URLParseError
  """
  URL scheme is not `http` or `https`.
  """
  fun string(): String iso^ => "UnsupportedScheme".clone()

primitive MissingHost is _URLParseError
  """
  URL has an empty host component.
  """
  fun string(): String iso^ => "MissingHost".clone()

primitive InvalidPort is _URLParseError
  """
  Port is non-numeric, zero, or exceeds 65535.
  """
  fun string(): String iso^ => "InvalidPort".clone()

primitive UserInfoNotSupported is _URLParseError
  """
  URL contains userinfo (`user@` or `user:pass@`), which is not supported.
  """
  fun string(): String iso^ => "UserInfoNotSupported".clone()
