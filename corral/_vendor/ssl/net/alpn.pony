use "net"

interface ALPNProtocolNotify
  fun ref alpn_negotiated(conn: TCPConnection, protocol: (String | None)): None

type ALPNProtocolName is String val
primitive ALPNFatal
primitive ALPNNoAck
primitive ALPNWarning

type ALPNMatchResult is (ALPNProtocolName | ALPNNoAck | ALPNWarning | ALPNFatal)
type _ALPNSelectCallback is @{(
   Pointer[_SSL] tag,
   Pointer[Pointer[U8] tag] tag,
   Pointer[U8] tag,
   Pointer[U8] box,
   U32,
   ALPNProtocolResolver box)
  : I32}

interface box ALPNProtocolResolver
  """
  Controls the protocol name to be chosen for incomming SSLConnections using the ALPN extension.
  """
  fun box resolve(advertised: Array[ALPNProtocolName] val): ALPNMatchResult

class val ALPNStandardProtocolResolver is ALPNProtocolResolver
  """
  Implements the standard protocol selection akin to the OpenSSL function `SSL_select_next_proto`.
  """
  let supported: Array[ALPNProtocolName] val
  let use_client_as_fallback: Bool

  new val create(
    supported': Array[ALPNProtocolName] val,
    use_client_as_fallback': Bool = true)
  =>
    supported = supported'
    use_client_as_fallback = use_client_as_fallback'

  fun box resolve(advertised: Array[ALPNProtocolName] val): ALPNMatchResult =>
    for sup_proto in supported.values() do
      for adv_proto in advertised.values() do
        if sup_proto == adv_proto then return sup_proto end
      end
    end
    if use_client_as_fallback then
      try return advertised(0)? end
    end

    ALPNWarning

primitive _ALPNMatchResultCode
  fun ok(): I32 => 0
  fun warning(): I32 => 1
  fun fatal(): I32 => 2
  fun no_ack(): I32 => 3

primitive _ALPNProtocolList
  fun from_array(protocols: Array[String] box): String ? =>
    """
    Try to pack the protocol names in `protocols` into a *protocol name list*
    """
    if protocols.size() == 0 then
      error
    end

    let list = recover trn String end

    for proto in protocols.values() do
      let len = proto.size()
      if (len == 0) or (len > 255) then error end

      list.push(U8.from[USize](len))
      list.append(proto)
    end

    list

  fun to_array(protocol_list: String box): Array[ALPNProtocolName] val ? =>
    """
    Try to unpack a *protocol name list* into an `Array[String]`
    """
    let arr = recover trn Array[ALPNProtocolName] end

    var index = USize(1)
    var remain = try protocol_list(0)? else error end
    var buf = recover trn String end

    if remain == 0 then error end

    while index < protocol_list.size() do
      let ch = try protocol_list(index)? else error end
      if remain > 0 then
        buf.push(ch)
        remain = remain - 1
      end

      if remain == 0 then
        let final_protocol: String = buf = recover String end
        arr.push(final_protocol)

        let hasNextChar = index < (protocol_list.size() - 1)
        if hasNextChar then
          remain = try protocol_list(index + 1)? else error end
          if remain == 0 then error end
          index = index + 1
        end
      end
      index = index + 1
    end

    if remain > 0 then error end
    arr
