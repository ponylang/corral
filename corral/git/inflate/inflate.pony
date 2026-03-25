"""
RFC 1951 DEFLATE decompression with RFC 1950 zlib framing. Provides one-shot
decompression suitable for git object reading -- objects are read whole from
disk or pack entries, so streaming decompression is not needed.

Use `Inflate` for zlib-framed data (loose git objects). Use `InflateRaw` for
raw DEFLATE streams without zlib framing (packfile delta data).
"""

primitive Inflate
  """
  Decompresses zlib-framed data (RFC 1950) containing a DEFLATE stream
  (RFC 1951). Returns the decompressed bytes or an error describing what
  went wrong.

  This is a one-shot API: provide the complete compressed input and receive
  the complete decompressed output. Streaming decompression is not needed
  for git object reading -- objects are read whole from disk or pack entries.
  """
  fun apply(data: Array[U8] val): (Array[U8] val | InflateError) =>
    // Validate zlib header (RFC 1950)
    if data.size() < 6 then return InflateIncompleteInput end

    let cmf = try data(0)? else return InflateIncompleteInput end
    let flg = try data(1)? else return InflateIncompleteInput end

    // CM must be 8 (deflate), CINFO must be <= 7
    if (cmf and 0x0F) != 8 then return InflateInvalidHeader end
    if (cmf >> 4) > 7 then return InflateInvalidHeader end

    // FCHECK: (CMF * 256 + FLG) must be a multiple of 31
    if (((cmf.u16() * 256) + flg.u16()) % 31) != 0 then
      return InflateInvalidHeader
    end

    // FDICT must not be set (git never uses preset dictionaries)
    if (flg and 0x20) != 0 then return InflateInvalidHeader end

    // All decompression + checksum inside recover val.
    // data is val (sendable), inflate_err holds only val primitives (sendable).
    var inflate_err: (InflateError | None) = None
    let decompressed: Array[U8] val = recover val
      let reader = _BitReader(data, 2)
      let output = Array[U8]

      match _Deflate(reader, output)
      | let e: InflateError =>
        inflate_err = e
      else
        // Read 4-byte Adler-32 checksum (big-endian) after DEFLATE stream
        reader.align_to_byte()
        var ok = true
        let b0 = match reader.bits(8) | let v: U32 => v | let e: InflateError => inflate_err = e; ok = false; U32(0) end
        let b1 = if ok then match reader.bits(8) | let v: U32 => v | let e: InflateError => inflate_err = e; ok = false; U32(0) end else U32(0) end
        let b2 = if ok then match reader.bits(8) | let v: U32 => v | let e: InflateError => inflate_err = e; ok = false; U32(0) end else U32(0) end
        let b3 = if ok then match reader.bits(8) | let v: U32 => v | let e: InflateError => inflate_err = e; ok = false; U32(0) end else U32(0) end

        if ok then
          let stored = (b0 << 24) or (b1 << 16) or (b2 << 8) or b3
          let computed = _Adler32._from_ref(output)
          if stored != computed then
            inflate_err = InflateChecksumMismatch
          end
        end
      end
      output
    end

    match inflate_err
    | let e: InflateError => e
    else
      decompressed
    end

primitive InflateRaw
  """
  Decompresses a raw DEFLATE stream (RFC 1951) without zlib framing.
  Needed for git packfile delta data, which is stored without zlib headers.
  """
  fun apply(data: Array[U8] val): (Array[U8] val | InflateError) =>
    var inflate_err: (InflateError | None) = None
    let decompressed: Array[U8] val = recover val
      let reader = _BitReader(data)
      let output = Array[U8]
      match _Deflate(reader, output)
      | let e: InflateError => inflate_err = e
      end
      output
    end

    match inflate_err
    | let e: InflateError => e
    else
      decompressed
    end
