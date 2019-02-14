use "cli"
use "files"
use "../bundle"
use "../util"
use "../vcs"

class CmdFetch
  let ctx: Context
  let cmd: Command

  new create(ctx': Context, cmd': Command) =>
    ctx = ctx'
    cmd = cmd'

    ctx.log.info("fetch: " + cmd.string())
    try
      let bundle = BundleFile.load_bundle(ctx.env, ctx.log)?
      fetch_bundle_deps(bundle)
    else
      ctx.log.err("Error loading bundle")
      //error
    end

  fun fetch_bundle_deps(bundle: Bundle) =>
    for dep in bundle.deps.values() do
      try
        ctx.log.info("fetchingdep: " + dep.name() + " @ " + dep.version()) //dep.data.locator)
        fetch_dep(dep)?
      else
        ctx.log.err("Error fetching dep: " + dep.name() + " @ " + dep.version()) //dep.data.locator)
      end
    end
    /**/
    for dep in bundle.deps.values() do
      // TODO: prevent infinite recursion by keeping & checking a deps Set
      try
        let bundle_dir = FilePath(ctx.env.root as AmbientAuth, dep.bundle_root())?
        fetch_bundle_deps(Bundle.load(ctx.env, bundle_dir, ctx.log)?)
      else
        ctx.log.err("Error loading/fetching dep's bundle: " + dep.repo_root())
      end
    end /**/

  // TODO: we  want the fetch workspace to always be directlyunder this project's
  // corral, but we still locate the fetched bundles from down in corral.

  fun fetch_dep(dep: Dep) ? =>
    let local = ctx.repo_cache.join(dep.flat_repo())?
    let workspace = FilePath(ctx.env.root as AmbientAuth, dep.repo_root())?
    let repo = Repo(dep.repo(), local, workspace)
    let vcs = VcsForType(ctx.env, dep.vcs())?
    let fetch_op = vcs.fetch_op(dep.version())?// TODO: careful about version here
    fetch_op(repo)
