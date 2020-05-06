use "cli"

primitive CLI
  fun parse(
    args: Array[String] box,
    envs: (Array[String] box | None))
    : (Command | (U8, String))
  =>
    try
      match CommandParser(spec()?).parse(args, envs)
      | let c: Command => c
      | let h: CommandHelp => (0, h.help_string())
      | let e: SyntaxError => (1, e.string())
      end
    else
      (2, "Internal error: invalid command spec")
    end

  fun help(): String =>
    try Help.general(spec()?).help_string() else "" end

  fun spec(): CommandSpec ?
  =>
    CommandSpec.parent(
      "corral",
      "",
      [
        OptionSpec.u64(
          "debug",
          "Configure debug output: 0=off, 1=err, 2=warn, 3=info, 4=fine."
          where short'='g',
          default' = 0)
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
        OptionSpec.string(
          "bundle_dir",
          "The directory where the bundle's corral.json and lock.json are located."
          where short' = 'd',
          default' = "<cwd>")
      ],
      [
        CommandSpec.leaf(
          "version",
          "Show the version and exit")?
        CommandSpec.leaf(
          "init",
          "Initializes the corral.json and lock.json files with"
            + " skeletal information."
        )?
        CommandSpec.leaf(
          "info",
          "Prints all or specific information about the bundle from"
            + " corral.json.")?
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
          ],
          [
            ArgSpec.string("locator", "Organization/repository name.")
          ])?
        CommandSpec.leaf(
          "remove",
          "Removes one or more deps from the bundle.",
          Array[OptionSpec](),
          [
            ArgSpec.string("locator", "Organization/repository name.")
          ])?
        CommandSpec.leaf(
          "list",
          "Lists the deps and packages, including corral details.")?
        CommandSpec.leaf(
          "clean",
          "Cleans repo cache and working corral. Default is to clean"
            + " only the working corral.",
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
          ])?
        CommandSpec.leaf(
          "update",
          "Updates one or more or all of the deps in the corral to their"
            + " best revisions.")?
        CommandSpec.leaf(
          "fetch",
          "Fetches one or more or all of the deps into the corral.")?
        CommandSpec.leaf(
          "run",
          "Runs a shell command inside an environment with the corral on"
            + " the PONYPATH.",
          Array[OptionSpec](),
          [
            ArgSpec.string_seq("args", "Arguments to run.")
          ])?
        CommandSpec.leaf(
          "exec",
          "For executing shell commands which require user interaction",
          Array[OptionSpec](),
          [
            ArgSpec.string_seq("args", "Arguments to run.")
          ])?
      ])?
      .> add_help()?
