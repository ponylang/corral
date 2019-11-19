use "cli"
use "files"
use "util"
use "cmd"

primitive Info
  fun version(): String => Version()

actor Main
  let _env: Env
  new create(env: Env) =>
    _env = env
    let log = Log(LvlFine, env.err, LevelLogFormatter)

    let cs = try
      CommandSpec.parent(
        "corral",
        "",
        [
          OptionSpec.bool(
            "quiet",
            "Quiet output."
            where short'='q',
            default' = false)
          OptionSpec.bool(
            "nothing",
            "Don't actually apply changes."
            where short' = 'n',
            default' = false)
          OptionSpec.bool(
            "verbose",
            "Verbose output."
            where short'='v',
            default' = false)
        ],
        [
          CommandSpec.leaf(
            "version",
            "Show the version and exit")?
          CommandSpec.leaf(
            "init",
            "Initializes the corral.json and dep-lock.json files with"
              + " skeletal information.",
            [
              OptionSpec.string(
                "directory",
                "The path where corral.json and dep-lock.json will be created."
                where short' = 'p',
                default' = "")
            ]
          )?
          CommandSpec.leaf(
            "info",
            "Prints all or specific information about the bundle from"
              + " corral.json.",
            [
              OptionSpec.string(
                "directory",
                "The path where both corral.json and dep-lock.json live."
                where short' = 'p',
                default' = "")
            ])?
          CommandSpec.leaf(
            "add",
            "Adds a remote VCS, local VCS or local direct dependency.",
            [
              OptionSpec.string(
                "version",
                "Version constraint"
                where short' = 'v',
                default' = "")
              OptionSpec.string(
                "revision",
                "Specific revision: tag, branch, commit"
                where short' = 'r',
                default' = "")
              OptionSpec.string(
                "directory",
                "The path where both corral.json and dep-lock.json live."
                where short' = 'p',
                default' = "")
            ],
            [
              ArgSpec.string("locator", "Organization/repository name.")
            ])?
          CommandSpec.leaf(
            "remove",
            "Removes one or more deps from the corral.",
            [
              OptionSpec.string(
                "directory",
                "The path where both corral.json and dep-lock.json live."
                where short' = 'p',
                default' = "")
            ])?
          CommandSpec.leaf(
            "list",
            "Lists the deps and packages, including corral details.",
            [
              OptionSpec.string(
                "directory",
                "The path where both corral.json and dep-lock.json live."
                where short' = 'p',
                default' = "")
            ]
          )?
          CommandSpec.leaf(
            "clean",
            "Cleans up repo cache and working corral. Default is to clean"
              + " only working corral.",
            [
              OptionSpec.bool(
                "all",
                "Clean both repo cache and working corral."
                where short' = 'a',
                default' = false)
              OptionSpec.bool(
                "repos",
                "Clean repo cache only."
                where short' = 'r',
                default' = false)
              OptionSpec.string(
                "directory",
                "The path where both corral.json and dep-lock.json live."
                where short' = 'p',
                default' = "")
            ])?
          CommandSpec.leaf(
            "update",
            "Updates one or more or all of the deps in the corral to their"
              + " best revisions.",
            [
              OptionSpec.string(
                "directory",
                "The path where both corral.json and dep-lock.json live."
                where short' = 'p',
                default' = "")
            ])?
          CommandSpec.leaf(
            "fetch",
            "Fetches one or more or all of the deps into the corral.",
            [
              OptionSpec.string(
                "directory",
                "The path where both corral.json and dep-lock.json live."
                where short' = 'p',
                default' = "")
            ])?
          CommandSpec.leaf(
            "run",
            "Runs a shell command inside an environment with the corral on"
              + " the PONYPATH.",
            Array[OptionSpec](),
            [
              ArgSpec.string_seq("args", "Arguments to run.")
            ])?
        ])?
        .> add_help()?
      else
        log.err("CLI Init error")
        env.exitcode(-1)  // Illegal command names
        return
      end

    let cmd =
      match CommandParser(cs).parse(env.args, env.vars)
      | let c: Command => c
      | let ch: CommandHelp =>
        ch.print_help(env.out)
        env.exitcode(0)
        return
      | let se: SyntaxError =>
        env.out.print(se.string())
        Help.general(cs).print_help(env.out)
        env.exitcode(1)
        return
      end

    let quiet = cmd.option("quiet").bool()
    let verbose = cmd.option("verbose").bool()
    let nothing = cmd.option("nothing").bool()
    let directory = match cmd.option("directory").string()
    | "" => Path.cwd()
    | let dir': String => Path.clean(dir')
    end
    let repo_cache = "./_repos"  // TODO: move default to user home and add flag
    let corral_base = "./_corral"
    //log.fine("Cmd: " + cmd.string())

    try
      let context =
        recover Context(env, directory, log,
          quiet, nothing,repo_cache, corral_base)? end

      match cmd.fullname()
      | "corral/version" => env.out.print("corral " + Info.version())
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
        Help.general(cs).print_help(env.out)
        env.exitcode(0)
        return
      end
    else
      log.err("Internal error setting up command context.")
      env.exitcode(2)
    end
