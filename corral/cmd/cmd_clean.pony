use "cli"
use "files"
use "../bundle"
use "../util"

class CmdClean is CmdType
  let clean_repos: Bool
  let clean_corral: Bool

  new create(cmd: Command) =>
    let opt_repos = cmd.option("repos").bool()
    let opt_all = cmd.option("all").bool()
    clean_repos = opt_repos or opt_all
    clean_corral = (not opt_repos) or opt_all

  fun requires_bundle(): Bool =>
    // TODO: once repo_cache is not under project.dir
    // clean_corral
    true

  fun apply(ctx: Context, project: Project) =>
    ctx.uout.info(
      "clean: corral:" + clean_corral.string() +
      " repos:" + clean_repos.string())

    if clean_repos then
      let repos_dir = ctx.repo_cache
      if not ctx.nothing then
        ctx.uout.info("clean: removing repos under: " + repos_dir.path)
        repos_dir.remove()
      else
        ctx.uout.info("clean: would have removed repos under: " + repos_dir.path)
      end
    end

    if clean_corral then
      match project.load_bundle()
      | let bundle: Bundle =>
        try
          let corral_dir = project.corral_dirpath()?
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
