use "cli"
use "../bundle"
use "../util"

primitive CmdInit
  fun apply(ctx: Context, cmd: Command) =>
    ctx.log.info("init: " + cmd.string())
    try
      // TODO: try to read first to convert/update existing file(s)
      let bundle = BundleFile.create_bundle(ctx.env, ctx.log)?
      ctx.log.info("created: " + bundle.name())
      bundle.save()?
      ctx.log.info("Save done.")
    end
