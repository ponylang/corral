use "cli"
use "files"
use "util"
use "cmd"
use "bundle"

primitive Info
  fun version(): String => Version()

actor Main
  new create(env: Env) =>
    let cmd =
      match recover val CLI.parse(env.args, env.vars) end
      | let c: Command => c
      | (let exit_code: U8, let msg: String) =>
        if exit_code == 0 then
          env.out.print(msg)
        else
          Log(LvlErrr, env.err, LevelLogFormatter).err(msg)
          env.out.print(CLI.help())
          env.exitcode(exit_code.i32())
        end
        return
      end

    // Setup options and helpers used by commands
    let debug = cmd.option("debug").u64()
    let quiet = cmd.option("quiet").bool()
    let verbose = cmd.option("verbose").bool()
    let ulvl = if verbose then LvlFine elseif quiet then LvlWarn else LvlInfo end
    let nothing = cmd.option("nothing").bool()

    let log = Log(Level(debug), env.err, LevelLogFormatter)
    let uout = Log(ulvl, env.out, SimpleLogFormatter)

    let auth = try
      env.root as AmbientAuth
    else
      log.err("Internal error: unable to get AmbientAuth.")
      env.exitcode(2)
      return
    end

    // Quick commands can be run now without a full context.
    match cmd.fullname()
    | "corral/version" =>
      uout.info("version: " + Info.version())
      return
    end

    // Build the command context
    let context = try
      let bundle_dir_maybe = match cmd.option("bundle_dir").string()
      | "" => BundleFile.find_bundle_dir(auth, Path.cwd(), log)
      | let dir': String => BundleFile.resolve_bundle_dir(auth, Path.clean(dir'), log)
      end
      let bundle_dir = match bundle_dir_maybe
      | let dirpath': FilePath => dirpath'
      | None => FilePath(auth, Path.cwd())?  // No bundle found, use cwd and let cmds handle it
      end
      // TODO: move default repo_cache to user home and add flag
      // https://github.com/ponylang/corral/issues/28
      let repo_cache = bundle_dir.join("_repos")?
      Context(env, log, uout, nothing, bundle_dir, repo_cache)
    else
      log.err("Internal error: could not access required directories")
      env.exitcode(2)
      return
    end
    //log.fine("Cmd: " + cmd.string())

    // Execute the command
    match cmd.fullname()
    | "corral/init" => CmdInit(context, cmd)
    | "corral/info" => CmdInfo(context, cmd)
    | "corral/add" => CmdAdd(context, cmd)
    | "corral/remove" => CmdRemove(context, cmd)
    | "corral/list" => CmdList(context, cmd)
    | "corral/clean" => CmdClean(context, cmd)
    | "corral/update" => CmdUpdate(context, cmd)
    | "corral/fetch" => CmdFetch(context, cmd)
    | "corral/run" => CmdRun(context, cmd)
    else
      log.err("Internal error: unexpected command: " + cmd.fullname())
      env.exitcode(2)
    end
