use "cli"
use "files"
use "../bundle"
use "../util"

primitive CmdList
  fun apply(ctx: Context, cmd: Command) =>
    ctx.uout.info("list: from dir " + ctx.bundle_dir.path)

    match BundleFile.load_bundle(ctx.bundle_dir, ctx.log)
    | let bundle: Bundle =>

      ctx.uout.info(
        "list: listing " + Files.bundle_filename() + " in " + bundle.name())
      for d in bundle.deps.values() do
        ctx.uout.info("  dep: " + d.name())
        ctx.uout.info("    vcs: " + d.vcs())
        ctx.uout.info("    ver: " + d.data.version)
        ctx.uout.info("    rev: " + d.lock.revision)
      end

      ctx.uout.info("")
      for br in bundle.bundle_roots().values() do
        ctx.uout.info("  dep_root: " + br)
      end

    | let err: Error =>
      ctx.uout.err("list: " + err.message)
      ctx.env.exitcode(1)
    end
