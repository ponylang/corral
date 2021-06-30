use "cli"
use "json"
use "logger"
use "../bundle"
use "../vcs"

class CmdRemove is CmdType
  let locator: String

  new create(cmd: Command) =>
    locator = cmd.arg("locator").string()

  fun apply(ctx: Context,
    project: Project,
    vcs_builder: VCSBuilder,
    result_receiver: CmdResultReceiver)
  =>
    ctx.uout(Info) and ctx.uout.log("remove: removing: " + locator)

    match project.load_bundle()
    | let bundle: Bundle =>
      try
        bundle.remove_dep(locator)?
      else
        ctx.uout(Error) and ctx.uout.log("remove: dep not found in: " + bundle.name())
        ctx.env.exitcode(1)
        return
      end
      try
        if not ctx.nothing then
          bundle.save()?
          ctx.uout(Info) and ctx.uout.log("remove: removed: " + locator)
        else
          ctx.uout(Info) and ctx.uout.log("remove: would have removed: " + locator)
        end
      else
        ctx.uout(Error) and ctx.uout.log("remove: could not update: " + bundle.name())
        ctx.env.exitcode(1)
      end
    | let err: String =>
      ctx.uout(Error) and ctx.uout.log(err)
      ctx.env.exitcode(1)
    end
