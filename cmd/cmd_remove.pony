use "cli"
use "logger"
use "../bundle"

class CmdRemove
  fun apply(ctx: Context, cmd: Command) =>
    ctx.env.out.print("remove: " + cmd.string())
    try
      let bundle = BundleFile.load_bundle(ctx.env, ctx.log)?
      //bundle.remove_dep(bd)
      bundle.save()?
    end
