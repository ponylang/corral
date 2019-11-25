use "cli"
use "files"
use "../bundle"
use "../util"
use "../vcs"

primitive CmdFetch
  fun apply(ctx: Context, cmd: Command) =>
    //ctx.log.info("fetch: " + cmd.string())
    ctx.env.out.print("\nfetch:")
    match BundleFile.load_bundle(ctx.bundle_dir, ctx.log)
    | let bundle: Bundle val =>
      _Fetcher(ctx, bundle).fetch_bundle_deps(bundle)
    | let err: Error =>
      ctx.env.out.print(err.message)
      ctx.env.exitcode(1)
    end

actor _Fetcher
  let ctx: Context
  let base_bundle: Bundle val

  new create(ctx': Context, base_bundle': Bundle val) =>
    ctx = ctx'
    base_bundle = base_bundle'

  be fetch_bundle_deps(bundle: Bundle val) =>
    ctx.log.info("Fetching direct deps of bundle: " + bundle.name())
    for dep in bundle.deps.values() do
      //try
        ctx.log.info("Fetching dep: " + dep.name() + " @ " + dep.version())
          //dep.data.locator)
        fetch_dep(dep)
      //else
      //  ctx.log.err("Error fetching dep: " + dep.name() + " @ " + dep.version())
      //    //dep.data.locator)
      //end
    end
    //fetch_transitive_deps(bundle)

  be fetch_transitive_dep(dep: Dep val) =>
    ctx.log.info("Fetching transitive dep: " + dep.name())
    // TODO: prevent infinite recursion by keeping & checking a deps Set
    try
      let bundle_dir = base_bundle.dep_bundle_root(dep)?
      ctx.log.fine("Fetching dep's bundle into: " + bundle_dir.path)
      let dep_bundle: Bundle val = Bundle.load(bundle_dir, ctx.log)?
      ctx.log.fine("Fetched dep's bundle is: " + dep_bundle.name())
      fetch_bundle_deps(dep_bundle)
    else
      ctx.log.err("Error loading/fetching dep bundle: " + dep.flat_name())
      ctx.env.exitcode(1)
    end

  fun fetch_dep(dep: Dep val) =>
    try
      let local = ctx.repo_cache.join(dep.flat_repo())?
      let workspace = base_bundle.dep_workspace_root(dep)?
      let repo = Repo(dep.repo(), local, workspace)
      let vcs = VCSForType(ctx.env, dep.vcs())?

      // TODO: deal with versions
      // - If its already resolved from a lock, done.
      // - Else, it is a constraint to solve but we don't have the tags here yet.
      var version = dep.version()
      let constraints = Constraints.parse(version)
      if constraints.size() > 0 then
        version = "master"  // TODO: hack until we can pass constraints down through fetch
      end

      let fetch_op = vcs.fetch_op(version, _DepFetchFollower(this, dep))?
      fetch_op(repo)
    else
      ctx.log.err("Error fetching dep: " + dep.name() + " @ " + dep.version())
    end

class val _DepFetchFollower is RepoOperation
  let fetcher: _Fetcher
  let dep: Dep val

  new val create(fetcher': _Fetcher, dep': Dep val) =>
    fetcher = fetcher'
    dep = dep'

  fun val apply(repo: Repo) =>
    fetcher.fetch_transitive_dep(dep)
