use "path:/usr/local/opt/libressl/lib" if osx and x86
use "path:/opt/homebrew/opt/libressl/lib" if osx and arm
use "lib:crypto"

use @HMAC[Pointer[U8]](
  evp_md: Pointer[_EVPMD],
  key: Pointer[U8] tag, key_len: I32,
  data: Pointer[U8] tag, data_len: USize,
  md: Pointer[U8] tag, md_len: Pointer[U32])

primitive HmacSha256
  """
  Compute HMAC using SHA-256 as the hash function, as defined in RFC 2104.

  Returns a 32-byte message authentication code.

  ```pony
  let mac = HmacSha256("secret-key", "Hello, World!")
  ```
  """
  fun tag apply(key: ByteSeq, data: ByteSeq): Array[U8] val =>
    recover
      // Use Array.init instead of pony_alloc + from_cpointer to avoid
      // intermittent GC buffer corruption. See ponyc#4831.
      let size: USize = 32
      let arr = Array[U8].init(0, size)
      @HMAC(@EVP_sha256(), key.cpointer(), key.size().i32(),
        data.cpointer(), data.size(), arr.cpointer(), Pointer[U32])
      arr
    end
