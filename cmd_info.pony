use "cli"
use "logger"

primitive CmdInfo
  fun apply(ctx: Context, cmd: Command) =>
    ctx.log(Info) and ctx.log.log("info: " + cmd.string())
    try
      let bundle = BundleFile.load_bundle(ctx.env, ctx.log)?
      ctx.log(Info) and ctx.log.log("bundle: " + bundle.name() +
        " info: " + bundle.info.json().string())
    end
