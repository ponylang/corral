use "cli"
use ".."

primitive CmdVersion
  fun apply(ctx: Context, cmd: Command) =>
    ctx.env.out.print("\nCorral version: " + Version())
