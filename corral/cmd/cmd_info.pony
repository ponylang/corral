use "cli"
use "files"
use "../bundle"
use "../util"
use "../vcs"

class CmdInfo is CmdType

  new create(cmd: Command) => None

  fun apply(ctx: Context,
    project: Project,
    vcs_builder: VCSBuilder,
    result_receiver: CmdResultReceiver)
  =>
    ctx.uout.info("info: from " + project.dir.path)

    match project.load_bundle()
    | let bundle: Bundle =>
      ctx.uout.info("info: " + bundle.info.json().string())
    | let err: Error =>
      ctx.uout.err(err.message)
      ctx.env.exitcode(1)
    end
