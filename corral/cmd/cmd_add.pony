use "cli"
use "json"
use "../bundle"
use "../util"

primitive CmdAdd
  fun apply(ctx: Context, cmd: Command) =>
    //ctx.log.info("add: " + cmd.string())

    let dd = DepData(JsonObject)
    dd.locator = cmd.arg("locator").string()
    dd.version = cmd.option("version").string()

    let ld = LockData(JsonObject)
    ld.locator = dd.locator
    ld.revision = cmd.option("revision").string()

    ctx.env.out.print(
      "\nadd: adding: " + dd.locator.string() + " "
        + dd.version.string() + " " + ld.revision.string())

    match BundleFile.load_bundle(ctx.bundle_dir, ctx.log)
    | let bundle: Bundle =>
      try
        bundle.add_dep(dd, ld)
        bundle.save()?
        ctx.env.out.print(
          "  added: " + dd.json().string() + " " + ld.json().string())
        //bundle.fetch() // TODO: maybe just fetch this one new dep
        else
          ctx.env.out.print("  could not update " + bundle.name())
          ctx.env.exitcode(1)
        end
    | let err: Error =>
      ctx.env.out.print(err.message)
      ctx.env.exitcode(1)
    end
