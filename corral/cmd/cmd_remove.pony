use "cli"
use "../bundle"
use "../util"


primitive CmdRemove
  fun apply(ctx: Context, cmd: Command) =>
    //ctx.log.info("remove: " + cmd.string())

    match BundleFile.load_bundle(ctx.env, ctx.log)
    | let bundle: Bundle =>
      try
        // TODO: lookup dep
        //bundle.remove_dep(dep)
        bundle.save()?
        //ctx.env.out.print("remove: removed " + cmd.string())
      else
        ctx.env.out.print("remove: could not update " + bundle.name())
        ctx.env.exitcode(1)
      end
    | let err: Error =>
      ctx.env.out.print("remove: " + err.message)
      ctx.env.exitcode(1)
    end
