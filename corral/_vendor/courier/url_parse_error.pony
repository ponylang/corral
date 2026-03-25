type URLParseError is
  ( MissingScheme
  | UnsupportedScheme
  | MissingHost
  | InvalidPort
  | UserInfoNotSupported )
