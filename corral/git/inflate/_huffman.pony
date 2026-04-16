class val _HuffmanTable
  """
  Flat lookup table for Huffman decoding. Read max_bits from input, index into
  the table, get symbol and actual code length, put back excess bits.
  Each entry: (symbol: U16, code_length: U8). A zero code_length means the
  entry is invalid.
  """
  let _table: Array[(U16, U8)] val
  let _max_bits: U8

  new val _create(table': Array[(U16, U8)] val, max_bits': U8) =>
    _table = table'
    _max_bits = max_bits'

  fun max_bits(): U8 => _max_bits

  fun decode(reader: _BitReader): (U16 | InflateError) =>
    """
    Decode one symbol from the bit stream.
    """
    let peek_bits = match reader.bits(_max_bits)
    | let v: U32 => v
    | let e: InflateError => return e
    end

    let index = peek_bits.usize()
    if index >= _table.size() then
      return InflateInvalidCodeLengths
    end

    (let symbol, let code_len) = try _table(index)? else return InflateInvalidCodeLengths end
    if code_len == 0 then
      return InflateInvalidCodeLengths
    end

    // Put back the excess bits we read
    let excess = _max_bits - code_len
    if excess > 0 then
      reader._put_back(excess)
    end
    symbol

primitive _BuildHuffmanTable
  """
  Builds a flat lookup table from an array of code lengths. Returns a
  _HuffmanTable or an error if the code lengths are invalid.
  """
  fun apply(code_lengths: Array[U8] val): (_HuffmanTable | InflateError) =>
    // Find the maximum code length
    var max_bits: U8 = 0
    for cl in code_lengths.values() do
      if cl > max_bits then max_bits = cl end
    end

    if max_bits == 0 then
      // All zero-length codes -- empty table (valid for empty distance alphabet)
      return _HuffmanTable._create(recover val Array[(U16, U8)] end, 0)
    end

    if max_bits > 15 then
      return InflateInvalidCodeLengths
    end

    // Count the number of codes at each length
    let bl_count = Array[U16].init(0, (max_bits.usize() + 1))
    for code_len in code_lengths.values() do
      if code_len > 0 then
        try bl_count(code_len.usize())? = bl_count(code_len.usize())? + 1 end
      end
    end

    // Compute the starting code for each length (RFC 1951 algorithm)
    let next_code = Array[U32].init(0, (max_bits.usize() + 1))
    var code: U32 = 0
    var bits: U8 = 1
    while bits <= max_bits do
      code = (code + (try bl_count((bits - 1).usize())? else 0 end).u32()) << 1
      try next_code(bits.usize())? = code end
      bits = bits + 1
    end

    // Build the flat lookup table
    let table_size = USize(1) << max_bits.usize()
    let table = recover iso Array[(U16, U8)].init((0, 0), table_size) end

    var symbol: USize = 0
    while symbol < code_lengths.size() do
      let sym_cl = try code_lengths(symbol)? else 0 end
      if sym_cl > 0 then
        let sym_code = try next_code(sym_cl.usize())? else 0 end
        try next_code(sym_cl.usize())? = sym_code + 1 end

        // Reverse the bits for LSB-first lookup
        let reversed = _reverse_bits(sym_code, sym_cl)

        // Fill all table entries that share this prefix
        let fill_step = USize(1) << sym_cl.usize()
        var idx = reversed.usize()
        while idx < table_size do
          try table(idx)? = (symbol.u16(), sym_cl) end
          idx = idx + fill_step
        end
      end
      symbol = symbol + 1
    end

    _HuffmanTable._create(consume table, max_bits)

  fun _reverse_bits(value: U32, num_bits: U8): U32 =>
    var result: U32 = 0
    var v = value
    var i: U8 = 0
    while i < num_bits do
      result = (result << 1) or (v and 1)
      v = v >> 1
      i = i + 1
    end
    result

primitive _FixedHuffmanTables
  """
  Pre-built fixed Huffman tables per RFC 1951 Section 3.2.6.
  """
  fun lit_len(): (_HuffmanTable | InflateError) =>
    """
    Fixed literal/length table:
    0-143: 8-bit, 144-255: 9-bit, 256-279: 7-bit, 280-287: 8-bit.
    """
    let lengths = recover val
      let arr = Array[U8](288)
      var i: U16 = 0
      while i <= 143 do arr.push(8); i = i + 1 end
      while i <= 255 do arr.push(9); i = i + 1 end
      while i <= 279 do arr.push(7); i = i + 1 end
      while i <= 287 do arr.push(8); i = i + 1 end
      arr
    end
    _BuildHuffmanTable(lengths)

  fun dist(): (_HuffmanTable | InflateError) =>
    """
    Fixed distance table: all 32 codes are 5-bit.
    """
    let lengths = recover val
      Array[U8].init(5, 32)
    end
    _BuildHuffmanTable(lengths)
