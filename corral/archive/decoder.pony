use "buffered"
use "files"

primitive ArchiveDecoder
  fun apply(archive: FilePath, to: Directory) ? =>
    """
    Decodes corral archive `archive` into directory `to`
    """

    let reader: Reader = Reader

    match OpenFile(archive)
    | let f: File =>
      reader.append(f.read(f.size()))

      // version
      reader.u8()?

      while reader.size() > 0  do
        // type
        let t = reader.u8()?
        match t
        | 1 =>
          // file
          let path_size = reader.i32_le()?.usize()
          let block = reader.block(path_size)?
          let path = String.from_array(consume block)
          let file = to.create_file(path)?

          let content_size = reader.i32_le()?.usize()
          let content = reader.block(content_size)?

          file.set_length(0)
          file.write(consume content)
        | 2 =>
          // package
          let path_size = reader.i32_le()?.usize()
          let block = reader.block(path_size)?
          let path = String.from_array(consume block)
          to.mkdir(path)
        else
          error
        end
      end
    else
      error
    end
