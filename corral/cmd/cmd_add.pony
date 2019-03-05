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

    match BundleFile.load_bundle(ctx.env, ctx.log)
    | let bundle: Bundle =>
      try
        bundle.add_dep(dd, ld)
        bundle.save()?
        ctx.env.out.print("add: added: " + dd.json().string() + " " + ld.json().string())
        //bundle.fetch() // TODO: maybe just fetch this one new dep
        else
          ctx.env.out.print("add: could not update " + bundle.name())
          ctx.env.exitcode(1)
        end
    | let err: Error =>
      ctx.env.out.print("add: " + err.message)
      ctx.env.exitcode(1)
    end
