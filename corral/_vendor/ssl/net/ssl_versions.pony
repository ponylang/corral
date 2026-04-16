primitive SslAutoVersion fun val apply(): ULong => 0x0

primitive Ssl3Version    fun val apply(): ULong => 0x300
primitive Tls1Version    fun val apply(): ULong => 0x301
primitive Tls1u1Version  fun val apply(): ULong => 0x302
primitive Tls1u2Version  fun val apply(): ULong => 0x303
primitive Tls1u3Version  fun val apply(): ULong => 0x304
primitive Dtls1Version   fun val apply(): ULong => 0xFEFF
primitive Dtls1u2Version fun val apply(): ULong => 0xFEFD

primitive TlsMinVersion  fun val apply(): ULong => Tls1Version()
primitive TlsMaxVersion  fun val apply(): ULong => Tls1u3Version()
primitive DtlsMinVersion fun val apply(): ULong => Dtls1Version()
primitive DtlsMaxVersion fun val apply(): ULong => Dtls1u2Version()
