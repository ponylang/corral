use "pony_test"
use "pony_check"

class \nodoc\ iso _TestAdler32Empty is UnitTest
  """adler32(empty) == 1"""
  fun name(): String => "inflate/adler32/empty"

  fun apply(h: TestHelper) =>
    h.assert_eq[U32](1, _Adler32(recover val Array[U8] end))

class \nodoc\ iso _TestAdler32ZeroByte is UnitTest
  """adler32([0x00]) == 0x00010001"""
  fun name(): String => "inflate/adler32/zero-byte"

  fun apply(h: TestHelper) =>
    h.assert_eq[U32](0x00010001, _Adler32([as U8: 0x00]))

class \nodoc\ iso _TestAdler32Wikipedia is UnitTest
  """adler32("Wikipedia") verified against Python's zlib.adler32()."""
  fun name(): String => "inflate/adler32/wikipedia"

  fun apply(h: TestHelper) =>
    // Python: zlib.adler32(b"Wikipedia") => 300286872 => 0x11E60398
    let data: Array[U8] val = [as U8:
      0x57; 0x69; 0x6B; 0x69; 0x70; 0x65; 0x64; 0x69; 0x61]
    h.assert_eq[U32](0x11E60398, _Adler32(data))

class \nodoc\ _PropertyAdler32Reference is Property1[Array[U8] val]
  """
  Verify _Adler32 against a reference implementation computed directly
  from the definition for random byte arrays.
  """
  fun name(): String => "inflate/adler32/property/reference"

  fun gen(): Generator[Array[U8] val] =>
    Generators.map2[U8, USize, Array[U8] val](
      Generators.u8(),
      Generators.usize(0, 6000),
      {(fill, len) => recover val Array[U8].init(fill, len) end })

  fun property(sample: Array[U8] val, h: PropertyHelper) =>
    // Reference implementation: direct computation without NMAX optimization
    let base: U32 = 65521
    var s1: U32 = 1
    var s2: U32 = 0
    for b in sample.values() do
      s1 = (s1 + b.u32()) % base
      s2 = (s2 + s1) % base
    end
    let expected = (s2 << 16) or s1

    h.assert_eq[U32](expected, _Adler32(sample))
