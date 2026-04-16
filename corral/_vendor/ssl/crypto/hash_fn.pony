use "path:/usr/local/opt/libressl/lib" if osx and x86
use "path:/opt/homebrew/opt/libressl/lib" if osx and arm
use "lib:crypto"

use @MD4[Pointer[U8]](d: Pointer[U8] tag, n: USize, md: Pointer[U8])
use @MD5[Pointer[U8]](d: Pointer[U8] tag, n: USize, md: Pointer[U8])
use @RIPEMD160[Pointer[U8]](d: Pointer[U8] tag, n: USize, md: Pointer[U8])
use @SHA1[Pointer[U8]](d: Pointer[U8] tag, n: USize, md: Pointer[U8])
use @SHA224[Pointer[U8]](d: Pointer[U8] tag, n: USize, md: Pointer[U8])
use @SHA256[Pointer[U8]](d: Pointer[U8] tag, n: USize, md: Pointer[U8])
use @SHA384[Pointer[U8]](d: Pointer[U8] tag, n: USize, md: Pointer[U8])
use @SHA512[Pointer[U8]](d: Pointer[U8] tag, n: USize, md: Pointer[U8])

use "format"

interface HashFn
  """
  Produces a fixed-length byte array based on the input sequence.
  """
  fun tag apply(input: ByteSeq): Array[U8] val

primitive MD4 is HashFn
  fun tag apply(input: ByteSeq): Array[U8] val =>
    """
    Compute the MD4 message digest conforming to RFC 1320
    """
    recover
      let size: USize = 16
      let digest = @pony_alloc(@pony_ctx(), size)
      @MD4(input.cpointer(), input.size(), digest)
      Array[U8].from_cpointer(digest, size)
    end

primitive MD5 is HashFn
  fun tag apply(input: ByteSeq): Array[U8] val =>
    """
    Compute the MD5 message digest conforming to RFC 1321
    """
    recover
      let size: USize = 16
      let digest = @pony_alloc(@pony_ctx(), size)
      @MD5(input.cpointer(), input.size(), digest)
      Array[U8].from_cpointer(digest, size)
    end

primitive RIPEMD160 is HashFn
  fun tag apply(input: ByteSeq): Array[U8] val =>
    """
    Compute the RIPEMD160 message digest conforming to ISO/IEC 10118-3
    """
    recover
      let size: USize = 20
      let digest = @pony_alloc(@pony_ctx(), size)
      @RIPEMD160(input.cpointer(), input.size(), digest)
      Array[U8].from_cpointer(digest, size)
    end

primitive SHA1 is HashFn
  fun tag apply(input: ByteSeq): Array[U8] val =>
    """
    Compute the SHA1 message digest conforming to US Federal Information
    Processing Standard FIPS PUB 180-4
    """
    recover
      let size: USize = 20
      let digest = @pony_alloc(@pony_ctx(), size)
      @SHA1(input.cpointer(), input.size(), digest)
      Array[U8].from_cpointer(digest, size)
    end

primitive SHA224 is HashFn
  fun tag apply(input: ByteSeq): Array[U8] val =>
    """
    Compute the SHA224 message digest conforming to US Federal Information
    Processing Standard FIPS PUB 180-4
    """
    recover
      let size: USize = 28
      let digest = @pony_alloc(@pony_ctx(), size)
      @SHA224(input.cpointer(), input.size(), digest)
      Array[U8].from_cpointer(digest, size)
    end

primitive SHA256 is HashFn
  fun tag apply(input: ByteSeq): Array[U8] val =>
    """
    Compute the SHA256 message digest conforming to US Federal Information
    Processing Standard FIPS PUB 180-4
    """
    recover
      let size: USize = 32
      let digest = @pony_alloc(@pony_ctx(), size)
      @SHA256(input.cpointer(), input.size(), digest)
      Array[U8].from_cpointer(digest, size)
    end

primitive SHA384 is HashFn
  fun tag apply(input: ByteSeq): Array[U8] val =>
    """
    Compute the SHA384 message digest conforming to US Federal Information
    Processing Standard FIPS PUB 180-4
    """
    recover
      let size: USize = 48
      let digest = @pony_alloc(@pony_ctx(), size)
      @SHA384(input.cpointer(), input.size(), digest)
      Array[U8].from_cpointer(digest, size)
    end

primitive SHA512 is HashFn
  fun tag apply(input: ByteSeq): Array[U8] val =>
    """
    Compute the SHA512 message digest conforming to US Federal Information
    Processing Standard FIPS PUB 180-4
    """
    recover
      let size: USize = 64
      let digest = @pony_alloc(@pony_ctx(), size)
      @SHA512(input.cpointer(), input.size(), digest)
      Array[U8].from_cpointer(digest, size)
    end

primitive ToHexString
  fun tag apply(bs: Array[U8] val): String =>
    """
    Return the lower-case hexadecimal string representation of the given Array
    of U8.
    """
    let out = recover String(bs.size() * 2) end
    for c in bs.values() do
      out.append(Format.int[U8](c where
        fmt = FormatHexSmallBare, width = 2, fill = '0'))
    end
    consume out
