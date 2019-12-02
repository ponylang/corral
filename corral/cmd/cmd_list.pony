use "cli"
use "files"
use "../bundle"
use "../util"

class CmdList is CmdType

  new create(cmd: Command) => None

  fun apply(ctx: Context, project: Project) =>
    ctx.uout.info("list: from dir " + project.dir.path)

    match project.load_bundle()
    | let bundle: Bundle =>
      ctx.uout.info(
        "list: listing " + Files.bundle_filename() + " in " + bundle.name())

      let iter = project.transitive_deps(bundle).values()
      for d in iter do
        ctx.uout.info("  dep: " + d.name())
        ctx.uout.info("    vcs: " + d.vcs())
        ctx.uout.info("    ver: " + d.data.version)
        ctx.uout.info("    rev: " + d.lock.revision)
        try
          ctx.uout.info("  dep_root: " + project.dep_bundle_root(d.locator)?.path)
        end
        if iter.has_next() then
          ctx.uout.info("")
        end
      end

    | let err: Error =>
      ctx.uout.err("list: " + err.message)
      ctx.env.exitcode(1)
    end
