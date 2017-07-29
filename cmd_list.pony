use "cli"
use "logger"

primitive CmdList
  fun apply(ctx: Context, cmd: Command) =>
    ctx.env.out.print("list: " + cmd.string())
    try
      let bundle = BundleFile.load_bundle(ctx.env, ctx.log)?
      for b in bundle.deps.values() do
        ctx.env.out.print("  " + b.data.json().string())
      end
    end
