use "cli"
use "json"
use "../bundle"
use "../util"

class CmdAdd is CmdType
  let locator: String
  let version: String
  let revision: String

  new create(cmd: Command) =>
    locator = cmd.arg("locator").string()
    version = cmd.option("version").string()
    revision = cmd.option("revision").string()

  fun apply(ctx: Context, project: Project) =>
    ctx.uout.info(
      "add: adding: " + locator + " " + version + " " + revision)

    match project.load_bundle()
    | let bundle: Bundle =>
      try
        let dep = bundle.add_dep(locator, version, revision)
        if not ctx.nothing then
          bundle.save()?
          ctx.uout.info(
            "add: added dep: " + dep.data.json().string() + " " + dep.lock.json().string())
          //bundle.fetch() // TODO: maybe just fetch this one new dep
        else
          ctx.uout.info(
            "add: would have added dep: " + dep.data.json().string() + " " + dep.lock.json().string())
        end
      else
        ctx.uout.warn("add: could not update " + bundle.name())
        ctx.env.exitcode(1)
      end
    | let err: Error =>
      ctx.uout.err(err.message)
      ctx.env.exitcode(1)
    end
