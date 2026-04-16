use "path:/usr/local/opt/libressl/lib" if osx and x86
use "path:/opt/homebrew/opt/libressl/lib" if osx and arm
use "lib:crypto"

use @RAND_bytes[I32](buf: Pointer[U8] tag, num: I32)

primitive RandBytes
  """
  Generate cryptographically secure random bytes using OpenSSL's CSPRNG.

  Returns an array of the requested number of random bytes, or raises an
  error if the CSPRNG cannot generate secure output (e.g., insufficient
  entropy during early system startup).

  ```pony
  let nonce = RandBytes(24)?
  ```
  """
  fun tag apply(size: USize): Array[U8] val ? =>
    recover
      let arr = Array[U8].init(0, size)
      let rc = @RAND_bytes(arr.cpointer(), size.i32())
      if rc != 1 then error end
      arr
    end
