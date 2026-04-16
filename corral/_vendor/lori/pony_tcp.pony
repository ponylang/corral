use @pony_os_accept[I32](event: AsioEventID)
use @pony_os_connect_tcp[U32](the_actor: AsioEventNotify,
  host: Pointer[U8] tag,
  port: Pointer[U8] tag,
  from: Pointer[U8] tag,
  asio_flags: U32)
use @pony_os_connect_tcp4[U32](the_actor: AsioEventNotify,
  host: Pointer[U8] tag,
  port: Pointer[U8] tag,
  from: Pointer[U8] tag,
  asio_flags: U32)
use @pony_os_connect_tcp6[U32](the_actor: AsioEventNotify,
  host: Pointer[U8] tag,
  port: Pointer[U8] tag,
  from: Pointer[U8] tag,
  asio_flags: U32)
use @pony_os_keepalive[None](fd: U32, secs: U32)
use @pony_os_listen_tcp[AsioEventID](the_actor: AsioEventNotify,
  host: Pointer[U8] tag,
  port: Pointer[U8] tag)
use @pony_os_listen_tcp4[AsioEventID](the_actor: AsioEventNotify,
  host: Pointer[U8] tag,
  port: Pointer[U8] tag)
use @pony_os_listen_tcp6[AsioEventID](the_actor: AsioEventNotify,
  host: Pointer[U8] tag,
  port: Pointer[U8] tag)
use @pony_os_peername[Bool](fd: U32, ip: net.NetAddress ref)
use @pony_os_recv[USize](event: AsioEventID,
  buffer: Pointer[U8] tag,
  offset: USize) ?
use @pony_os_send[USize](event: AsioEventID,
  buffer: Pointer[U8] tag,
  from_offset: USize) ?
use @pony_os_socket_close[None](fd: U32)
use @pony_os_socket_shutdown[None](fd: U32)
use @pony_os_sockname[Bool](fd: U32, ip: net.NetAddress ref)
use @pony_os_writev[USize](ev: AsioEventID,
  wsa: Pointer[(USize, Pointer[U8] tag)] tag,
  wsacnt: I32) ? if windows
use @pony_os_writev[USize](ev: AsioEventID,
  iov: Pointer[(Pointer[U8] tag, USize)] tag,
  iovcnt: I32) ? if not windows
use @pony_os_writev_max[I32]()

use net = "net"

primitive PonyTCP
  fun listen(the_actor: AsioEventNotify,
    host: String,
    port: String,
    ip_version: IPVersion = DualStack)
    : AsioEventID
  =>
    match ip_version
    | IP4 =>
      @pony_os_listen_tcp4(the_actor, host.cstring(), port.cstring())
    | IP6 =>
      @pony_os_listen_tcp6(the_actor, host.cstring(), port.cstring())
    | DualStack =>
      @pony_os_listen_tcp(the_actor, host.cstring(), port.cstring())
    end

  fun accept(event: AsioEventID): I32 =>
    @pony_os_accept(event)

  fun close(fd: U32) =>
    @pony_os_socket_close(fd)

  fun connect(the_actor: AsioEventNotify,
    host: String,
    port: String,
    from: String,
    asio_flags: U32,
    ip_version: IPVersion = DualStack)
    : U32
  =>
    match ip_version
    | IP4 =>
      @pony_os_connect_tcp4(the_actor,
        host.cstring(),
        port.cstring(),
        from.cstring(),
        asio_flags)
    | IP6 =>
      @pony_os_connect_tcp6(the_actor,
        host.cstring(),
        port.cstring(),
        from.cstring(),
        asio_flags)
    | DualStack =>
      @pony_os_connect_tcp(the_actor,
        host.cstring(),
        port.cstring(),
        from.cstring(),
        asio_flags)
    end

  fun keepalive(fd: U32, secs: U32) =>
    @pony_os_keepalive(fd, secs)

  fun peername(fd: U32, ip: net.NetAddress ref): Bool =>
    @pony_os_peername(fd, ip)

  fun receive(event: AsioEventID,
    buffer: Pointer[U8] tag,
    offset: USize)
    : USize ?
  =>
    @pony_os_recv(event, buffer, offset)?

  fun send(event: AsioEventID,
    buffer: ByteSeq,
    from_offset: USize = 0)
    : USize ?
  =>
    @pony_os_send(event,
      buffer.cpointer(from_offset),
      buffer.size() - from_offset)?

  fun shutdown(fd: U32) =>
    @pony_os_socket_shutdown(fd)

  fun sockname(fd: U32, ip: net.NetAddress ref): Bool =>
    @pony_os_sockname(fd, ip)

  fun writev(event: AsioEventID, data: Array[ByteSeq] box,
    from: USize, count: USize,
    first_buffer_byte_offset: USize = 0): USize ?
  =>
    """
    Send `count` buffers from `data` starting at index `from` via writev.
    Builds the platform-specific IOV array (iovec on POSIX, WSABUF on
    Windows) internally.

    `first_buffer_byte_offset` skips bytes in `data(from)` for partial
    write resume.

    Returns bytes sent (POSIX) or buffer count submitted (Windows).
    """
    ifdef windows then
      let wsa = Array[(USize, Pointer[U8] tag)](count)
      var i = from
      while i < (from + count) do
        let entry = data(i)?
        if (i == from) and (first_buffer_byte_offset > 0) then
          wsa.push((entry.size() - first_buffer_byte_offset,
            entry.cpointer(first_buffer_byte_offset)))
        else
          wsa.push((entry.size(), entry.cpointer()))
        end
        i = i + 1
      end
      @pony_os_writev(event, wsa.cpointer(), count.i32())?
    else
      let iov = Array[(Pointer[U8] tag, USize)](count)
      var i = from
      while i < (from + count) do
        let entry = data(i)?
        if (i == from) and (first_buffer_byte_offset > 0) then
          iov.push((entry.cpointer(first_buffer_byte_offset),
            entry.size() - first_buffer_byte_offset))
        else
          iov.push((entry.cpointer(), entry.size()))
        end
        i = i + 1
      end
      @pony_os_writev(event, iov.cpointer(), count.i32())?
    end

  fun writev_max(): I32 =>
    """
    Maximum number of IOV entries per writev call. IOV_MAX on POSIX, 1 on
    Windows (Windows submits all entries at once, not in batches).
    """
    @pony_os_writev_max()
