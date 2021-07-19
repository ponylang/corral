use "files"

primitive Copy
  // TODO: Error handling here is sketchy at best because FilePath.walk
  // error handling is non-existant.
  fun tree(from_root: FilePath, to_root: FilePath, dir_name: String) ? =>
    """
    Copy the `dir_name` tree from `from_root` to under `to_root`.
    """
    // Make matching subdir under to_root
    let from_dir = from_root.join(dir_name)?
    let to_dir = to_root.join(dir_name)?
    to_dir.mkdir()

    // Copy contents of from_dir into to_dir
    from_dir.walk({(dir_path: FilePath, dir_entries: Array[String] ref) =>
      try
        let path = Path.rel(from_dir.path, dir_path.path)?
        let to_path = to_dir.join(path)?

        for entry in dir_entries.values() do
          let from_fp = dir_path.join(entry)?
          let info = FileInfo(from_fp)?
          let to_fp = to_path.join(entry)?
          if info.directory then
            to_fp.mkdir()
          else
            Copy.file(from_fp, to_fp)
          end
        end
      end
    })

  fun file(from_path: FilePath, to_path: FilePath): FileErrNo =>
    let from_file = match OpenFile(from_path)
    | let f: File => f
    | let e: FileErrNo => return e
    end
    let to_file = match CreateFile(to_path)
    | let f: File => f
    | let e: FileErrNo => return e
    end
    while from_file.errno() is FileOK do
      to_file.write(from_file.read(65536))
    end
    from_file.dispose()
    to_file.dispose()

    FileOK
