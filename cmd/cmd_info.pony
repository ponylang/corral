use "cli"
use "../bundle"
use "../util"

primitive CmdInfo
  fun apply(ctx: Context, cmd: Command) =>
    ctx.log.info("info: " + cmd.string())
    try
      let bundle = BundleFile.load_bundle(ctx.env, ctx.log)?
      ctx.env.out.print("bundle: " + bundle.name())
      ctx.env.out.print("info: " + bundle.info.json().string())
    end
