primitive URL
  """
  Parse URL strings into their components.

  Supports `http` and `https` schemes. Validates the scheme, host, and port;
  rejects URLs with userinfo (`user:pass@host`). Fragments are silently
  discarded.

  ```pony
  match URL.parse("https://example.com:8443/api/v1?key=value")
  | let url: ParsedURL =>
    // url.scheme == SchemeHTTPS
    // url.host == "example.com"
    // url.port == "8443"
    // url.path == "/api/v1"
    // url.query == "key=value"
    // url.request_path() == "/api/v1?key=value"
    // url.is_ssl() == true
  | let err: URLParseError =>
    // handle error
  end
  ```
  """

  fun parse(url: String): (ParsedURL val | URLParseError) =>
    """
    Parse a URL string into its components, or return an error.
    """
    // Find :// separator
    let sep: ISize = try url.find("://")? else return MissingScheme end
    if sep == 0 then return MissingScheme end

    // Match scheme (case-insensitive)
    let scheme: Scheme =
      if (sep == 4)
        and (url.compare_sub("http", 4 where ignore_case = true) is Equal)
      then
        SchemeHTTP
      elseif (sep == 5)
        and (url.compare_sub("https", 5 where ignore_case = true) is Equal)
      then
        SchemeHTTPS
      else
        return UnsupportedScheme
      end

    // Authority starts after ://
    var pos: ISize = sep + 3
    let url_size: ISize = url.size().isize()

    // Find end of authority (first /, ?, #, or end of string)
    var authority_end: ISize = url_size
    var scan: ISize = pos
    while scan < url_size do
      try
        let ch = url(scan.usize())?
        if (ch == '/') or (ch == '?') or (ch == '#') then
          authority_end = scan
          break
        end
      else
        _Unreachable()
      end
      scan = scan + 1
    end

    // Check for userinfo (@ in authority)
    try
      let at_pos = url.find("@", pos)?
      if at_pos < authority_end then
        return UserInfoNotSupported
      end
    end

    // Parse host
    var host: String val = ""
    var host_end: ISize = pos

    if pos >= url_size then return MissingHost end

    try
      if url(pos.usize())? == '[' then
        // IPv6: extract between brackets
        host_end = try url.find("]", pos)? else return MissingHost end
        if host_end >= authority_end then return MissingHost end
        host = url.substring(pos + 1, host_end)
        host_end = host_end + 1
      else
        // Regular host: ends at : or authority_end
        host_end = pos
        while host_end < authority_end do
          try
            if url(host_end.usize())? == ':' then break end
          else
            _Unreachable()
          end
          host_end = host_end + 1
        end
        host = url.substring(pos, host_end)
      end
    else
      _Unreachable()
    end

    if host.size() == 0 then return MissingHost end

    // Parse port
    var port: String val =
      if scheme is SchemeHTTP then "80" else "443" end

    if host_end < authority_end then
      try
        if url(host_end.usize())? == ':' then
          let port_str: String val =
            url.substring(host_end + 1, authority_end)
          if port_str.size() > 0 then
            // RFC 3986: port = *DIGIT (decimal only, no hex/binary/underscores)
            if not _all_digits(port_str) then return InvalidPort end
            try
              (let port_num, let consumed) =
                port_str.read_int[U32](where base = 10)?
              if (consumed == 0) or (consumed != port_str.size())
                or (port_num == 0) or (port_num > 65535)
              then
                return InvalidPort
              end
              port = port_num.string()
            else
              return InvalidPort
            end
          end
        end
      else
        _Unreachable()
      end
    end

    // Parse path
    var path: String val = "/"
    var query: (String | None) = None
    pos = authority_end

    if pos < url_size then
      try
        let pos_ch = url(pos.usize())?
        if pos_ch == '/' then
          // Find end of path (? or # or end)
          var path_end: ISize = url_size
          scan = pos
          while scan < url_size do
            try
              let pc = url(scan.usize())?
              if (pc == '?') or (pc == '#') then
                path_end = scan
                break
              end
            else
              _Unreachable()
            end
            scan = scan + 1
          end
          path = url.substring(pos, path_end)
          pos = path_end
        elseif pos_ch == '#' then
          pos = url_size
        end
      else
        _Unreachable()
      end
    end

    // Parse query (from ? to # or end)
    if pos < url_size then
      try
        if url(pos.usize())? == '?' then
          var query_end: ISize = url_size
          scan = pos + 1
          while scan < url_size do
            try
              if url(scan.usize())? == '#' then
                query_end = scan
                break
              end
            else
              _Unreachable()
            end
            scan = scan + 1
          end
          query = url.substring(pos + 1, query_end)
        end
      else
        _Unreachable()
      end
    end

    ParsedURL._create(scheme, host, port, path, query)

  fun _all_digits(s: String box): Bool =>
    """
    True if every byte in `s` is an ASCII digit.
    """
    for byte in s.values() do
      if (byte < '0') or (byte > '9') then return false end
    end
    true
