use "cli"
use "util"
use "cmd"

actor Main
  new create(env: Env) =>
    // Parse the CLI args and handle help and errors.
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
    let log = Log(Level(debug), env.err, LevelLogFormatter)

    let quiet = cmd.option("quiet").bool()
    let verbose = cmd.option("verbose").bool()
    let ulvl = if verbose then LvlFine else LvlWarn end
    let ulvl_info = if quiet then LvlWarn else LvlInfo end
    let uout = Log(ulvl, env.out, SimpleLogFormatter)
    let uout_info = Log(ulvl_info, env.out, SimpleLogFormatter)

    // Create the specific command object
    let command: (CmdType, Log) = match cmd.fullname()
      | "corral/add" => (CmdAdd(cmd), uout)
      | "corral/clean" => (CmdClean(cmd), uout)
      | "corral/fetch" => (CmdFetch(cmd), uout)
      | "corral/info" => (CmdInfo(cmd), uout_info)
      | "corral/init" => (CmdInit(cmd), uout)
      | "corral/list" => (CmdList(cmd), uout_info)
      | "corral/remove" => (CmdRemove(cmd), uout)
      | "corral/run" => (CmdRun(cmd), uout)
      | "corral/update" => (CmdUpdate(cmd), uout)
      | "corral/version" => (CmdVersion(cmd), uout_info)
      else
        log.err("Internal error: unexpected command: " + cmd.fullname())
        env.exitcode(2)
        return
      end

    // Hand off to Executor to resolve required dirs and execute the command
    Executor.execute(
      command._1, env, log, command._2,
      cmd.option("nothing").bool(), cmd.option("bundle_dir").string())
