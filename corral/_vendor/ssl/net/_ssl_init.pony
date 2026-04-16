use "path:/usr/local/opt/libressl/lib" if osx and x86
use "path:/opt/homebrew/opt/libressl/lib" if osx and arm
use "lib:ssl"
use "lib:crypto"

use @OPENSSL_init_ssl[I32](opts: U64, settings: Pointer[_OpenSslInitSettings])
use @OPENSSL_INIT_new[Pointer[_OpenSslInitSettings]]()
use @OPENSSL_INIT_free[None](settings: Pointer[_OpenSslInitSettings])

primitive _OpenSslInitSettings

// From https://github.com/ponylang/ponyc/issues/330
primitive _OpenSslInitNoLoadSslStrings    fun val apply(): U64 => 0x00100000
primitive _OpenSslInitLoadSslStrings      fun val apply(): U64 => 0x00200000
primitive _OpenSslInitNoLoadCryptoStrings fun val apply(): U64 => 0x00000001
primitive _OpenSslInitLoadCryptoStrings   fun val apply(): U64 => 0x00000002

primitive _SSLInit
  """
  This initialises SSL when the program begins.
  """
  fun _init() =>
    ifdef "openssl_1.1.x" or "openssl_3.0.x" then
      let settings = @OPENSSL_INIT_new()
      @OPENSSL_init_ssl(
        _OpenSslInitLoadSslStrings() + _OpenSslInitLoadCryptoStrings(),
        settings)
      @OPENSSL_INIT_free(settings)
    elseif "libressl" then
      @OPENSSL_init_ssl(0, Pointer[_OpenSslInitSettings])
    else
      compile_error "You must select an SSL version to use."
    end
