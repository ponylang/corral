use "cli"
use "files"
use "strings"
use "ponytest"
use "../util"


interface \nodoc\ val Checker
  fun apply(h: TestHelper, ar: ActionResult)


primitive \nodoc\ Execute
  fun apply(h: TestHelper, args: Array[String] val, checker: (Checker | None) = None) =>
    try
      (let evars, let corral_bin_key, let corral_default) =
        ifdef windows then
          // Environment variables on Windows are case-insensitive
          (EnvVars(h.env.vars, "", true), "corral_bin", "corral.exe")
        else
          (EnvVars(h.env.vars), "CORRAL_BIN", "corral")
        end
      let corral_bin = evars.get_or_else(corral_bin_key, corral_default)
      let corral_prog = Program(h.env, corral_bin)?
      let corral_cmd = Action(corral_prog, args, h.env.vars)
      match checker
      | let chk: Checker => Runner.run(corral_cmd, {(ar: ActionResult) => chk(h, ar)} iso)
      | None => Runner.run(corral_cmd, {(ar: ActionResult) => None} iso)
      end
    else
      h.fail("failed to create corral Program")
    end


primitive \nodoc\ Data
  fun apply(h: TestHelper, subdir: String = ""): FilePath ? =>
    FilePath(FileAuth(h.env.root), "corral/test/testdata").join(subdir)?


class \nodoc\ val DataClone
  let _root: FilePath
  let _dir: FilePath

  new val create(h: TestHelper, subdirs: (Array[String] val | String | None) = None) ? =>
    let auth = FileAuth(h.env.root)
    let src_root = FilePath(auth, "corral/test/testdata")

    _root = FilePath.mkdtemp(auth, "test_scratch.")?

    let subdirs': Array[String] val =
      match consume subdirs
      | let a: Array[String] val => a
      | let s: String => recover val [ s ] end
      else
        recover val Array[String] end
      end

    _dir =
      try
        _root.join(subdirs'(0)?)?
      else
        _root.join("")?
      end

    for subdir in subdirs'.values() do
      Copy.tree(src_root, _root, subdir)?
    end

  fun cleanup(h: TestHelper) =>
    _root.remove()

  fun dir(): String => _dir.path

  fun dir_path(subdir: String): FilePath ? => _dir.join(subdir)?


class \nodoc\ val DataNone
  fun cleanup(h: TestHelper) => None
  fun dir(): String => ""
  fun dir_path(subdir: String): FilePath ? => error

primitive RelativePathToPonyc
  fun apply(h: TestHelper): String ? =>
    var cwd = Path.cwd()
    var ponyc_rel_path: String trn = recover trn String.create() end
    let env = EnvVars(h.env.vars)
    let path =
      ifdef windows then
        env("path")?
      else
        env("PATH")?
      end
    for bindir in Path.split_list(path).values() do
      let ponyc_path = FilePath(
        FileAuth(h.env.root), Path.join(bindir, "ponyc"))
      if ponyc_path.exists() then
        let prefix: String val = CommonPrefix([cwd; ponyc_path.path])
        while cwd.size() > prefix.size() do
          cwd = Path.dir(cwd)
          ponyc_rel_path = ponyc_rel_path + ".." + Path.sep()
        end
        ponyc_rel_path = ponyc_rel_path + ponyc_path.path.substring(prefix.size().isize())
        return (consume ponyc_rel_path)
      end
    end
    error
