class val SendToken is Equatable[SendToken]
  """
  Identifies a send operation. Returned by `send()` on success and delivered
  to `_on_sent()` when the data has been fully handed to the OS.

  Tokens use structural equality based on their ID, which is scoped per
  connection. Applications managing multiple connections should pair tokens
  with connection identity to avoid ambiguity.
  """
  let id: USize

  new val _create(id': USize) =>
    id = id'

  fun eq(that: box->SendToken): Bool =>
    id == that.id

  fun ne(that: box->SendToken): Bool =>
    not eq(that)

primitive SendErrorNotConnected
  """
  The connection is not yet established or has already been closed.
  """

primitive SendErrorNotWriteable
  """
  The socket is not writeable. This happens during backpressure (a previous
  send is still pending) or when the socket's send buffer is full.
  Wait for `_on_unthrottled` before retrying.
  """

type SendError is
  (SendErrorNotConnected | SendErrorNotWriteable)
