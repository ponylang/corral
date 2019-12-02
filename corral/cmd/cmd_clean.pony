use "cli"
use "files"
use "../bundle"
use "../util"

primitive CmdClean
  fun apply(ctx: Context, cmd: Command) =>
    let clean_repos = cmd.option("repos").bool()
    let clean_all = cmd.option("all").bool()

    ctx.uout.info(
      "clean: repos:" + clean_repos.string() + " all:"
        + clean_all.string())

    if clean_repos or clean_all then
      let repos_dir = ctx.repo_cache
      if not ctx.nothing then
        ctx.uout.info("clean: removing repos under: " + repos_dir.path)
        repos_dir.remove()
      else
        ctx.uout.info("clean: would have removed repos under: " + repos_dir.path)
      end
    end

    if (not clean_repos) or clean_all then
      match BundleFile.load_bundle(ctx.bundle_dir, ctx.log)
      | let bundle: Bundle =>
        try
          let corral_dir = bundle.corral_dirpath()?
          if not ctx.nothing then
            ctx.uout.info("clean: removing corral: " + corral_dir.path)
            corral_dir.remove()
          else
            ctx.uout.info("clean: would have removed corral: " + corral_dir.path)
          end
        end
      | let err: Error =>
        ctx.uout.err(err.message)
        ctx.env.exitcode(1)
      end
    end
