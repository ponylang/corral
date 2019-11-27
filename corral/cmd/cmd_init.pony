use "cli"
use "files"
use "../bundle"
use "../util"

primitive CmdInit
  fun apply(ctx: Context, cmd: Command) =>
    ctx.uout.info("init: from dir " + ctx.bundle_dir.path)

    // TODO: try to read first to convert/update existing file(s)
    match BundleFile.create_bundle(ctx.bundle_dir, ctx.log)
    | let bundle: Bundle =>
      try
        if not ctx.nothing then
          bundle.save()?
          ctx.uout.info("init: created: " + bundle.name())
        else
          ctx.uout.info("init: would have created: " + bundle.name())
        end
      else
        ctx.uout.err("init: could not create: " + bundle.name())
        ctx.env.exitcode(1)
      end
    | let err: Error =>
      ctx.uout.err(err.message)
      ctx.env.exitcode(1)
    end
