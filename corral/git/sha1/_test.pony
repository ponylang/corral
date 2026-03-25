use "pony_test"
use "pony_check"
use crypto = "ssl/crypto"

actor \nodoc\ Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(Property1UnitTest[Array[U8] val](_PropertySha1DigestSize))
    test(Property1UnitTest[Array[U8] val](_PropertySha1HexSize))
    test(_TestSha1Empty)
    test(_TestSha1Abc)
    test(_TestSha1Long)
    test(_TestSha1GitObject)
    test(_TestSha1FromChunksEquivalence)
    test(_TestSha1HexFormat)

class \nodoc\ _PropertySha1DigestSize is Property1[Array[U8] val]
  """SHA-1 digest is always 20 bytes for arbitrary input."""
  fun name(): String => "sha1/property/digest-size"

  fun gen(): Generator[Array[U8] val] =>
    Generators.map2[U8, USize, Array[U8] val](
      Generators.u8(),
      Generators.usize(0, 200),
      {(fill, len) => recover val Array[U8].init(fill, len) end })

  fun property(sample: Array[U8] val, h: PropertyHelper) =>
    h.assert_eq[USize](20, GitSha1(sample).size())

class \nodoc\ _PropertySha1HexSize is Property1[Array[U8] val]
  """SHA-1 hex string is always 40 characters for arbitrary input."""
  fun name(): String => "sha1/property/hex-size"

  fun gen(): Generator[Array[U8] val] =>
    Generators.map2[U8, USize, Array[U8] val](
      Generators.u8(),
      Generators.usize(0, 200),
      {(fill, len) => recover val Array[U8].init(fill, len) end })

  fun property(sample: Array[U8] val, h: PropertyHelper) =>
    h.assert_eq[USize](40, GitSha1.hex(sample).size())

class \nodoc\ iso _TestSha1Empty is UnitTest
  """NIST FIPS 180-4: SHA-1 of empty string."""
  fun name(): String => "sha1/nist/empty"

  fun apply(h: TestHelper) =>
    let expected = "da39a3ee5e6b4b0d3255bfef95601890afd80709"
    h.assert_eq[String val](expected, GitSha1.hex(""))

class \nodoc\ iso _TestSha1Abc is UnitTest
  """NIST FIPS 180-4: SHA-1 of "abc"."""
  fun name(): String => "sha1/nist/abc"

  fun apply(h: TestHelper) =>
    let expected = "a9993e364706816aba3e25717850c26c9cd0d89d"
    h.assert_eq[String val](expected, GitSha1.hex("abc"))

class \nodoc\ iso _TestSha1Long is UnitTest
  """NIST FIPS 180-4: SHA-1 of the 448-bit test string."""
  fun name(): String => "sha1/nist/long"

  fun apply(h: TestHelper) =>
    let input = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
    let expected = "84983e441c3bd26ebaae4aa1f95129e5e54670f1"
    h.assert_eq[String val](expected, GitSha1.hex(input))

class \nodoc\ iso _TestSha1GitObject is UnitTest
  """
  SHA-1 of a git blob object. Verified with:
    echo -n hello | git hash-object --stdin
    printf 'blob 5\0hello' | sha1sum
  """
  fun name(): String => "sha1/git-object"

  fun apply(h: TestHelper) =>
    let expected = "b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0"
    h.assert_eq[String val](expected, GitSha1.hex("blob 5\0hello"))

    // Same result via from_chunks
    let chunks: Array[ByteSeq] val = ["blob 5\0"; "hello"]
    h.assert_eq[String val](expected, GitSha1.hex_from_chunks(chunks))

class \nodoc\ iso _TestSha1FromChunksEquivalence is UnitTest
  """from_chunks produces the same digest as apply on concatenated input."""
  fun name(): String => "sha1/from-chunks-equivalence"

  fun apply(h: TestHelper) =>
    let whole = GitSha1("blob 5\0hello")
    let chunks: Array[ByteSeq] val = ["blob 5\0"; "hello"]
    let chunked = GitSha1.from_chunks(chunks)

    h.assert_eq[USize](whole.size(), chunked.size())
    var i: USize = 0
    while i < whole.size() do
      try
        h.assert_eq[U8](whole(i)?, chunked(i)?)
      end
      i = i + 1
    end

class \nodoc\ iso _TestSha1HexFormat is UnitTest
  """Hex output is exactly 40 characters, all lowercase hex."""
  fun name(): String => "sha1/hex-format"

  fun apply(h: TestHelper) =>
    let hex_str = GitSha1.hex("test")
    h.assert_eq[USize](40, hex_str.size())
    for c in hex_str.values() do
      let valid =
        ((c >= '0') and (c <= '9')) or ((c >= 'a') and (c <= 'f'))
      h.assert_true(valid, "character '" + String.from_array([c]) + "' is not lowercase hex")
    end
