use "cli"
use "files"
use "../logger"
use "../bundle"
use "../vcs"

class CmdList is CmdType

  new create(cmd: Command) => None

  fun apply(ctx: Context,
    project: Project,
    vcs_builder: VCSBuilder,
    result_receiver: CmdResultReceiver)
  =>
    ctx.uout(Info) and ctx.uout.log("list: from " + project.dir.path)

    match project.load_bundle()
    | let bundle: Bundle =>
      let iter = project.transitive_deps(bundle).values()
      for d in iter do
        ctx.uout(Info) and ctx.uout.log("  dep: " + d.name())
        ctx.uout(Info) and ctx.uout.log("    vcs: " + d.vcs())
        ctx.uout(Info) and ctx.uout.log("    ver: " + d.data.version)
        ctx.uout(Info) and ctx.uout.log("    rev: " + d.lock.revision)
        try
          ctx.uout(Info) and ctx.uout.log("  dep_root: " + project.dep_bundle_root(d.locator)?.path)
        end
        if iter.has_next() then
          ctx.uout(Info) and ctx.uout.log("")
        end
      end

    | let err: String =>
      ctx.uout(Error) and ctx.uout.log("list: " + err)
      ctx.env.exitcode(1)
    end
