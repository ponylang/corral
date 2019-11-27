use "cli"
use "files"
use "util"
use "cmd"
use "bundle"

primitive Info
  fun version(): String => Version()

actor Main
  new create(env: Env) =>
    let log = Log(LvlFine, env.err, LevelLogFormatter)
    let auth = try
      env.root as AmbientAuth
    else
      log.err("Internal error: unable to get AmbientAuth.")
      env.exitcode(2)
      return
    end

    let cmd =
      match recover val CLI.parse(env.args, env.vars) end
      | let c: Command => c
      | (let exit_code: U8, let msg: String) =>
        if exit_code == 0 then
          env.out.print(msg)
        else
          log.err(msg)
          env.out.print(CLI.help())
          env.exitcode(exit_code.i32())
        end
        return
      end

    // Quick commands can be run now without a bundle_dir or Context
    match cmd.fullname()
    | "corral/version" =>
      env.out.print("corral " + Info.version())
      return
    end

    let quiet = cmd.option("quiet").bool()
    let verbose = cmd.option("verbose").bool()
    let nothing = cmd.option("nothing").bool()

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
      Context(env, log, quiet, nothing, bundle_dir, repo_cache)
    else
      log.err("Internal error: could not access required directories")
      env.exitcode(2)
      return
    end
    //log.fine("Cmd: " + cmd.string())

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
