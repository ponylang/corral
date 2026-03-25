class ref _BitReader
  """
  Reads bits from a byte array LSB-first (DEFLATE bit order). Tracks byte
  position and bit offset within the current byte.
  """
  let _data: Array[U8] val
  var _byte_pos: USize
  var _bit_pos: U8  // 0-7 within current byte

  new create(data: Array[U8] val, start_offset: USize = 0) =>
    _data = data
    _byte_pos = start_offset
    _bit_pos = 0

  fun ref bits(n: U8): (U32 | InflateError) =>
    """
    Read n bits (0-25) and return as a U32, LSB-aligned.
    """
    if n == 0 then return U32(0) end
    var result: U32 = 0
    var bits_read: U8 = 0
    while bits_read < n do
      if _byte_pos >= _data.size() then
        return InflateIncompleteInput
      end
      let current_byte = try _data(_byte_pos)? else return InflateIncompleteInput end
      let bits_available: U8 = 8 - _bit_pos
      let bits_needed: U8 = n - bits_read
      let take: U8 = if bits_available < bits_needed then bits_available else bits_needed end

      // Extract 'take' bits from current byte starting at _bit_pos.
      // Use U16 for mask computation to avoid U8(1) << 8 clamping to 128.
      let mask: U8 = (U16(1) << take.u16()).u8() - 1
      let extracted: U8 = (current_byte >> _bit_pos) and mask
      result = result or (extracted.u32() << bits_read.u32())

      bits_read = bits_read + take
      _bit_pos = _bit_pos + take
      if _bit_pos >= 8 then
        _bit_pos = 0
        _byte_pos = _byte_pos + 1
      end
    end
    result

  fun ref _put_back(n: U8) =>
    """
    Put back n bits that were read but not consumed (used by Huffman decoder).
    """
    let total_bits = (_byte_pos.u32() * 8) + _bit_pos.u32()
    let new_total = total_bits - n.u32()
    _byte_pos = (new_total / 8).usize()
    _bit_pos = (new_total % 8).u8()

  fun ref align_to_byte() =>
    """
    Advance to the next byte boundary (for stored blocks).
    """
    if _bit_pos > 0 then
      _bit_pos = 0
      _byte_pos = _byte_pos + 1
    end

  fun bytes_remaining(): USize =>
    if _byte_pos >= _data.size() then
      0
    else
      _data.size() - _byte_pos
    end

  fun ref read_bytes(n: USize): (Array[U8] val | InflateError) =>
    """
    Read n bytes, only valid when byte-aligned.
    """
    if (_byte_pos + n) > _data.size() then
      return InflateIncompleteInput
    end
    let result = recover val
      let arr = Array[U8](n)
      var i: USize = 0
      while i < n do
        try
          arr.push(_data(_byte_pos + i)?)
        else
          _Unreachable()
        end
        i = i + 1
      end
      arr
    end
    _byte_pos = _byte_pos + n
    result
