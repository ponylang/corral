use "cli"
use "collections"
use "files"
use "../bundle"
use "../util"
use "../vcs"

class CmdFetch is CmdType

  new create(cmd: Command) => None

  fun apply(ctx: Context, project: Project) =>
    ctx.uout.info("fetch:")
    match project.load_bundle()
    | let base_bundle: Bundle iso =>
      _Fetcher(ctx, project, consume base_bundle)
    | let err: Error =>
      ctx.uout.err(err.message)
      ctx.env.exitcode(1)
    end

actor _Fetcher
  let ctx: Context
  let project: Project
  let base_bundle: Bundle val
  let fetched: Set[Locator] = fetched.create()

  new create(ctx': Context, project': Project, base_bundle': Bundle iso) =>
    ctx = ctx'
    project = project'
    base_bundle = consume base_bundle'
    ctx.log.info("Fetching direct deps of project bundle: " + base_bundle.name())
    fetch_bundle_deps(base_bundle)

  fun ref fetch_bundle_deps(bundle: Bundle val) =>
    for dep in bundle.deps.values() do
      if not ctx.nothing then
        if not fetched.contains(dep.locator) then
          fetched.set(dep.locator)
          fetch_dep(dep)
          ctx.uout.info("fetch: fetching dep: " + dep.name() + " @ " + dep.version())
        else
          ctx.uout.info("fetch: skipping seen dep: " + dep.name() + " @ " + dep.version())
        end
      else
        ctx.uout.info("fetch: would have fetched dep: " + dep.name() + " @ " + dep.version())
      end
    end

  fun fetch_dep(dep: Dep val) =>
    try
      let vcs = VCSForType(ctx.env, dep.vcs())?
      let repo = RepoForDep(ctx, project, dep)?

      // Determine revision of the dep to fetch
      // - If it's already resolved from a lock, use that.
      // - Else, if the dep is a specific revision, use that.
      // - Else, it is a constraint to solve but update should have done that,
      //   so just use master for now.
      // TODO https://github.com/ponylang/corral/issues/59

      var revision = base_bundle.dep_revision(dep.locator.string())
      if revision == "" then
        revision = dep.revision()
      end
      if Constraints.parse(revision).size() > 0 then
        revision = "master"  // TODO: hack until we can ensure revisions are all locked.
      end

      let self: _Fetcher tag = this
      let checkout_op = vcs.checkout_op(revision,
        {(repo: Repo) => self.fetch_transitive_dep(dep.locator)})
      let fetch_op = vcs.sync_op(checkout_op)

      fetch_op(repo)

    else
      ctx.uout.err("Error fetching dep: " + dep.name() + " @ " + dep.version())
    end

  be fetch_transitive_dep(locator: Locator) =>
    ctx.log.info("Fetching transitive dep: " + locator.path())
    try
      let bundle_dir = project.dep_bundle_root(locator)?
      ctx.log.fine("Fetching dep's bundle from: " + bundle_dir.path)
      let dep_bundle: Bundle val = Bundle.load(bundle_dir, ctx.log)?
      ctx.log.fine("Fetched dep's bundle is: " + dep_bundle.name())
      fetch_bundle_deps(dep_bundle)
    else
      ctx.uout.err("Error loading/fetching dep bundle: " + locator.flat_name())
      ctx.env.exitcode(1)
    end
