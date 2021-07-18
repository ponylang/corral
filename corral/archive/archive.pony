"""
Corral archive format (version 1)

Field        | Type | Description
------------ | ------ | -----------
version      | u8     | archive version (currently 1)
entries      | n/a    | 0 or more archive entries

Archive Entry:

Field        | Length | Description
------------ | ------ | -----------
type         | u8     | 1 for file, 2 for package
path-size    | i32_le | encodes variable path size (see notes)
path         | ?      | path to the entry from archive root
file-size    | i32_le | encodes variable length file content (see notes)
content      | ?      | content for a file entry

- path-size and file-size are signed and little endian encoded (i32_le)
- if type is not `file` then file-size and content are not in the entry
"""
