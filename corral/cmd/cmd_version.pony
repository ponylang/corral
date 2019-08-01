use "cli"
use ".."

primitive CmdVersion
  fun apply(ctx: Context, cmd: Command) =>
    //ctx.log.info("version: " + cmd.string())

    ctx.env.out.print("\nCorral version: " + Version())
