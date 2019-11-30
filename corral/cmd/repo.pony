use "files"
use "../bundle"
use "../vcs"

primitive RepoForDep
  fun apply(ctx: Context, project: Project box, dep: Dep box): Repo ? =>

    let auth = ctx.env.root as AmbientAuth

    ctx.log.info("dep is_vcs:" + dep.locator.is_vcs().string() +
      " is_local:" + dep.locator.is_local().string() +
      " locator: " + dep.locator.string())

    let repo =
      // Local-direct (non-vcs) locator points to the workspace directly
      if dep.locator.is_local_direct() then
        let ws_str = Path.join(dep.bundle.dir.path, dep.locator.bundle_path)
        let workspace = FilePath(auth, ws_str)?
        Repo("", FilePath(auth, "")?, workspace)
      else
        let workspace = project.dep_workspace_root(dep.locator)?

        // Local-vcs has no remote component, just local repo and workspace
        if dep.locator.is_local_vcs() then
          Repo("", FilePath(auth, dep.locator.repo_path)?, workspace)

        // Remote-vcs has remote repo, local repo, and workspace
        elseif dep.locator.is_remote_vcs() then
          let local = ctx.repo_cache.join(dep.flat_repo())?
          Repo(dep.repo(), local, workspace)
        else
          error // Should never happen
        end
      end
    ctx.log.info("Repo for dep: " + dep.name() + " is " + repo.string())
    repo
