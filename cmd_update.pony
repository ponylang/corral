use "cli"
use "logger"

primitive CmdUpdate
  fun apply(ctx: Context, cmd: Command) =>
    ctx.env.out.print("update: " + cmd.string())

"""
VCS Operations:
  - clone if new, pull (all branches) otherwise.
  - retrieve versions
  - (select best & update lock)
"""
