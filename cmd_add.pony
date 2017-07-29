use "cli"
use "json"
use "logger"

primitive CmdAddGithub
  fun apply(ctx: Context, cmd: Command) =>
    ctx.env.out.print("add/github: " + cmd.string())

    let bd = DepData(JsonObject)
    //bd.source = "github"
    bd.locator = cmd.arg("repo").string()
    bd.subdir = cmd.option("subdir").string()
    bd.version = cmd.option("tag").string()
    //bd.revision = cmd.option("tag").string()

    ctx.log.log("Adding: " + bd.json().string())
    try
      let bundle = BundleFile.load_bundle(ctx.env, ctx.log)?
      bundle.add_dep(bd)
      bundle.save()?
      //bundle.fetch() // TODO: just fetch this dep
    end

primitive CmdAddGit
  fun apply(ctx: Context, cmd: Command) =>
    ctx.env.out.print("add/git: " + cmd.string())

    let bd = DepData(JsonObject)
    //bd.source = "git"
    bd.locator = cmd.arg("path").string()
    //bd.subdir = cmd.option("subdir").string()
    bd.version = cmd.option("tag").string()
    //bd.revision = cmd.option("tag").string()

    ctx.log.log("Adding: " + bd.json().string())
    try
      let bundle = BundleFile.load_bundle(ctx.env, ctx.log)?
      bundle.add_dep(bd)
      bundle.save()?
      //bundle.fetch() // TODO: just fetch this dep
    end

primitive CmdAddLocal
  fun apply(ctx: Context, cmd: Command) =>
    ctx.env.out.print("add/local: " + cmd.string())

    let bd = DepData(JsonObject)
    //bd.source = "local"
    bd.locator = cmd.arg("path").string()
    //bd.subdir = cmd.option("subdir").string()
    //bd.version = ""
    //bd.revision = cmd.option("tag").string()

    ctx.log.log("Adding: " + bd.json().string())
    try
      let bundle = BundleFile.load_bundle(ctx.env, ctx.log)?
      bundle.add_dep(bd)
      bundle.save()?
      //bundle.fetch() // TODO: just fetch this dep
    end
