use "cli"
use "files"
use "ponytest"
use "../util"

interface val Checker
  fun apply(h: TestHelper, ar: ActionResult)


primitive Execute
  fun apply(h: TestHelper, args: Array[String] val, checker: (Checker | None) = None) =>
    try
      let evars = EnvVars(h.env.vars)
      let corral_bin = evars.get_or_else("CORRAL_BIN", "corral")
      let corral_prog = Program(h.env, corral_bin)?
      let corral_cmd = Action(corral_prog, args, h.env.vars)
      match checker
      | let chk: Checker => Runner.run(corral_cmd, {(ar: ActionResult) => chk(h, ar)} iso)
      | None => Runner.run(corral_cmd, {(ar: ActionResult) => None} iso)
      end
    else
      h.fail("failed to create corral Program")
    end


primitive Data
  fun apply(h: TestHelper, subdir: String = ""): FilePath ? =>
    let auth = h.env.root as AmbientAuth
    FilePath(auth, "corral/test/testdata")?.join(subdir)?


class val DataClone
  let _root: FilePath
  let _dir: FilePath

  new val create(h: TestHelper, subdir: String = "") ? =>
    let auth = h.env.root as AmbientAuth
    let src_root = FilePath(auth, "corral/test/testdata")?

    _root = FilePath.mkdtemp(auth, "test_scratch.")?
    _dir = _root.join(subdir)?

    Copy.tree(src_root, _root, subdir)?
    //h.env.err.print("cloned _root: " + _root.path)

  fun cleanup(h: TestHelper) =>
    //h.env.err.print("cleaning up _root: " + _root.path)
    _root.remove()

  fun dir(): String => _dir.path

  fun dir_path(subdir: String): FilePath ? => _dir.join(subdir)?


class val DataNone
  fun cleanup(h: TestHelper) => None
  fun dir(): String => ""
  fun dir_path(subdir: String): FilePath ? => error


primitive Copy
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

  fun file(from_path: FilePath, to_path: FilePath) =>
    let from_file = match OpenFile(from_path)
    | let f: File => f
    else
      return
    end
    let to_file = match CreateFile(to_path)
    | let f: File => f
    else
      return
    end
    while from_file.errno() is FileOK do
      to_file.write(from_file.read(65536))
    end
