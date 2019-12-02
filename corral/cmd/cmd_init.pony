use "cli"
use "files"
use "../bundle"
use "../util"

class CmdInit is CmdType

  new create(cmd: Command) => None

  fun requires_bundle(): Bool => false
  fun requires_no_bundle(): Bool => true

  fun apply(ctx: Context, project: Project) =>
    ctx.uout.info("init: from dir " + project.dir.path)

    // TODO: try to read first to convert/update existing file(s)
    // TODO: might want to fail if files exist.
    match project.create_bundle()
    | let bundle: Bundle =>
      try
        if not ctx.nothing then
          bundle.save()?
          ctx.uout.info("init: created: " + bundle.name())
        else
          ctx.uout.info("init: would have created: " + bundle.name())
        end
      else
        ctx.uout.err("init: could not create: " + bundle.name())
        ctx.env.exitcode(1)
      end
    | let err: Error =>
      ctx.uout.err(err.message)
      ctx.env.exitcode(1)
    end
