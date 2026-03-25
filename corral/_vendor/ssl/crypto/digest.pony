use "path:/usr/local/opt/libressl/lib" if osx and x86
use "path:/opt/homebrew/opt/libressl/lib" if osx and arm
use "lib:crypto"
use "lib:bcrypt" if windows

use @EVP_MD_CTX_new[Pointer[_EVPCTX]]() if "openssl_1.1.x" or "openssl_3.0.x" or "libressl"
use @EVP_DigestInit_ex[I32](ctx: Pointer[_EVPCTX] tag, t: Pointer[_EVPMD], impl: USize)
use @EVP_DigestUpdate[I32](ctx: Pointer[_EVPCTX] tag, d: Pointer[U8] tag, cnt: USize)
use @EVP_DigestFinal_ex[I32](ctx: Pointer[_EVPCTX] tag, md: Pointer[U8] tag, s: Pointer[USize])
use @EVP_DigestFinalXOF[I32](ctx: Pointer[_EVPCTX] tag, md: Pointer[U8] tag, len: USize) if "openssl_3.0.x"
use @EVP_MD_CTX_free[None](ctx: Pointer[_EVPCTX]) if "openssl_1.1.x" or "openssl_3.0.x" or "libressl"

use @EVP_md5[Pointer[_EVPMD]]()
use @EVP_ripemd160[Pointer[_EVPMD]]()
use @EVP_sha1[Pointer[_EVPMD]]()
use @EVP_sha224[Pointer[_EVPMD]]()
use @EVP_sha256[Pointer[_EVPMD]]()
use @EVP_sha384[Pointer[_EVPMD]]()
use @EVP_sha512[Pointer[_EVPMD]]()
use @EVP_shake128[Pointer[_EVPMD]]()
use @EVP_shake256[Pointer[_EVPMD]]()

primitive _EVPMD
primitive _EVPCTX

