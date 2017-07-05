use "cli"
use "logger"

class CmdRemove
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("remove: " + cmd.string())
    try
      let project = ProjectFile.load_project(env, log)
      //project.remove_bundle(bd)
      project.save()
    end
