use "cli"
use "logger"

primitive CmdFetch
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("fetch: " + cmd.string())
    try
      let project = ProjectFile.load_project(env, log)
      project.fetch()
    end
