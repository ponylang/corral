primitive _Deflate
  """
  Core DEFLATE decompression engine (RFC 1951). Processes blocks sequentially
  until BFINAL is set.
  """
  fun apply(reader: _BitReader, output: Array[U8] ref): (None | InflateError) =>
    var bfinal: Bool = false

    while not bfinal do
      // Read BFINAL (1 bit)
      let bf = match reader.bits(1)
      | let v: U32 => v
      | let e: InflateError => return e
      end
      bfinal = bf == 1

      // Read BTYPE (2 bits)
      let btype = match reader.bits(2)
      | let v: U32 => v
      | let e: InflateError => return e
      end

      match btype
      | 0 => // Stored (no compression)
        match _stored_block(reader, output)
        | let e: InflateError => return e
        end
      | 1 => // Fixed Huffman
        let lit_len_table = match _FixedHuffmanTables.lit_len()
        | let t: _HuffmanTable => t
        | let e: InflateError => return e
        end
        let dist_table = match _FixedHuffmanTables.dist()
        | let t: _HuffmanTable => t
        | let e: InflateError => return e
        end
        match _huffman_block(reader, output, lit_len_table, dist_table)
        | let e: InflateError => return e
        end
      | 2 => // Dynamic Huffman
        match _dynamic_block(reader, output)
        | let e: InflateError => return e
        end
      else
        return InflateInvalidBlockType
      end
    end
    None

  fun _stored_block(
    reader: _BitReader,
    output: Array[U8] ref)
    : (None | InflateError)
  =>
    """
    Decompress a stored (uncompressed) block.
    """
    reader.align_to_byte()

    // Read LEN (2 bytes, little-endian)
    let len_lo = match reader.bits(8)
    | let v: U32 => v
    | let e: InflateError => return e
    end
    let len_hi = match reader.bits(8)
    | let v: U32 => v
    | let e: InflateError => return e
    end
    let len = (len_hi << 8) or len_lo

    // Read NLEN (2 bytes, little-endian)
    let nlen_lo = match reader.bits(8)
    | let v: U32 => v
    | let e: InflateError => return e
    end
    let nlen_hi = match reader.bits(8)
    | let v: U32 => v
    | let e: InflateError => return e
    end
    let nlen = (nlen_hi << 8) or nlen_lo

    // Verify LEN == ~NLEN (lower 16 bits)
    if len != (nlen xor 0xFFFF) then
      return InflateInvalidStoredLength
    end

    // Copy raw bytes
    match reader.read_bytes(len.usize())
    | let bytes: Array[U8] val =>
      output.append(bytes)
      None
    | let e: InflateError => e
    end

  fun _huffman_block(
    reader: _BitReader,
    output: Array[U8] ref,
    lit_len_table: _HuffmanTable,
    dist_table: _HuffmanTable)
    : (None | InflateError)
  =>
    """
    Decompress a Huffman-coded block (fixed or dynamic).
    """
    let len_base = _Tables.length_base()
    let len_extra = _Tables.length_extra()
    let d_base = _Tables.dist_base()
    let d_extra = _Tables.dist_extra()

    while true do
      let symbol = match lit_len_table.decode(reader)
      | let v: U16 => v
      | let e: InflateError => return e
      end

      if symbol < 256 then
        // Literal byte
        output.push(symbol.u8())
      elseif symbol == 256 then
        // End of block
        return None
      elseif symbol <= 285 then
        // Length code
        let len_idx = (symbol - 257).usize()
        let base_len = try len_base(len_idx)? else return InflateInvalidLitLen end
        let extra = try len_extra(len_idx)? else return InflateInvalidLitLen end
        let extra_val = if extra > 0 then
          match reader.bits(extra)
          | let v: U32 => v.u16()
          | let e: InflateError => return e
          end
        else
          U16(0)
        end
        let length = (base_len + extra_val).usize()

        // Decode distance
        let dist_symbol = match dist_table.decode(reader)
        | let v: U16 => v
        | let e: InflateError => return e
        end

        if dist_symbol.usize() >= d_base.size() then
          return InflateInvalidDistance
        end

        let base_dist = try d_base(dist_symbol.usize())? else return InflateInvalidDistance end
        let d_extra_bits = try d_extra(dist_symbol.usize())? else return InflateInvalidDistance end
        let d_extra_val = if d_extra_bits > 0 then
          match reader.bits(d_extra_bits)
          | let v: U32 => v.u16()
          | let e: InflateError => return e
          end
        else
          U16(0)
        end
        let distance = (base_dist + d_extra_val).usize()

        if distance > output.size() then
          return InflateInvalidDistance
        end

        // Copy bytes from back-reference. Must be byte-by-byte because
        // distance can be less than length (overlapping copy).
        let start = output.size() - distance
        var i: USize = 0
        while i < length do
          try
            output.push(output(start + i)?)
          else
            _Unreachable()
          end
          i = i + 1
        end
      else
        return InflateInvalidLitLen
      end
    end
    // Unreachable -- loop only exits via return
    _Unreachable()
    InflateInvalidLitLen

  fun _dynamic_block(
    reader: _BitReader,
    output: Array[U8] ref)
    : (None | InflateError)
  =>
    """
    Read dynamic Huffman code tables and decompress the block.
    """
    // Read header fields
    let hlit = match reader.bits(5)
    | let v: U32 => v.usize() + 257
    | let e: InflateError => return e
    end
    let hdist = match reader.bits(5)
    | let v: U32 => v.usize() + 1
    | let e: InflateError => return e
    end
    let hclen = match reader.bits(4)
    | let v: U32 => v.usize() + 4
    | let e: InflateError => return e
    end

    // Read code length code lengths in zigzag order
    let cl_order = _Tables.code_length_order()
    let cl_lengths = recover iso Array[U8].init(0, 19) end
    var i: USize = 0
    while i < hclen do
      let cl = match reader.bits(3)
      | let v: U32 => v.u8()
      | let e: InflateError => return e
      end
      let order_idx = try cl_order(i)? else return InflateInvalidCodeLengths end
      try cl_lengths(order_idx.usize())? = cl end
      i = i + 1
    end

    // Build code length Huffman table
    let cl_table = match _BuildHuffmanTable(consume cl_lengths)
    | let t: _HuffmanTable => t
    | let e: InflateError => return e
    end

    // Decode literal/length + distance code lengths
    let total_codes = hlit + hdist
    let code_lengths = recover iso Array[U8](total_codes) end
    while code_lengths.size() < total_codes do
      let sym = match cl_table.decode(reader)
      | let v: U16 => v.usize()
      | let e: InflateError => return e
      end

      if sym < 16 then
        code_lengths.push(sym.u8())
      elseif sym == 16 then
        if code_lengths.size() == 0 then return InflateInvalidCodeLengths end
        let repeat_count = match reader.bits(2)
        | let v: U32 => v.usize() + 3
        | let e: InflateError => return e
        end
        let prev = try code_lengths(code_lengths.size() - 1)? else return InflateInvalidCodeLengths end
        var j: USize = 0
        while j < repeat_count do
          code_lengths.push(prev)
          j = j + 1
        end
      elseif sym == 17 then
        let repeat_count = match reader.bits(3)
        | let v: U32 => v.usize() + 3
        | let e: InflateError => return e
        end
        var j: USize = 0
        while j < repeat_count do
          code_lengths.push(0)
          j = j + 1
        end
      elseif sym == 18 then
        let repeat_count = match reader.bits(7)
        | let v: U32 => v.usize() + 11
        | let e: InflateError => return e
        end
        var j: USize = 0
        while j < repeat_count do
          code_lengths.push(0)
          j = j + 1
        end
      else
        return InflateInvalidCodeLengths
      end
    end

    let all_lengths: Array[U8] val = consume code_lengths

    // Split into literal/length and distance code lengths
    let lit_len_lengths = recover val
      let arr = Array[U8](hlit)
      var k: USize = 0
      while k < hlit do
        try arr.push(all_lengths(k)?) else _Unreachable() end
        k = k + 1
      end
      arr
    end

    let dist_lengths = recover val
      let arr = Array[U8](hdist)
      var k: USize = 0
      while k < hdist do
        try arr.push(all_lengths(hlit + k)?) else _Unreachable() end
        k = k + 1
      end
      arr
    end

    // Build tables
    let lit_len_table = match _BuildHuffmanTable(lit_len_lengths)
    | let t: _HuffmanTable => t
    | let e: InflateError => return e
    end
    let dist_table = match _BuildHuffmanTable(dist_lengths)
    | let t: _HuffmanTable => t
    | let e: InflateError => return e
    end

    _huffman_block(reader, output, lit_len_table, dist_table)
