use "cli"
use ".."
use "../bundle"

class CmdVersion is CmdType

  new create(cmd: Command) => None

  fun requires_bundle(): Bool => false

  fun apply(ctx: Context, project: Project) =>
    ctx.uout.info("version: " + Version())
