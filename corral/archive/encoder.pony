use "buffered"
use "collections"
use "files"
use "../mort"

class ArchiveEncoder
  let _root: FilePath
  let _writer: Writer = Writer

  new create(root: FilePath, version: U8 = 1) ? =>
    """
    Creates a new corral archive with no entries

    `root` is filesystem path root for all archive entries.
    If `root` is set to `/home/pony` then when adding an entry:
      `/home/pony/corral.json`
    """
    _root = root

    if version != 1 then
      error
    end

    _writer.u8(version)

  // TODO: change to "add_package" that takes a directory
  // add single "corral.json" addition method as well.
  fun ref add(from: FilePath) ? =>
    """
    Adds the contents of `from` to the Corral archive file `to`.

    - Directories are recursively added.
    - Symlinks are ignored
    """

    // If we don't have FileStat on from, we are going to fail later, let's do
    // it now. Failing early here means we should be able to 'ignore' errors
    // in the later `try` as we've already validated all sources of issues
    // earlier.
    if not from.caps(FileStat) then
      error
    end


    try
      let i = FileInfo(from)?

      if i.file then
        _add_file(from)
      elseif i.directory then
        _add_package(from)
      end
    else
      Unreachable()
    end

  fun ref write(to: FilePath) ? =>
    """
    Creates a new archive file at `to`. Throws an error if it is unable to
    create the archive.

    - Removes any existing file at `to`
    - Resets the archiver after writing
    """

    match CreateFile(to)
    | let archive: File =>
      archive.set_length(0)

      for c in _writer.done().values() do
        archive.write(c)
      end

      archive.dispose()
    else
      error
    end

  fun ref _add_file(e: FilePath) =>
    // type: file
    _writer.u8(1)

    // file name size and file name
    let n = _name_from_root(e.path)
    _writer.i32_le(n.size().i32())
    _writer.write(n)

    // file content size and file content
    let file = File.open(e)
    let cs = file.size()
    _writer.i32_le(cs.i32())
    _writer.write(file.read(cs))

  fun ref _add_package(package: FilePath) =>
    // type: package
    _writer.u8(2)

    // package name size and package name
    let n = _name_from_root(package.path)
    _writer.i32_le(n.size().i32())
    _writer.write(n)

    // add files in package
    try
      with dir = Directory(package)? do
        let sorted_entries = Sort[Array[String], String](dir.entries()?)
        for e in sorted_entries.values() do
          let p = package.join(e)?
          let i = FileInfo(p)?
          if i.file then
            _add_file(p)
          end
        end
      end
    else
      Unreachable()
    end

  fun _name_from_root(path: String): String =>
    try
      Path.rel(_root.path, path)?
    else
      Unreachable()
      ""
    end
