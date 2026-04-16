use "pony_test"
use "pony_check"

// ---- Helper ----

primitive _AssertInflateOk
  """
  Decompress and verify the result matches expected output.
  """
  fun apply(
    h: TestHelper,
    compressed: Array[U8] val,
    expected: Array[U8] val,
    raw: Bool = false)
  =>
    let result = if raw then
      InflateRaw(compressed)
    else
      Inflate(compressed)
    end
    match result
    | let data: Array[U8] val =>
      h.assert_eq[USize](expected.size(), data.size(),
        "output size mismatch: expected " + expected.size().string()
        + " got " + data.size().string())
      var i: USize = 0
      while i < expected.size() do
        try
          h.assert_eq[U8](expected(i)?, data(i)?,
            "byte mismatch at offset " + i.string())
        end
        i = i + 1
      end
    | let err: InflateError =>
      h.fail("expected success but got: " + err.string())
    end

primitive _AssertInflateError
  """
  Decompress and verify the result is the expected error type.
  """
  fun apply(
    h: TestHelper,
    compressed: Array[U8] val,
    expected: InflateError,
    raw: Bool = false)
  =>
    let result = if raw then
      InflateRaw(compressed)
    else
      Inflate(compressed)
    end
    match result
    | let data: Array[U8] val =>
      h.fail("expected error '" + expected.string()
        + "' but got " + data.size().string() + " bytes")
    | let err: InflateError =>
      h.assert_eq[String val](expected.string(), err.string())
    end

// ---- Happy path tests ----

class \nodoc\ iso _TestInflateEmpty is UnitTest
  """zlib.compress(b"") -- minimal valid zlib stream."""
  fun name(): String => "inflate/empty"

  fun apply(h: TestHelper) =>
    // Python: zlib.compress(b"")
    let compressed: Array[U8] val =
      [as U8: 0x78; 0x9C; 0x03; 0x00; 0x00; 0x00; 0x00; 0x01]
    _AssertInflateOk(h, compressed, recover val Array[U8] end)

class \nodoc\ iso _TestInflateHello is UnitTest
  """zlib.compress(b"hello") -- single fixed Huffman block."""
  fun name(): String => "inflate/hello"

  fun apply(h: TestHelper) =>
    // Python: zlib.compress(b"hello")
    let compressed: Array[U8] val = [as U8:
      0x78; 0x9C; 0xCB; 0x48; 0xCD; 0xC9; 0xC9; 0x07
      0x00; 0x06; 0x2C; 0x02; 0x15]
    let expected: Array[U8] val = [as U8:
      0x68; 0x65; 0x6C; 0x6C; 0x6F]  // "hello"
    _AssertInflateOk(h, compressed, expected)

class \nodoc\ iso _TestInflateRepeated is UnitTest
  """zlib.compress(b"a" * 1000) -- LZ77 back-references."""
  fun name(): String => "inflate/repeated"

  fun apply(h: TestHelper) =>
    // Python: zlib.compress(b"a" * 1000)
    let compressed: Array[U8] val = [as U8:
      0x78; 0x9C; 0x4B; 0x4C; 0x1C; 0x05; 0xA3; 0x60
      0x14; 0x0C; 0x77; 0x00; 0x00; 0xF9; 0xD8; 0x7A; 0xF8]
    let expected = recover val Array[U8].init('a', 1000) end
    _AssertInflateOk(h, compressed, expected)

