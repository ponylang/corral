use "cli"
use "logger"
use "../bundle"

primitive CmdInit
  fun apply(ctx: Context, cmd: Command) =>
    ctx.log(Info) and ctx.log.log("init: " + cmd.string())
    try
      // TODO: try to read first to convert/update existing file(s)
      let bundle = BundleFile.create_bundle(ctx.env, ctx.log)?
      ctx.log(Info) and ctx.log.log("created: " + bundle.name())
      bundle.save()?
      ctx.log(Info) and ctx.log.log("Save done.")
    end
