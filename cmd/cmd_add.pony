use "cli"
use "json"
use "../bundle"
use "../util"

primitive CmdAdd
  fun apply(ctx: Context, cmd: Command) =>
    ctx.log.info("add: " + cmd.string())

    let dd = DepData(JsonObject)
    dd.locator = cmd.arg("locator").string()
    dd.version = cmd.option("version").string()

    let ld = LockData(JsonObject)
    ld.locator = dd.locator
    ld.revision = cmd.option("revision").string()

    ctx.log.info("Adding: " + dd.json().string() + " " + ld.json().string())
    try
      let bundle = BundleFile.load_bundle(ctx.env, ctx.log)?
      bundle.add_dep(dd, ld)
      bundle.save()?
      //bundle.fetch() // TODO: just fetch this one new dep
    end
