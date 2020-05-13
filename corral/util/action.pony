use "cli"  // EnvVars
use "files"
use "process"

class val Program
  """
  A Program encapsulates an executable program and authority to execute it.
  """
  let auth: AmbientAuth
  let path: FilePath

  new val create(
    env: Env,
    name: String) ?
  =>
    path = if Path.is_abs(name) then
      FilePath(env.root, name)?
    else
      (let evars, let pathkey) =
        ifdef windows then
          // environment variables are case-insensitive on Windows
          (EnvVars(env.vars, "", true), "path")
        else
          (EnvVars(env.vars), "PATH")
        end
      first_existing(env.root, evars.get_or_else(pathkey, ""), name)?
    end

  fun tag first_existing(auth': AmbientAuth, binpath: String, name: String)
    : FilePath ?
  =>
    for bindir in Path.split_list(binpath).values() do
      try
        let bd = FilePath(auth', bindir)?
        ifdef windows then
          let bin_bare = FilePath(bd, name)?
          if bin_bare.exists() then return bin_bare end
          let bin_exe = FilePath(bd, name + ".exe")?
          if bin_exe.exists() then return bin_exe end
        else
          let bin = FilePath(bd, name)?
          if bin.exists() then
            // TODO: should also stat for executable. FileInfo(bin)
            return bin
          end
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

  new val create(
    prog': Program val,
    args': Array[String] val,
    vars': Array[String] val = recover val Array[String] end)
  =>
    prog = prog'
    args = args'
    vars = vars'

class val ActionResult
  """
  The results of an Action which includes its exit code, out and err streams as
  Strings, and and error message if the Action failed.
  """
  let exit_status: ProcessExitStatus
  let stdout: String
  let stderr: String
  let errmsg: String

  new val ok(exit_status': ProcessExitStatus, stdout': String, stderr': String) =>
    exit_status = exit_status'
    stdout = stdout'
    stderr = stderr'
    errmsg = ""

  new val fail(errmsg': String, exit_status': ProcessExitStatus = Exited(-1)) =>
    exit_status = exit_status'
    stdout = ""
    stderr = ""
    errmsg = errmsg'

  fun val exit_code(): I32 =>
    match exit_status
    | let exited: Exited => exited.exit_code()
    | let signaled: Signaled =>
      // simulate bash signal to return code mapping
      I32(128) + signaled.signal().i32()
    end

  fun val print_to(out: OutStream) =>
    out.print("  exit: " + exit_status.string())
    out.print("  out: " + stdout)
    out.print("  err: " + stderr)

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
    ProcessMonitor(
      action.prog.auth,
      action.prog.auth,
      consume c,
      action.prog.path, consume argv,
      action.vars).done_writing()

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
    let cr = ActionResult.fail(err.string())
    _result(cr)

  fun ref dispose(process: ProcessMonitor ref, child_exit_status: ProcessExitStatus) =>
    let cr = ActionResult.ok(child_exit_status,
      recover val _stdout.clone() end,
      recover val _stderr.clone() end)
    _result(cr)

//https://www.gnu.org/software/libc/manual/html_node/Working-Directory.html
//use @chdir[I32](filename: Pointer[U8] tag)
//use @fchdir[I32](filename: Pointer[U8] tag)
