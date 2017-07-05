use "cli"
use "logger"

primitive CmdInit
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("init: " + cmd.string())
    try
      let project = ProjectFile.create_project(env, log)
      env.out.print("created: " + project.name())
      project.save()
      env.out.print("Save done.")
    end
