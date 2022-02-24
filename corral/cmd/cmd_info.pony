use "cli"
use "files"
use "../logger"
use "../bundle"
use "../vcs"

class CmdInfo is CmdType

  new create(cmd: Command) => None

  fun apply(ctx: Context,
    project: Project,
    vcs_builder: VCSBuilder,
    result_receiver: CmdResultReceiver)
  =>
    ctx.uout(Info) and ctx.uout.log("info: from " + project.dir.path)

    match project.load_bundle()
    | let bundle: Bundle =>
      ctx.uout(Info) and ctx.uout.log("info: " + bundle.info.json().string())
    | let err: String =>
      ctx.uout(Error) and ctx.uout.log(err)
      ctx.env.exitcode(1)
    end
