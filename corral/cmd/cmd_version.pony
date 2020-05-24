use "cli"
use ".."
use "../bundle"
use "../vcs"

class CmdVersion is CmdType

  new create(cmd: Command) => None

  fun requires_bundle(): Bool => false

  fun apply(ctx: Context,
    project: Project,
    vcs_builder: VCSBuilder,
    result_receiver: CmdResultReceiver)
  =>
    ctx.uout.info("version: " + Version())