class \nodoc\ iso _TestInflateAllBytes is UnitTest
  """zlib.compress(bytes(range(256))) -- all 256 literal values."""
  fun name(): String => "inflate/all-bytes"

  fun apply(h: TestHelper) =>
    // Python: zlib.compress(bytes(range(256)))
    let compressed: Array[U8] val = [as U8:
      0x78; 0x9C; 0x01; 0x00; 0x01; 0xFF; 0xFE; 0x00; 0x01; 0x02
      0x03; 0x04; 0x05; 0x06; 0x07; 0x08; 0x09; 0x0A; 0x0B; 0x0C
      0x0D; 0x0E; 0x0F; 0x10; 0x11; 0x12; 0x13; 0x14; 0x15; 0x16
      0x17; 0x18; 0x19; 0x1A; 0x1B; 0x1C; 0x1D; 0x1E; 0x1F; 0x20
      0x21; 0x22; 0x23; 0x24; 0x25; 0x26; 0x27; 0x28; 0x29; 0x2A
      0x2B; 0x2C; 0x2D; 0x2E; 0x2F; 0x30; 0x31; 0x32; 0x33; 0x34
      0x35; 0x36; 0x37; 0x38; 0x39; 0x3A; 0x3B; 0x3C; 0x3D; 0x3E
      0x3F; 0x40; 0x41; 0x42; 0x43; 0x44; 0x45; 0x46; 0x47; 0x48
      0x49; 0x4A; 0x4B; 0x4C; 0x4D; 0x4E; 0x4F; 0x50; 0x51; 0x52
      0x53; 0x54; 0x55; 0x56; 0x57; 0x58; 0x59; 0x5A; 0x5B; 0x5C
      0x5D; 0x5E; 0x5F; 0x60; 0x61; 0x62; 0x63; 0x64; 0x65; 0x66
      0x67; 0x68; 0x69; 0x6A; 0x6B; 0x6C; 0x6D; 0x6E; 0x6F; 0x70
      0x71; 0x72; 0x73; 0x74; 0x75; 0x76; 0x77; 0x78; 0x79; 0x7A
      0x7B; 0x7C; 0x7D; 0x7E; 0x7F; 0x80; 0x81; 0x82; 0x83; 0x84
      0x85; 0x86; 0x87; 0x88; 0x89; 0x8A; 0x8B; 0x8C; 0x8D; 0x8E
      0x8F; 0x90; 0x91; 0x92; 0x93; 0x94; 0x95; 0x96; 0x97; 0x98
      0x99; 0x9A; 0x9B; 0x9C; 0x9D; 0x9E; 0x9F; 0xA0; 0xA1; 0xA2
      0xA3; 0xA4; 0xA5; 0xA6; 0xA7; 0xA8; 0xA9; 0xAA; 0xAB; 0xAC
      0xAD; 0xAE; 0xAF; 0xB0; 0xB1; 0xB2; 0xB3; 0xB4; 0xB5; 0xB6
      0xB7; 0xB8; 0xB9; 0xBA; 0xBB; 0xBC; 0xBD; 0xBE; 0xBF; 0xC0
      0xC1; 0xC2; 0xC3; 0xC4; 0xC5; 0xC6; 0xC7; 0xC8; 0xC9; 0xCA
      0xCB; 0xCC; 0xCD; 0xCE; 0xCF; 0xD0; 0xD1; 0xD2; 0xD3; 0xD4
      0xD5; 0xD6; 0xD7; 0xD8; 0xD9; 0xDA; 0xDB; 0xDC; 0xDD; 0xDE
      0xDF; 0xE0; 0xE1; 0xE2; 0xE3; 0xE4; 0xE5; 0xE6; 0xE7; 0xE8
      0xE9; 0xEA; 0xEB; 0xEC; 0xED; 0xEE; 0xEF; 0xF0; 0xF1; 0xF2
      0xF3; 0xF4; 0xF5; 0xF6; 0xF7; 0xF8; 0xF9; 0xFA; 0xFB; 0xFC
      0xFD; 0xFE; 0xFF; 0xAD; 0xF6; 0x7F; 0x81]
    let expected = recover val
      let arr = Array[U8](256)
      var i: U16 = 0
      while i < 256 do
        arr.push(i.u8())
        i = i + 1
      end
      arr
    end
    _AssertInflateOk(h, compressed, expected)

class \nodoc\ iso _TestInflateStored is UnitTest
  """zlib.compress(b"short", level=0) -- stored (BTYPE=00) block."""
  fun name(): String => "inflate/stored"

  fun apply(h: TestHelper) =>
    // Python: zlib.compress(b"short", 0)
    let compressed: Array[U8] val = [as U8:
      0x78; 0x01; 0x01; 0x05; 0x00; 0xFA; 0xFF; 0x73
      0x68; 0x6F; 0x72; 0x74; 0x06; 0x89; 0x02; 0x31]
    let expected: Array[U8] val = [as U8:
      0x73; 0x68; 0x6F; 0x72; 0x74]  // "short"
    _AssertInflateOk(h, compressed, expected)

