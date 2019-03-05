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
    path': FilePath) ?
  =>
    auth = env.root as AmbientAuth
    path = path'

  new val on_path(
    env: Env,
    name: String) ?
  =>
    auth = env.root as AmbientAuth
    let evars = EnvVars(env.vars)
    path = first_existing(auth, evars.get_or_else("PATH", ""), name)?

  fun tag first_existing(auth': AmbientAuth, binpath: String, name: String): FilePath ? =>
    for bindir in Path.split_list(binpath).values() do
      try
        let bd = FilePath(auth', bindir)?
        let bin = FilePath(bd, name)?
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

  new val create(
    prog': Program val,
    args': Array[String] val,
    vars': Array[String] val = recover val Array[String] end)
  =>
    prog = prog'
    args = args'
    vars = vars'


class val ActionResult
  let exit_code: I32
  let stdout: String
  let stderr: String
  let errmsg: String

  new val ok(exit_code': I32, stdout': String, stderr': String) =>
    exit_code = exit_code'
    stdout = stdout'
    stderr = stderr'
    errmsg = ""

  new val fail(errmsg': String) =>
    exit_code = -1
    stdout = ""
    stderr = ""
    errmsg = errmsg'

  fun val print_to(out: OutStream) =>
    out.print("  exit: " + exit_code.string())
    out.print("  out: " + stdout)
    out.print("  err: " + stderr)


primitive Runner
  """
  Run an Action using ProcessMonitor, and hand the resulting ActionResult to a
  given lambda.
  """
  fun run(action: Action, result: {(ActionResult)} iso) =>
    let c = _Collector(consume result)
    let argv: Array[String] iso = recover argv.create(action.args.size()+1) end
    argv.push(action.prog.path.path)
    argv.append(action.args)
    ProcessMonitor(action.prog.auth, action.prog.auth, consume c, action.prog.path, consume argv, action.vars).done_writing()


class _Collector is ProcessNotify
  """
  Collect Action output and exit into an ActionResult and hand it to the given
  lambda when ready.
  """
  let _stdout: String iso = recover String end
  let _stderr: String iso = recover String end
  var _exit_code: I32 = 0
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
    let errmsg = match err
      | ExecveError => "ProcessError: ExecveError"
      | PipeError => "ProcessError: PipeError"
      | ForkError => "ProcessError: ForkError"
      | WaitpidError => "ProcessError: WaitpidError"
      | WriteError => "ProcessError: WriteError"
      | KillError => "ProcessError: KillError"
      | Unsupported => "ProcessError: Unsupported"
      | CapError =>  "ProcessError: CapError"
      end
    let cr = ActionResult.fail(errmsg)
    _result(cr)

  fun ref dispose(process: ProcessMonitor ref, child_exit_code: I32) =>
    let cr = ActionResult.ok(child_exit_code,
      recover val _stdout.clone() end,
      recover val _stderr.clone() end)
    _result(cr)

//https://www.gnu.org/software/libc/manual/html_node/Working-Directory.html
//use @chdir[I32](filename: Pointer[U8] tag)
//use @fchdir[I32](filename: Pointer[U8] tag)
