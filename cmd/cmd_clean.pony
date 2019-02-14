use "cli"
use "files"
use "../bundle"
use "../util"

primitive CmdClean
  fun apply(ctx: Context, cmd: Command) =>
    ctx.log.info("clean: " + cmd.string())

    try
      let bundle = BundleFile.load_bundle(ctx.env, ctx.log)?

      let repos_dir = ctx.repo_cache
      let corral_dir = FilePath(ctx.env.root as AmbientAuth, bundle.corral_path())?

      let clean_repos = cmd.option("repos").bool()
      let clean_all = cmd.option("all").bool()

      if (not clean_repos) or clean_all then
        ctx.log.info("  cleaning corral: " + corral_dir.path)
        corral_dir.remove()
      end
      if clean_repos or clean_all then
        ctx.log.info("  cleaning repos: " + repos_dir.path)
        repos_dir.remove()
      end
    end
