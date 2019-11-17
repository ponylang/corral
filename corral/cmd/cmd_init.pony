use "cli"
use "files"
use "../bundle"
use "../util"

primitive CmdInit
  fun apply(ctx: Context, cmd: Command) =>
    ctx.env.out.print("\ninit: from dir " + ctx.path)

    // TODO: try to read first to convert/update existing file(s)
    match BundleFile.create_bundle(ctx.env, ctx.path, ctx.log)
    | let bundle: Bundle =>
      try
        bundle.save()?
        ctx.log.info("init: created: " + bundle.name())
      else
        ctx.env.out.print("init: could not create " + bundle.name())
        ctx.env.exitcode(1)
      end
    | let err: Error =>
      ctx.env.out.print(err.message)
      ctx.env.exitcode(1)
    end