class \nodoc\ iso _TestInflateDynamic is UnitTest
  """
  Compressed random-ish data that forces BTYPE=10 (dynamic Huffman).
  Data is SHA-256 of 'test-vector-seed' repeated 128 times (4096 bytes).
  """
  fun name(): String => "inflate/dynamic"

  fun apply(h: TestHelper) =>
    // Python: hashlib.sha256(b'test-vector-seed').digest() * 128, then zlib.compress()
    let compressed: Array[U8] val = [as U8:
      0x78; 0x9C; 0xE3; 0xBA; 0x3B; 0xF1; 0xEB; 0xC2
      0x97; 0x87; 0xB8; 0x9D; 0x98; 0xD2; 0x72; 0x96
      0xCD; 0x17; 0x95; 0x3C; 0xE9; 0x1C; 0x35; 0xE5
      0xF2; 0xE6; 0x87; 0x1A; 0x4A; 0x9E; 0x5C; 0xD1
      0x42; 0xDE; 0xB3; 0x97; 0x71; 0x8D; 0xCA; 0x8F
      0xCA; 0x8F; 0xCA; 0x8F; 0xCA; 0x8F; 0xCA; 0x8F
      0xCA; 0x8F; 0xCA; 0x8F; 0xCA; 0x8F; 0xCA; 0x8F
      0xCA; 0x8F; 0xCA; 0x8F; 0xCA; 0x8F; 0xCA; 0x8F
      0xCA; 0x8F; 0xCA; 0x0F; 0x79; 0x79; 0x00; 0x7D
      0x51; 0x22; 0x6A]
    let result = Inflate(compressed)
    match result
    | let data: Array[U8] val =>
      h.assert_eq[USize](4096, data.size())
      // Verify it's 128 repetitions of 32 bytes
      try
        let first_32 = recover val
          let arr = Array[U8](32)
          var i: USize = 0
          while i < 32 do
            arr.push(data(i)?)
            i = i + 1
          end
          arr
        end
        var rep: USize = 1
        while rep < 128 do
          var j: USize = 0
          while j < 32 do
            h.assert_eq[U8](first_32(j)?, data((rep * 32) + j)?,
              "mismatch at rep " + rep.string() + " byte " + j.string())
            j = j + 1
          end
          rep = rep + 1
        end
      end
    | let err: InflateError =>
      h.fail("expected success but got: " + err.string())
    end

class \nodoc\ iso _TestInflateMaxBackRef is UnitTest
  """32KB+ input with repeated pattern testing full sliding window."""
  fun name(): String => "inflate/max-back-ref"

  fun apply(h: TestHelper) =>
    // Python: zlib.compress(b'A' * 100 + b'B' * 32668 + b'A' * 100)
    let compressed: Array[U8] val = [as U8:
      0x78; 0x9C; 0xED; 0xC1; 0x41; 0x11; 0x00; 0x00
      0x08; 0x03; 0xA0; 0x6C; 0xB3; 0x7F; 0x28; 0x53
      0xCC; 0xF3; 0x01; 0x24; 0x7D; 0x03; 0x00; 0x00
      0x00; 0x00; 0x00; 0x00; 0x00; 0x00; 0x00; 0x00
      0x00; 0x00; 0x00; 0x00; 0x00; 0x00; 0x00; 0x00
      0x00; 0x00; 0x00; 0x00; 0x00; 0x00; 0x00; 0x00
      0x00; 0x00; 0x00; 0x00; 0x00; 0xCF; 0xE5; 0xC0
      0x02; 0x75; 0xE0; 0x1A; 0xF0]
    let result = Inflate(compressed)
    match result
    | let data: Array[U8] val =>
      h.assert_eq[USize](32868, data.size())
      // First 100 bytes should be 'A'
      try h.assert_eq[U8]('A', data(0)?) end
      try h.assert_eq[U8]('A', data(99)?) end
      // Middle should be 'B'
      try h.assert_eq[U8]('B', data(100)?) end
      try h.assert_eq[U8]('B', data(32767)?) end
      // Last 100 should be 'A'
      try h.assert_eq[U8]('A', data(32768)?) end
      try h.assert_eq[U8]('A', data(32867)?) end
    | let err: InflateError =>
      h.fail("expected success but got: " + err.string())
    end

class \nodoc\ iso _TestInflateMultiBlock is UnitTest
  """Multiple DEFLATE blocks (BFINAL=0 followed by BFINAL=1)."""
  fun name(): String => "inflate/multi-block"

  fun apply(h: TestHelper) =>
    // Python: zlib.compress((b'ABCDEFGHIJ' * 1000) + (b'0123456789' * 1000))
    let compressed: Array[U8] val = [as U8:
      0x78; 0x9C; 0xED; 0xC6; 0xC9; 0x0D; 0x80; 0x20
      0x00; 0x00; 0xB0; 0x95; 0x10; 0x54; 0xE0; 0x89
      0xE2; 0xB9; 0xFF; 0x40; 0xCC; 0x41; 0xD2; 0xBE
      0xDA; 0x8E; 0xB3; 0x5F; 0xF7; 0xF3; 0x7E; 0x7F
      0x33; 0x33; 0x33; 0x33; 0x33; 0x33; 0x33; 0x33
      0x33; 0x33; 0x33; 0x33; 0x33; 0x33; 0x33; 0x33
      0x33; 0x33; 0x33; 0x9B; 0x76; 0x61; 0x89; 0x69
      0xDD; 0xF6; 0x5C; 0xAA; 0x99; 0x99; 0x99; 0x99
      0x99; 0x99; 0x99; 0x99; 0x99; 0x99; 0x99; 0x99
      0x99; 0x99; 0x99; 0x99; 0x99; 0x99; 0xD9; 0xBC
      0x1B; 0xE1; 0x8D; 0x9E; 0xAF]
    let result = Inflate(compressed)
    match result
    | let data: Array[U8] val =>
      h.assert_eq[USize](20000, data.size())
      // Check first part is ABCDEFGHIJ repeated
      try h.assert_eq[U8]('A', data(0)?) end
      try h.assert_eq[U8]('J', data(9)?) end
      try h.assert_eq[U8]('A', data(10)?) end
      // Check second part is 0123456789 repeated
      try h.assert_eq[U8]('0', data(10000)?) end
      try h.assert_eq[U8]('9', data(10009)?) end
    | let err: InflateError =>
      h.fail("expected success but got: " + err.string())
    end

