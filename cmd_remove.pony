use "cli"
use "logger"

class CmdRemove
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("remove: " + cmd.string())
    try
      let bundle = BundleFile.load_bundle(env, log)
      //bundle.remove_dep(bd)
      bundle.save()
    end
