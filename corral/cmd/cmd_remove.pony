use "cli"
use "json"
use "../bundle"
use "../util"

primitive CmdRemove
  fun apply(ctx: Context, cmd: Command) =>
    let locator = cmd.arg("locator").string()
    ctx.uout.info("remove: removing: " + locator)

    match BundleFile.load_bundle(ctx.bundle_dir, ctx.log)
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
