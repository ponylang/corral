use "cli"
use "logger"

primitive CmdList
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("list: " + cmd.string())
    try
      let bundle = BundleFile.load_bundle(env, log)
      for b in bundle.deps.values() do
        env.out.print("  " + b.data.json().string())
      end
    end
