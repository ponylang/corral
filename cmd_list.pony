use "cli"
use "logger"

primitive CmdList
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("list: " + cmd.string())
    try
      let project = ProjectFile.load_project(env, log)
      for bd in project.bundles() do
        env.out.print("  " + project.data.info.json().string())
      end
    end
