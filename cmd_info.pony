use "cli"
use "logger"

primitive CmdInfo
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("info: " + cmd.string())
    try
      let bundle = BundleFile.load_bundle(env, log)
      env.out.print("bundle: " + bundle.name() +
        " info: " + bundle.info.json().string())
    end
