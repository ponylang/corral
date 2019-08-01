use "cli"
use "files"
use "../bundle"
use "../util"
use "../vcs"

class CmdFetch
  let ctx: Context

  new create(ctx': Context, cmd: Command) =>
    ctx = ctx'
    //ctx.log.info("fetch: " + cmd.string())

    ctx.env.out.print("\nfetch:")
    match BundleFile.load_bundle(ctx.env, ctx.log)
    | let bundle: Bundle =>
      fetch_bundle_deps(bundle, bundle)
    | let err: Error =>
      ctx.env.out.print(err.message)
      ctx.env.exitcode(1)
    end

  fun fetch_bundle_deps(base_bundle: Bundle box, bundle: Bundle) =>
    ctx.log.info("Fetching bundle: " + bundle.name())
    for dep in bundle.deps.values() do
      try
        ctx.log.info("Fetching dep: " + dep.name() + " @ " + dep.version())
          //dep.data.locator)
        fetch_dep(base_bundle, dep)?
      else
        ctx.log.err("Error fetching dep: " + dep.name() + " @ " + dep.version())
          //dep.data.locator)
      end
    end
    for dep in bundle.deps.values() do
      // TODO: prevent infinite recursion by keeping & checking a deps Set
      try
        let bundle_dir = base_bundle.dep_bundle_root(dep)?
        ctx.log.fine("Fetching dep's bundle in: " + bundle_dir.path)
        let dep_bundle = Bundle.load(ctx.env, bundle_dir, ctx.log)?
        ctx.log.fine("Fetched dep's bundle is: " + dep_bundle.name())
        fetch_bundle_deps(base_bundle, dep_bundle)
      else
        ctx.log.err("Error loading/fetching dep's bundle: " + dep.flat_name())
      end
    end

  // TODO:
  // We want the fetch workspace to always be directly under this project's
  // corral, but we still locate the fetched bundles from down in corral.

  fun fetch_dep(base_bundle: Bundle box, dep: Dep) ? =>
    let local = ctx.repo_cache.join(dep.flat_repo())?
    let workspace = base_bundle.dep_workspace_root(dep)?
    let repo = Repo(dep.repo(), local, workspace)
    let vcs = VcsForType(ctx.env, dep.vcs())?

    // TODO: careful about version here
    let fetch_op = vcs.fetch_op(dep.version())?

    // TODO:
    // Need to include callback here to continue recursion once fetch is done.
    fetch_op(repo)
