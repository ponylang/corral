use "cli"
use "logger"

primitive CmdUpdate
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("update: " + cmd.string())
