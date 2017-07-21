use "cli"
use "logger"

primitive CmdInfo
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("info: " + cmd.string())
    try
      let project = ProjectFile.load_project(env, log)
      env.out.print("project: " + project.name() +
        " info: " + project.info.json().string())
    end
