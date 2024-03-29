use "backpressure"
use "cli"  // EnvVars
use "files"
use "process"

class val Program
  """
  A Program encapsulates an executable program and authority to execute it.
  """
  let process_auth: StartProcessAuth
  let backpressure_auth: ApplyReleaseBackpressureAuth
  let path: FilePath

  new val create(
    env: Env,
    name: String) ?
  =>
    let file_auth = FileAuth(env.root)
    process_auth = StartProcessAuth(env.root)
    backpressure_auth = ApplyReleaseBackpressureAuth(env.root)

    path = if Path.is_abs(name) then
      FilePath(file_auth, name)
    else
      let cwd = Path.cwd()
      // first try to resolve the binary with the current directory as base
      try
        first_existing(file_auth, cwd, name)?
      else
        // then try with $PATH entries
        (let evars, let pathkey) =
          ifdef windows then
            // environment variables are case-insensitive on Windows
            (EnvVars(env.vars, "", true), "path")
          else
            (EnvVars(env.vars), "PATH")
          end
        first_existing(file_auth, evars.get_or_else(pathkey, ""), name)?
      end
    end

  fun tag first_existing(auth': FileAuth, binpath: String, name: String)
    : FilePath ?
  =>
    for bindir in Path.split_list(binpath).values() do
      ifdef windows then
        let bin_bare = FilePath.create(auth', Path.join(bindir, name))
        if bin_bare.exists() then return bin_bare end
        let bin_bat = FilePath.create(auth', Path.join(bindir, name + ".bat"))
        if bin_bat.exists() then return bin_bat end
        let bin_ps1 = FilePath.create(auth', Path.join(bindir, name + ".ps1"))
        if bin_ps1.exists() then return bin_ps1 end
        let bin_exe = FilePath.create(auth', Path.join(bindir, name + ".exe"))
        if bin_exe.exists() then return bin_exe end
      else
        let bin = FilePath.create(auth', Path.join(bindir, name))
        if bin.exists() then
          // TODO: should also stat for executable. FileInfo(bin)
          return bin
        end
      end
    end
    error

class val Action
  """
  An Action encapsulates one specific executable action with a Program, cli args
  and env vars.
  """
  let prog: Program val
  let args: Array[String] val
  let vars: Array[String] val
  let cwd: (FilePath | None)

  new val create(
    prog': Program val,
    args': Array[String] val,
    vars': Array[String] val = recover val Array[String] end,
    cwd': (FilePath | None) = None)
  =>
    prog = prog'
    args = args'
    vars = vars'
    cwd = cwd'

class val ActionResult
  """
  The results of an Action which includes its exit code, out and err streams as
  Strings, and and error message if the Action failed.
  """
  let exit_status: ProcessExitStatus
  let stdout: String
  let stderr: String
  let errmsg: (String | None)

  new val ok(exit_status': ProcessExitStatus, stdout': String, stderr': String) =>
    exit_status = exit_status'
    stdout = stdout'
    stderr = stderr'
    errmsg = None

  new val fail(
    errmsg': String,
    exit_status': ProcessExitStatus = Exited(-1),
    stdout': String = "",
    stderr': String = ""
  ) =>
    exit_status = exit_status'
    stdout = stdout'
    stderr = stderr'
    errmsg = errmsg'

  fun val exit_code(): I32 =>
    match exit_status
    | let exited: Exited => exited.exit_code()
    | let signaled: Signaled =>
      // simulate bash signal to return code mapping
      I32(128) + signaled.signal().i32()
    end

  fun val print_to(out: OutStream) =>
    match errmsg
    | None =>
      out.print("  exit: " + exit_status.string())

      ifdef windows then
        let stdout' = stdout.clone()
        stdout'.replace("\r", "")
        out.print("  out:\n" + (consume stdout'))

        let stderr' = stderr.clone()
        stderr'.replace("\r", "")
        out.print("  err:\n" + (consume stderr'))
      else
        out.print("  out: " + stdout)
        out.print("  err: " + stderr)
      end
    | let err: String =>
      out.print("  failed: " + err)
    end

  fun successful(): Bool =>
    match exit_status
    | Exited(0) => true
    else
      false
    end

primitive Runner
  """
  Run an Action using ProcessMonitor, and pass the resulting ActionResult to a
  given lambda.
  """
  fun run(action: Action, result: {(ActionResult)} iso) =>
    let c = _Collector(consume result)
    let argv: Array[String] iso = recover argv.create(action.args.size()+1) end
    let appname =
      ifdef windows then
        if action.prog.path.path.contains(" ") then
          "\"" + action.prog.path.path + "\""
        else
          action.prog.path.path
        end
      else
        action.prog.path.path
      end
    argv.push(appname)
    argv.append(action.args)
    let pm = ProcessMonitor(
      action.prog.process_auth,
      action.prog.backpressure_auth,
      consume c,
      action.prog.path,
      consume argv,
      action.vars,
      try action.cwd as FilePath end)
    pm.done_writing()

class _Collector is ProcessNotify
  """
  Collect Action output and exit into an ActionResult and hand it to the given
  lambda when ready.
  """
  let _stdout: String iso = recover String end
  let _stderr: String iso = recover String end
  let _result: {(ActionResult)} iso

  new iso create(result: {(ActionResult)} iso) =>
    _result = consume result

  fun ref created(process: ProcessMonitor ref) =>
    None

  fun ref stdout(process: ProcessMonitor ref, data: Array[U8] iso) =>
    _stdout.append(consume data)

  fun ref stderr(process: ProcessMonitor ref, data: Array[U8] iso) =>
    _stderr.append(consume data)

  fun ref failed(process: ProcessMonitor ref, err: ProcessError) =>
    let cr = ActionResult.fail(
      err.string()
      where
        stdout' = recover val _stdout.clone() end,
        stderr' = recover val _stderr.clone() end
    )
    _result(cr)

  fun ref dispose(process: ProcessMonitor ref, child_exit_status: ProcessExitStatus) =>
    let cr = ActionResult.ok(child_exit_status,
      recover val _stdout.clone() end,
      recover val _stderr.clone() end)
    _result(cr)

//https://www.gnu.org/software/libc/manual/html_node/Working-Directory.html
//use @chdir[I32](filename: Pointer[U8] tag)
//use @fchdir[I32](filename: Pointer[U8] tag)
