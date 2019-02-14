use "cli"
use "../bundle"
use "../util"

primitive CmdList
  fun apply(ctx: Context, cmd: Command) =>
    ctx.log.info("list: " + cmd.string())
    try
      let bundle = BundleFile.load_bundle(ctx.env, ctx.log)?
      for b in bundle.deps.values() do
        //ctx.env.out.print("  " + b.data.json().string())
        ctx.env.out.print("  " + b.name())
        ctx.env.out.print("    vcs: " + b.vcs())
        ctx.env.out.print("    ver: " + b.data.version)
        ctx.env.out.print("    rev: " + b.lock.revision)
      end
    end
