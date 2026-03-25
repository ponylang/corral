use "pony_test"
use "pony_check"

actor \nodoc\ Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    // Adler-32 tests
    test(_TestAdler32Empty)
    test(_TestAdler32ZeroByte)
    test(_TestAdler32Wikipedia)
    test(Property1UnitTest[Array[U8] val](_PropertyAdler32Reference))

    // Inflate tests
    test(_TestInflateEmpty)
    test(_TestInflateHello)
    test(_TestInflateRepeated)
    test(_TestInflateAllBytes)
    test(_TestInflateStored)
    test(_TestInflateDynamic)
    test(_TestInflateMaxBackRef)
    test(_TestInflateMultiBlock)
    test(_TestInflateGitObject)
    test(_TestInflateRawMinimal)
    test(_TestInflateRawFixed)
    test(_TestInflateRawStored)

    // Error path tests
    test(_TestInflateChecksumCorruption)
    test(_TestInflateTruncated)
    test(_TestInflateInvalidBlockType)
    test(_TestInflateInvalidHeader)
    test(_TestInflateStoredLengthMismatch)

    // BitReader tests
    test(_PropertyBitReaderSplit)
