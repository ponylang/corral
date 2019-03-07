use "cli"
use "files"
use "../bundle"
use "../util"


primitive CmdList
  fun apply(ctx: Context, cmd: Command) =>
    //ctx.log.info("list: " + cmd.string())

    ctx.env.out.print("\nlist: from dir " + Path.cwd())
    match BundleFile.load_bundle(ctx.env, ctx.log)
    | let bundle: Bundle =>

      ctx.env.out.print("listing " + Files.bundle_filename() + " in " + bundle.name())
      for d in bundle.deps.values() do
        //ctx.env.out.print("  " + d.data.json().string())
        ctx.env.out.print("  dep: " + d.name())
        ctx.env.out.print("    vcs: " + d.vcs())
        ctx.env.out.print("    ver: " + d.data.version)
        ctx.env.out.print("    rev: " + d.lock.revision)
      end

      ctx.env.out.print("")
      for br in bundle.bundle_roots().values() do
        ctx.env.out.print("  dep_root: " + br)
      end

    | let err: Error =>
      ctx.env.out.print("list: " + err.message)
      ctx.env.exitcode(1)
    end