class \nodoc\ iso _TestInflateGitObject is UnitTest
  """
  zlib.compress(b"blob 5\0hello") -- bridges inflate testing to git use case.
  """
  fun name(): String => "inflate/git-object"

  fun apply(h: TestHelper) =>
    // Python: zlib.compress(b"blob 5\0hello")
    let compressed: Array[U8] val = [as U8:
      0x78; 0x9C; 0x4B; 0xCA; 0xC9; 0x4F; 0x52; 0x30
      0x65; 0xC8; 0x48; 0xCD; 0xC9; 0xC9; 0x07; 0x00
      0x19; 0xAA; 0x04; 0x09]
    let expected: Array[U8] val = [as U8:
      0x62; 0x6C; 0x6F; 0x62; 0x20; 0x35; 0x00; 0x68
      0x65; 0x6C; 0x6C; 0x6F]  // "blob 5\0hello"
    _AssertInflateOk(h, compressed, expected)

class \nodoc\ iso _TestInflateRawMinimal is UnitTest
  """
  Minimal raw DEFLATE stream: 0x03 0x00 (empty fixed block with BFINAL=1).
  From Mark Adler's puff reference.
  """
  fun name(): String => "inflate/raw/minimal"

  fun apply(h: TestHelper) =>
    let compressed: Array[U8] val = [as U8: 0x03; 0x00]
    _AssertInflateOk(h, compressed, recover val Array[U8] end where raw = true)

class \nodoc\ iso _TestInflateRawFixed is UnitTest
  """Raw DEFLATE fixed Huffman block for 'hello' (no zlib framing)."""
  fun name(): String => "inflate/raw/fixed"

  fun apply(h: TestHelper) =>
    // Stripped from zlib.compress(b"hello"): remove 2-byte header and 4-byte trailer
    let compressed: Array[U8] val = [as U8:
      0xCB; 0x48; 0xCD; 0xC9; 0xC9; 0x07; 0x00]
    let expected: Array[U8] val = [as U8:
      0x68; 0x65; 0x6C; 0x6C; 0x6F]  // "hello"
    _AssertInflateOk(h, compressed, expected where raw = true)

class \nodoc\ iso _TestInflateRawStored is UnitTest
  """Raw DEFLATE stored block containing 'hello'."""
  fun name(): String => "inflate/raw/stored"

  fun apply(h: TestHelper) =>
    // Hand-crafted: BFINAL=1, BTYPE=00, LEN=5, NLEN=~5, "hello"
    let compressed: Array[U8] val = [as U8:
      0x01; 0x05; 0x00; 0xFA; 0xFF; 0x68; 0x65; 0x6C; 0x6C; 0x6F]
    let expected: Array[U8] val = [as U8:
      0x68; 0x65; 0x6C; 0x6C; 0x6F]  // "hello"
    _AssertInflateOk(h, compressed, expected where raw = true)

// ---- Error path tests ----

class \nodoc\ iso _TestInflateChecksumCorruption is UnitTest
  """Flip a byte in compressed payload to trigger checksum mismatch."""
  fun name(): String => "inflate/error/checksum"

  fun apply(h: TestHelper) =>
    // Take valid "hello" compressed data, flip a byte in the payload
    let corrupted: Array[U8] val = [as U8:
      0x78; 0x9C; 0xCB; 0x48; 0xCD; 0xC9; 0xC9; 0x07
      0x00; 0x06; 0x2C; 0x02; 0xFF]  // last byte changed from 0x15 to 0xFF
    _AssertInflateError(h, corrupted, InflateChecksumMismatch)

