use "cli"
use "logger"

primitive CmdFetch
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("fetch: " + cmd.string())
    try
      let bundle = BundleFile.load_bundle(env, log)
      bundle.fetch()
    end
