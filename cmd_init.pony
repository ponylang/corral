use "cli"
use "logger"

primitive CmdInit
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("init: " + cmd.string())
    try
      let bundle = BundleFile.create_bundle(env, log)
      env.out.print("created: " + bundle.name())
      bundle.save()
      env.out.print("Save done.")
    end
