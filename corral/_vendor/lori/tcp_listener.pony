use "collections"
use net = "net"

class TCPListener
  let _host: String
  let _port: String
  let _limit: (MaxSpawn | None)
  let _ip_version: IPVersion
  var _open_connections: U32 = 0
  var _paused: Bool = false
  var _event: AsioEventID = AsioEvent.none()
  var _fd: U32 = -1
  var _listening: Bool = false
  var _enclosing: (TCPListenerActor ref | None)

  new create(auth: TCPListenAuth, host: String, port: String,
    enclosing: TCPListenerActor ref, ip_version: IPVersion = DualStack,
    limit: (MaxSpawn | None) = DefaultMaxSpawn())
  =>
    _host = host
    _port = port
    _ip_version = ip_version
    _limit = limit
    _enclosing = enclosing
    enclosing._finish_initialization()

  new none() =>
    _host = ""
    _port = ""
    _limit = None
    _ip_version = DualStack
    _enclosing = None

  fun ref close() =>
    match \exhaustive\ _enclosing
    | let e: TCPListenerActor ref =>
      // TODO: when in debug mode we should blow up if listener is closed
      if _listening then
        _listening = false

        if not _event.is_null() then
          PonyAsio.unsubscribe(_event)
          PonyTCP.close(_fd)
          _fd = -1
          e._on_closed()
        end
      end
    | None =>
      _Unreachable()
    end

  fun local_address(): net.NetAddress =>
    """
    Return the local IP address. If this TCPListener is closed then the
    address returned is invalid.
    """
    recover
      let ip: net.NetAddress ref = net.NetAddress
      PonyTCP.sockname(_fd, ip)
      ip
    end

  fun ref _event_notify(event: AsioEventID, flags: U32, arg: U32) =>
    if event isnt _event then
      return
    end

    if AsioEvent.readable(flags) then
      _accept(arg)
    end

    if AsioEvent.disposable(flags) then
      PonyAsio.destroy(_event)
      _event = AsioEvent.none()
      _listening = false
    end

  fun ref _accept(arg: U32 = 0) =>
    match \exhaustive\ _enclosing
    | let e: TCPListenerActor ref =>
      if _listening then
        ifdef windows then
          // Unsubscribe if we get an invalid socket in an event
          if arg == -1 then
            PonyAsio.unsubscribe(_event)
            return
          end

          try
            if arg > 0 then
              let opened = e._on_accept(arg)?
              opened._register_spawner(e)
              _open_connections = _open_connections + 1
            end

            if not _at_connection_limit() then
              PonyTCP.accept(_event)
            else
              _paused = true
            end
          else
            PonyTCP.close(arg)
          end
        else
          while not _at_connection_limit() do
            var fd = PonyTCP.accept(_event)

            // 0: would block, -1: error
            if fd <= 0 then
              return
            end

            try
              let opened = e._on_accept(fd.u32())?
              opened._register_spawner(e)
              _open_connections = _open_connections + 1
            else
              PonyTCP.close(fd.u32())
            end
          end

          _paused = true
        end
      else
        // It's possible that after closing, we got an event for a connection
        // attempt. If that is the case or the listener is otherwise not open,
        // return and do not start a new connection
        ifdef windows then
          if arg == -1 then
            PonyAsio.unsubscribe(_event)
            return
          end

          if arg > 0 then
            PonyTCP.close(arg)
          end
        end
        return
      end
    | None =>
      _Unreachable()
    end

  fun _at_connection_limit(): Bool =>
    match \exhaustive\ _limit
    | let l: MaxSpawn => _open_connections >= l()
    | None => false
    end

  fun ref _connection_closed() =>
    _open_connections = _open_connections - 1
    if _paused and not _at_connection_limit() then
      _paused = false
      _accept()
    end

  fun ref _finish_initialization() =>
    match \exhaustive\ _enclosing
    | let e: TCPListenerActor ref =>
      _event = PonyTCP.listen(e, _host, _port where ip_version = _ip_version)
      if not _event.is_null() then
        _fd = PonyAsio.event_fd(_event)
        _listening = true
        e._on_listening()
      else
        e._on_listen_failure()
      end
    | None =>
      _Unreachable()
    end
