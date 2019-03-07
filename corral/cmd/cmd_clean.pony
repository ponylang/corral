use "cli"
use "files"
use "../bundle"
use "../util"


primitive CmdClean
  fun apply(ctx: Context, cmd: Command) =>
    //ctx.log.info("clean: " + cmd.string())

    match BundleFile.load_bundle(ctx.env, ctx.log)
    | let bundle: Bundle =>
      try
        let repos_dir = ctx.repo_cache
        let corral_dir = bundle.corral_dirpath()?

        let clean_repos = cmd.option("repos").bool()
        let clean_all = cmd.option("all").bool()

        ctx.env.out.print("\nclean: repos:" + clean_repos.string() + " all:" + clean_all.string())

        if (not clean_repos) or clean_all then
          ctx.env.out.print("  cleaning corral: " + corral_dir.path)
          corral_dir.remove()
        end
        if clean_repos or clean_all then
          ctx.env.out.print("  cleaning repos: " + repos_dir.path)
          repos_dir.remove()
        end
      end
    | let err: Error =>
      ctx.env.out.print(err.message)
      ctx.env.exitcode(1)
    end
