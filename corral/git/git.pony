"""
Pure Pony git internals for corral. This package tree provides the building
blocks for reading git repositories without shelling out to the git CLI.

Sub-packages:
- `inflate` -- RFC 1951 DEFLATE decompression with RFC 1950 zlib framing
- `sha1` -- SHA-1 hashing (thin wrapper over ssl's Digest)

Future phases will add `objects`, `pack`, `refs`, `checkout`, and `protocol`.
"""
