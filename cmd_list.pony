use "cli"
use "logger"

primitive CmdList
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("list: " + cmd.string())
    try
      let project = ProjectFile.load_project(env, log)
      for b in project.bundles.values() do
        env.out.print("  " + b.data.json().string())
      end
    end
