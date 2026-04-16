primitive _Adler32
  """
  Computes the Adler-32 checksum per RFC 1950. Two running sums (s1, s2)
  modulo 65521 (largest prime below 2^16). s1 = 1 + sum of bytes,
  s2 = sum of s1 values. Result = (s2 << 16) | s1.

  Accumulates up to 5552 bytes before taking modulo -- this is zlib's NMAX,
  the largest n where 255*n*(n+1)/2 + (n+1)*(BASE-1) fits in a U32.
  """
  fun _from_ref(data: Array[U8] ref): U32 =>
    _compute(data)

  fun apply(data: Array[U8] val): U32 =>
    _compute(data)

  fun _compute(data: Array[U8] box): U32 =>
    let base: U32 = 65521
    let nmax: USize = 5552
    var s1: U32 = 1
    var s2: U32 = 0
    var offset: USize = 0
    let size = data.size()

    while offset < size do
      let remaining = size - offset
      let block_size = if remaining < nmax then remaining else nmax end
      var i: USize = 0
      while i < block_size do
        try
          s1 = s1 + data(offset + i)?.u32()
        else
          _Unreachable()
        end
        s2 = s2 + s1
        i = i + 1
      end
      s1 = s1 % base
      s2 = s2 % base
      offset = offset + block_size
    end

    (s2 << 16) or s1
