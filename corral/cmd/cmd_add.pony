use "cli"
use "json"
use "../bundle"
use "../util"

primitive CmdAdd
  fun apply(ctx: Context, cmd: Command) =>
    let dd = DepData(JsonObject)
    dd.locator = cmd.arg("locator").string()
    dd.version = cmd.option("version").string()

    let ld = LockData(JsonObject)
    ld.locator = dd.locator
    ld.revision = cmd.option("revision").string()

    ctx.uout.info(
      "add: adding: " + dd.locator.string() + " "
        + dd.version.string() + " " + ld.revision.string())

    match BundleFile.load_bundle(ctx.bundle_dir, ctx.log)
    | let bundle: Bundle =>
      try
        bundle.add_dep(dd, ld)
        if not ctx.nothing then
          bundle.save()?
          ctx.uout.info(
            "add: added dep: " + dd.json().string() + " " + ld.json().string())
          //bundle.fetch() // TODO: maybe just fetch this one new dep
        else
          ctx.uout.info(
            "add: would have added dep: " + dd.json().string() + " " + ld.json().string())
        end
      else
        ctx.uout.warn("add: could not update " + bundle.name())
        ctx.env.exitcode(1)
      end
    | let err: Error =>
      ctx.uout.err(err.message)
      ctx.env.exitcode(1)
    end
