use "cli"
use "files"
use "../bundle"
use "../util"

class CmdInfo is CmdType

  new create(cmd: Command) => None

  fun apply(ctx: Context, project: Project) =>
    ctx.uout.info("info: from dir " + project.dir.path)

    match project.load_bundle()
    | let bundle: Bundle =>
      ctx.uout.info(
        "info: from " + Files.bundle_filename()
          + " in " + bundle.name())
      ctx.uout.info("info: " + bundle.info.json().string())
    | let err: Error =>
      ctx.uout.err(err.message)
      ctx.env.exitcode(1)
    end
