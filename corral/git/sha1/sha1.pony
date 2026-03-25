"""
SHA-1 hashing for git object verification. Wraps ssl's Digest to isolate the
ssl dependency to this single package.

Git uses SHA-1 for object IDs: the SHA-1 hash of the object's header and
content produces the 40-character hex object ID. Use `GitSha1` for single-buffer
hashing and `GitSha1.from_chunks` when header and content are separate (avoiding
concatenation).
"""

use crypto = "ssl/crypto"

primitive GitSha1
  """
  Computes SHA-1 digests for git object verification. Wraps ssl's Digest
  to isolate the ssl dependency to this single package.

  Git uses SHA-1 for object IDs: the SHA-1 hash of the object's header
  and content produces the 40-character hex object ID. This primitive
  provides both raw bytes and hex string forms.
  """

  fun apply(data: ByteSeq): Array[U8] val =>
    """
    Returns the 20-byte SHA-1 digest of the input.
    """
    crypto.SHA1(data)

  fun hex(data: ByteSeq): String val =>
    """
    Returns the 40-character lowercase hex SHA-1 digest of the input.
    """
    crypto.ToHexString(crypto.SHA1(data))

  fun from_chunks(chunks: ReadSeq[ByteSeq] val): Array[U8] val =>
    """
    Returns the 20-byte SHA-1 digest of the concatenated chunks.
    Useful for hashing git objects where header and content are separate
    (e.g., ["blob 5\0", content]).
    """
    let d = crypto.Digest.sha1()
    for chunk in chunks.values() do
      try d.append(chunk)? else _Unreachable() end
    end
    d.final()

  fun hex_from_chunks(chunks: ReadSeq[ByteSeq] val): String val =>
    """
    Returns the 40-character lowercase hex SHA-1 digest of the
    concatenated chunks.
    """
    crypto.ToHexString(from_chunks(chunks))
