type InflateError is
  ( InflateInvalidHeader
  | InflateInvalidBlockType
  | InflateIncompleteInput
  | InflateInvalidCodeLengths
  | InflateInvalidDistance
  | InflateInvalidLitLen
  | InflateChecksumMismatch
  | InflateInvalidStoredLength
  )
  """Errors that can occur during DEFLATE decompression or zlib framing."""

primitive InflateInvalidHeader
  """Zlib header validation failed (wrong CM, bad FCHECK, or FDICT set)."""
  fun string(): String val => "invalid zlib header"

primitive InflateInvalidBlockType
  """DEFLATE block type 11 (reserved/invalid) was encountered."""
  fun string(): String val => "invalid DEFLATE block type"

primitive InflateIncompleteInput
  """Compressed data ended before the stream was complete."""
  fun string(): String val => "unexpected end of compressed data"

primitive InflateInvalidCodeLengths
  """Dynamic Huffman code lengths failed validation."""
  fun string(): String val => "invalid Huffman code lengths"

primitive InflateInvalidDistance
  """Back-reference distance exceeds current output size."""
  fun string(): String val => "invalid back-reference distance"

primitive InflateInvalidLitLen
  """Literal/length code is outside the valid range."""
  fun string(): String val => "invalid literal/length code"

primitive InflateChecksumMismatch
  """Computed Adler-32 does not match the stored checksum."""
  fun string(): String val => "Adler-32 checksum mismatch"

primitive InflateInvalidStoredLength
  """Stored block LEN does not match the complement NLEN."""
  fun string(): String val => "stored block length mismatch"
