use "cli"
use "logger"

actor Main
  let _env: Env
  new create(env: Env) =>
    _env = env
    let log = StringLogger(Fine, env.err)

    let cs = try
        CommandSpec.parent("corral", "", [
          OptionSpec.bool("quiet", "Quiet output."
            where short'='q', default' = false)
          OptionSpec.bool("nothing", "Don't actually apply changes."
            where short' = 'n', default' = false)
          OptionSpec.bool("verbose", "Verbose output."
            where short'='v', default' = false)
        ], [
          CommandSpec.leaf("init",
            "Initializes the bundle.json and dep-lock.json files with skeletal information.")
          CommandSpec.leaf("info",
            "Prints all or specific information about the bundle from bundle.json.")
          CommandSpec.parent("add", "", Array[OptionSpec](), [
            CommandSpec.leaf("github",
              "Adds a remote dep from a Github repository.", [
                OptionSpec.string("tag", "Git tag to pull" where short' = 't', default' = "")
                OptionSpec.string("subdir", "Subdir of bundle in repo" where short' = 'd', default' = "")
              ], [
                ArgSpec.string("repo", "Organization/repository name.")
              ])
            CommandSpec.leaf("git", "Adds a dep from a local git repository.", [
                OptionSpec.string("tag", "Git tag to pull" where short' = 't', default' = "")
              ], [
                ArgSpec.string("path", "Local path to Git repo.")
              ])
            CommandSpec.leaf("local", "Adds a dep from a local path.",
              Array[OptionSpec](), [
                ArgSpec.string("path", "Local path to dep bundle.")
              ])
            ])
          CommandSpec.leaf("remove",
            "Removes one or more deps from the corral.")
          CommandSpec.leaf("update",
            "Updates one or more or all of the deps in the corral to their best revision.")
          CommandSpec.leaf("fetch",
            "Fetches one or more or all of the deps into the corral.")
          CommandSpec.leaf("list",
            "Lists the deps and packages, including corral details.")
          CommandSpec.leaf("run",
            "Runs a shell command inside an environment with the corral on the PONYPATH.",
            Array[OptionSpec](), [
              ArgSpec.string_seq("args", "Arguments to run.")
            ])
        ]).>add_help()
      else
        log(Error) and log.log("CLI Init error")
        env.exitcode(-1)  // some kind of coding error
        return
      end

    let cmd =
      match CommandParser(cs).parse(env.args, env.vars())
      | let c: Command => c
      | let ch: CommandHelp =>
        ch.print_help(env.out)
        env.exitcode(0)
        return
      | let se: SyntaxError =>
        env.out.print(se.string())
        env.exitcode(1)
        return
      end

    let quiet = cmd.option("quiet").bool()
    let nothing = cmd.option("nothing").bool()

    env.out.print("Cmd: " + cmd.string())

    match cmd.fullname()
    | "corral/init" => CmdInit(env, log, cmd)
    | "corral/info" => CmdInfo(env, log, cmd)
    | "corral/add/github" => CmdAddGithub(env, log, cmd)
    | "corral/add/git" => CmdAddGit(env, log, cmd)
    | "corral/add/local" => CmdAddLocal(env, log, cmd)
    | "corral/remove" => CmdRemove(env, log, cmd)
    | "corral/update" => CmdUpdate(env, log, cmd)
    | "corral/fetch" => CmdFetch(env, log, cmd)
    | "corral/list" => CmdList(env, log, cmd)
    | "corral/run" => CmdRun(env, log, cmd)
    else
      Help.general(cs).print_help(env.out)
      env.exitcode(0)
      return
    end
