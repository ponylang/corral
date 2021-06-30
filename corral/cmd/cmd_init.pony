use "cli"
use "files"
use "logger"
use "../bundle"
use "../vcs"

class CmdInit is CmdType

  new create(cmd: Command) => None

  fun requires_bundle(): Bool => false
  fun requires_no_bundle(): Bool => true

  fun apply(ctx: Context,
    project: Project,
    vcs_builder: VCSBuilder,
    result_receiver: CmdResultReceiver)
  =>
    ctx.uout(Info) and ctx.uout.log("init: in " + project.dir.path)

    // TODO: try to read first to convert/update existing file(s)
    // TODO: might want to fail if files exist.
    match project.create_bundle()
    | let bundle: Bundle =>
      try
        if not ctx.nothing then
          bundle.save()?
          ctx.uout(Info) and ctx.uout.log("init: created: " + bundle.name())
        else
          ctx.uout(Info) and ctx.uout.log("init: would have created: " + bundle.name())
        end
      else
        ctx.uout(Error) and ctx.uout.log("init: could not create: " + bundle.name())
        ctx.env.exitcode(1)
      end
    | let err: String =>
      ctx.uout(Error) and ctx.uout.log(err)
      ctx.env.exitcode(1)
    end
