use "cli"
use "json"
use "../bundle"
use "../util"

class CmdRemove is CmdType
  let locator: String

  new create(cmd: Command) =>
    locator = cmd.arg("locator").string()

  fun apply(ctx: Context, project: Project) =>
    ctx.uout.info("remove: removing: " + locator)

    match project.load_bundle()
    | let bundle: Bundle =>
      try
        bundle.remove_dep(locator)?
      else
        ctx.uout.err("remove: dep not found in: " + bundle.name())
        ctx.env.exitcode(1)
        return
      end
      try
        if not ctx.nothing then
          bundle.save()?
          ctx.uout.info("remove: removed: " + locator)
        else
          ctx.uout.info("remove: would have removed: " + locator)
        end
      else
        ctx.uout.err("remove: could not update: " + bundle.name())
        ctx.env.exitcode(1)
      end
    | let err: Error =>
      ctx.uout.err(err.message)
      ctx.env.exitcode(1)
    end
