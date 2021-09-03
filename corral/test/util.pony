use "cli"
use "files"
use "ponytest"
use "../util"

interface val Checker
  fun apply(h: TestHelper, ar: ActionResult)


primitive Execute
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


primitive Data
  fun apply(h: TestHelper, subdir: String = ""): FilePath ? =>
    let auth = h.env.root as AmbientAuth
    FilePath(auth, "corral/test/testdata").join(subdir)?


class val DataClone
  let _root: FilePath
  let _dir: FilePath

  new val create(h: TestHelper, subdirs: (Array[String] val | String | None) = None) ? =>
    let auth = h.env.root as AmbientAuth
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


class val DataNone
  fun cleanup(h: TestHelper) => None
  fun dir(): String => ""
  fun dir_path(subdir: String): FilePath ? => error
