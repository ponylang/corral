use "cli"
use "logger"
//use "ponycc/ast"
//use "ponycc/ast/parse"

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
            "Initializes the project.json and bundle-lock.json files with skeletal information.")
          CommandSpec.leaf("info",
            "Prints all or specific information about the project from project.json.")
          CommandSpec.parent("add", "", Array[OptionSpec](), [
              CommandSpec.leaf("github",
                "Adds a remote bundle from a Github repository.", [
                  OptionSpec.string("tag", "Git tag to pull" where short' = 't', default' = "")
                  OptionSpec.string("subdir", "Subdir of project in repo" where short' = 'd', default' = "")
                ], [
                  ArgSpec.string("repo", "Organization/repository name.")
                ])
              CommandSpec.leaf("git", "Adds a bundle from a local git repository.", [
                  OptionSpec.string("tag", "Git tag to pull" where short' = 't', default' = "")
                ], [
                  ArgSpec.string("path", "Local path to Git repo.")
                ])
              CommandSpec.leaf("local", "Adds a bundle from a local path.",
                Array[OptionSpec](), [
                  ArgSpec.string("path", "Local path to bundle project.")
                ])
            ])
          CommandSpec.leaf("remove",
            "Removes one or more bundles from the corral.")
          CommandSpec.leaf("update",
            "Updates one or more or all of the bundles in the corral to their best revision.")
          CommandSpec.leaf("fetch",
            "Fetches one or more or all of the bundles into the corral.")
          CommandSpec.leaf("list",
            "Lists the bundles and packages, including corral details.")
          CommandSpec.leaf("run",
            "Runs a shell command inside an environment with the corral on the PONYPATH.")
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

    // TODO: Command should have a name() or fullname() that is cs1/cs2/cs3

    match cmd.spec().name()
    | "corral" =>
      Help.general(cs).print_help(env.out)
      env.exitcode(0)
      return
    | "init" => CmdInit(env, log, cmd)
    | "info" => CmdInfo(env, log, cmd)
//      | "add" => CmdAdd(env, log, cmd)
    | "github" => CmdAddGithub(env, log, cmd)
    | "git" => CmdAddGit(env, log, cmd)
    | "local" => CmdAddLocal(env, log, cmd)
    | "remove" => CmdRemove(env, log, cmd)
    | "update" => CmdUpdate(env, log, cmd)
    | "fetch" => CmdFetch(env, log, cmd)
    | "list" => CmdList(env, log, cmd)
    | "run" => CmdRun(env, log, cmd)
    else
      // TODO: parent Commands should be an error
      Help.general(cs).print_help(env.out)
      env.exitcode(0)
      return
    end

    /*
    try
      let src = Source("use \"collections\"", "test.pony")
      let errs = Array[(String, SourcePosAny)]
      let parse = Parse(src, errs)
    end
    */