class Digest
  """
  Produces a hash from the chunks of input. Feed the input with append() and
  produce a final hash from the concatenation of the input with final().
  """
  let _digest_size: USize
  let _ctx: Pointer[_EVPCTX]
  let _variable_length: Bool
  var _hash: (Array[U8] val | None) = None

  new md5() =>
    """
    Use the MD5 algorithm to calculate the hash.
    """
    _variable_length = false
    _digest_size = 16
    ifdef "openssl_1.1.x" or "openssl_3.0.x" or "libressl" then
      _ctx = @EVP_MD_CTX_new()
    else
      compile_error "You must select an SSL version to use."
    end
    @EVP_DigestInit_ex(_ctx, @EVP_md5(), USize(0))

  new ripemd160() =>
    """
    Use the RIPEMD160 algorithm to calculate the hash.
    """
    _variable_length = false
    _digest_size = 20
    ifdef "openssl_1.1.x" or "openssl_3.0.x" or "libressl" then
      _ctx = @EVP_MD_CTX_new()
    else
      compile_error "You must select an SSL version to use."
    end
    @EVP_DigestInit_ex(_ctx, @EVP_ripemd160(), USize(0))

  new sha1() =>
    """
    Use the SHA1 algorithm to calculate the hash.
    """
    _variable_length = false
    _digest_size = 20
    ifdef "openssl_1.1.x" or "openssl_3.0.x" or "libressl" then
      _ctx = @EVP_MD_CTX_new()
    else
      compile_error "You must select an SSL version to use."
    end
    @EVP_DigestInit_ex(_ctx, @EVP_sha1(), USize(0))

  new sha224() =>
    """
    Use the SHA256 algorithm to calculate the hash.
    """
    _variable_length = false
    _digest_size = 28
    ifdef "openssl_1.1.x" or "openssl_3.0.x" or "libressl" then
      _ctx = @EVP_MD_CTX_new()
    else
      compile_error "You must select an SSL version to use."
    end
    @EVP_DigestInit_ex(_ctx, @EVP_sha224(), USize(0))

  new sha256() =>
    """
    Use the SHA256 algorithm to calculate the hash.
    """
    _variable_length = false
    _digest_size = 32
    ifdef "openssl_1.1.x" or "openssl_3.0.x" or "libressl" then
      _ctx = @EVP_MD_CTX_new()
    else
      compile_error "You must select an SSL version to use."
    end
    @EVP_DigestInit_ex(_ctx, @EVP_sha256(), USize(0))

  new sha384() =>
    """
    Use the SHA384 algorithm to calculate the hash.
    """
    _variable_length = false
    _digest_size = 48
    ifdef "openssl_1.1.x" or "openssl_3.0.x" or "libressl" then
      _ctx = @EVP_MD_CTX_new()
    else
      compile_error "You must select an SSL version to use."
    end
    @EVP_DigestInit_ex(_ctx, @EVP_sha384(), USize(0))

  new sha512() =>
    """
    Use the SHA512 algorithm to calculate the hash.
    """
    _variable_length = false
    _digest_size = 64
    ifdef "openssl_1.1.x" or "openssl_3.0.x" or "libressl" then
      _ctx = @EVP_MD_CTX_new()
    else
      compile_error "You must select an SSL version to use."
    end
    @EVP_DigestInit_ex(_ctx, @EVP_sha512(), USize(0))

  new shake128(size': USize = 16) =>
    """
    Use the SHAKE128 algorithm to calculate the hash.

    SHAKE128 is an extendable output function (XOF) that can produce
    variable-length output. The `size'` parameter controls the output length
    in bytes (default: 16). Variable-length output requires OpenSSL 3.0.x;
    on OpenSSL 1.1.x, the default size is always used.
    """
    ifdef "openssl_1.1.x" or "openssl_3.0.x" then
      ifdef "openssl_3.0.x" then
        _variable_length = true
        _digest_size = size'
      else
        _variable_length = false
        _digest_size = 16
      end
      _ctx = @EVP_MD_CTX_new()
      @EVP_DigestInit_ex(_ctx, @EVP_shake128(), USize(0))
    else
      compile_error "shake128 is only supported with OpenSSL 1.1.x or 3.0.x"
    end

  new shake256(size': USize = 32) =>
    """
    Use the SHAKE256 algorithm to calculate the hash.

    SHAKE256 is an extendable output function (XOF) that can produce
    variable-length output. The `size'` parameter controls the output length
    in bytes (default: 32). Variable-length output requires OpenSSL 3.0.x;
    on OpenSSL 1.1.x, the default size is always used.
    """
    ifdef "openssl_1.1.x" or "openssl_3.0.x" then
      ifdef "openssl_3.0.x" then
        _variable_length = true
        _digest_size = size'
      else
        _variable_length = false
        _digest_size = 32
      end
      _ctx = @EVP_MD_CTX_new()
      @EVP_DigestInit_ex(_ctx, @EVP_shake256(), USize(0))
    else
      compile_error "shake256 is only supported with OpenSSL 1.1.x or 3.0.x"
    end

  fun ref append(input: ByteSeq) ? =>
    """
    Update the Digest object with input. Throw an error if final() has been
    called.
    """
    if _hash isnt None then error end
    @EVP_DigestUpdate(_ctx, input.cpointer(), input.size())

  fun ref final(): Array[U8] val =>
    """
    Return the digest of the strings passed to the append() method.
    """
    match _hash
    | let h: Array[U8] val => h
    else
      let size = _digest_size
      let digest =
        recover String.from_cpointer(
          @pony_alloc(@pony_ctx(), size), size)
        end
      if not _variable_length then
        @EVP_DigestFinal_ex(_ctx, digest.cpointer(), Pointer[USize])
      else
        ifdef "openssl_3.0.x" then
          @EVP_DigestFinalXOF(_ctx, digest.cpointer(), size)
        else
          @EVP_DigestFinal_ex(_ctx, digest.cpointer(), Pointer[USize])
        end
      end
      ifdef "openssl_1.1.x" or "openssl_3.0.x" or "libressl" then
        @EVP_MD_CTX_free(_ctx)
      else
        compile_error "You must select an SSL version to use."
      end
      let h = (consume digest).array()
      _hash = h
      h
    end

  fun digest_size(): USize =>
    """
    Return the size of the message digest in bytes.
    """
    _digest_size
