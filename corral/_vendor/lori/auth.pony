primitive NetAuth
  new create(from: AmbientAuth) =>
    None

primitive TCPAuth
  new create(from: (AmbientAuth | NetAuth)) =>
    None

primitive TCPListenAuth
  new create(from: (AmbientAuth | NetAuth | TCPAuth)) =>
    None

primitive TCPConnectAuth
  new create(from: (AmbientAuth | NetAuth | TCPAuth)) =>
    None

primitive TCPServerAuth
  new create(from: (AmbientAuth | NetAuth | TCPAuth | TCPListenAuth)) =>
    None
