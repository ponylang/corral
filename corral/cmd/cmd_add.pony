use "cli"
use "json"
use "../logger"
use "../bundle"
use "../vcs"

class CmdAdd is CmdType
  let locator: String
  let version: String
  let revision: String

  new create(cmd: Command) =>
    locator = cmd.arg("locator").string()
    version = cmd.option("version").string()
    revision = cmd.option("revision").string()

  fun apply(ctx: Context,
    project: Project,
    vcs_builder: VCSBuilder,
    result_receiver: CmdResultReceiver)
  =>
    ctx.uout(Info) and ctx.uout.log(
      "add: adding: " + locator + " " + version + " " + revision)

    match project.load_bundle()
    | let bundle: Bundle =>
      try
        let dep = bundle.add_dep(locator, version, revision)
        if not ctx.nothing then
          bundle.save()?
          ctx.uout(Info) and ctx.uout.log(
            "add: added dep: " + dep.data.json().string() + " " + dep.lock.json().string())
          //bundle.fetch() // TODO: maybe just fetch this one new dep
        else
          ctx.uout(Info) and ctx.uout.log(
            "add: would have added dep: " + dep.data.json().string() + " " + dep.lock.json().string())
        end
      else
        ctx.uout(Warn) and ctx.uout.log("add: could not update " + bundle.name())
        ctx.env.exitcode(1)
      end
    | let err: String =>
      ctx.uout(Error) and ctx.uout.log(err)
      ctx.env.exitcode(1)
    end