class \nodoc\ iso _TestInflateTruncated is UnitTest
  """Truncated input at various points."""
  fun name(): String => "inflate/error/truncated"

  fun apply(h: TestHelper) =>
    // Just the zlib header, no DEFLATE data
    _AssertInflateError(h,
      [as U8: 0x78; 0x9C], InflateIncompleteInput)

    // zlib header + partial fixed block
    _AssertInflateError(h,
      [as U8: 0x78; 0x9C; 0xCB], InflateIncompleteInput)

class \nodoc\ iso _TestInflateInvalidBlockType is UnitTest
  """Craft a byte stream with BTYPE=11 (invalid)."""
  fun name(): String => "inflate/error/invalid-block-type"

  fun apply(h: TestHelper) =>
    // Zlib header + BFINAL=1, BTYPE=11 (binary: 111 = 0x07 in first 3 bits)
    // Extra bytes so the reader doesn't run out of input before detecting block type
    let data: Array[U8] val = [as U8: 0x78; 0x9C; 0x07; 0x00; 0x00; 0x00; 0x00; 0x00]
    _AssertInflateError(h, data, InflateInvalidBlockType)

class \nodoc\ iso _TestInflateInvalidHeader is UnitTest
  """Various invalid zlib headers."""
  fun name(): String => "inflate/error/invalid-header"

  fun apply(h: TestHelper) =>
    // Wrong CM value (not 8)
    _AssertInflateError(h,
      [as U8: 0x79; 0x9C; 0x03; 0x00; 0x00; 0x00; 0x00; 0x01],
      InflateInvalidHeader)

    // FCHECK failure -- (0x78 * 256 + 0x00) % 31 != 0
    _AssertInflateError(h,
      [as U8: 0x78; 0x00; 0x03; 0x00; 0x00; 0x00; 0x00; 0x01],
      InflateInvalidHeader)

    // FDICT set (bit 5 of FLG)
    // 0x78 0xBC: CM=8, CINFO=7, FDICT=1, FCHECK adjusted
    // (0x78*256 + 0xBB) = 30907, 30907 % 31 = 0 => FCHECK works, FDICT set
    _AssertInflateError(h,
      [as U8: 0x78; 0xBB; 0x03; 0x00; 0x00; 0x00; 0x00; 0x01],
      InflateInvalidHeader)

class \nodoc\ iso _TestInflateStoredLengthMismatch is UnitTest
  """Stored block where LEN != ~NLEN."""
  fun name(): String => "inflate/error/stored-length-mismatch"

  fun apply(h: TestHelper) =>
    // Raw DEFLATE: BFINAL=1, BTYPE=00, LEN=5 (0x0005), NLEN=0x0000 (wrong)
    _AssertInflateError(h,
      [as U8: 0x01; 0x05; 0x00; 0x00; 0x00; 0x68; 0x65; 0x6C; 0x6C; 0x6F],
      InflateInvalidStoredLength where raw = true)

// ---- BitReader tests ----

class \nodoc\ iso _PropertyBitReaderSplit is UnitTest
  """
  Reading n bits then m bits produces the same result as reading n+m bits
  and splitting.

  TODO: Convert back to Property1[Array[U8] val] once ponyc#4838 is fixed.
  Was a property test using Generators.map2 but segfaults due to vtable bug.
  """
  fun name(): String => "inflate/bit-reader-split"

  fun apply(h: TestHelper) =>
    _check_split(h, [as U8: 0xAB; 0xCD; 0xEF; 0x01])
    _check_split(h, [as U8: 0x00; 0x00; 0x00; 0x00])
    _check_split(h, [as U8: 0xFF; 0xFF; 0xFF; 0xFF])
    _check_split(h, [as U8: 0x55; 0xAA; 0x55; 0xAA])

  fun _check_split(h: TestHelper, data: Array[U8] val) =>
    // Read 5 bits then 7 bits from one reader
    let r1 = _BitReader(data)
    let a = match r1.bits(5)
    | let v: U32 => v
    | let e: InflateError => h.fail(e.string()); return
    end
    let b = match r1.bits(7)
    | let v: U32 => v
    | let e: InflateError => h.fail(e.string()); return
    end

    // Read 12 bits from another reader and split
    let r2 = _BitReader(data)
    let combined = match r2.bits(12)
    | let v: U32 => v
    | let e: InflateError => h.fail(e.string()); return
    end

    let a2 = combined and 0x1F  // lower 5 bits
    let b2 = (combined >> 5) and 0x7F  // next 7 bits

    h.assert_eq[U32](a, a2, "lower bits mismatch")
    h.assert_eq[U32](b, b2, "upper bits mismatch")
