use "cli"
use "logger"

primitive CmdInit
  fun apply(ctx: Context, cmd: Command) =>
    ctx.log(Info) and ctx.log.log("init: " + cmd.string())
    try
      let bundle = BundleFile.create_bundle(ctx.env, ctx.log)?
      ctx.log(Info) and ctx.log.log("created: " + bundle.name())
      bundle.save()?
      ctx.log(Info) and ctx.log.log("Save done.")
    end
