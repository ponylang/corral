use "cli"
use "collections"
use "files"
use "../bundle"
use "../util"
use "../vcs"

class CmdFetch is CmdType

  new create(cmd: Command) => None

  fun apply(ctx: Context, project: Project, vcs_builder: VCSBuilder) =>
    ctx.uout.info("fetch: fetching from " + project.dir.path)

    match project.load_bundle()
    | let base_bundle: Bundle iso =>
      _Fetcher(ctx, project, consume base_bundle, vcs_builder)
    | let err: Error =>
      ctx.uout.err(err.message)
      ctx.env.exitcode(1)
    end

actor _Fetcher
  let ctx: Context
  let project: Project
  let base_bundle: Bundle val
  let fetched: Set[Locator] = fetched.create()

  let _vcs_builder: VCSBuilder

  new create(ctx': Context,
    project': Project,
    base_bundle': Bundle iso,
    vcs_builder: VCSBuilder)
  =>
    ctx = ctx'
    project = project'
    base_bundle = consume base_bundle'
     _vcs_builder = vcs_builder
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
      let vcs = _vcs_builder(dep.vcs())?
      let repo = RepoForDep(ctx, project, dep)?

      let revision = Constraints.best_revision(
        base_bundle.dep_revision(dep.locator.string()),
        dep.revision(),
        dep.version())

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

    let bundle_dir = try
        project.dep_bundle_root(locator)?
      else
        ctx.log.err("Unexpected error making path for: " + locator.string())
        return
      end
    try
      ctx.log.fine("Fetching dep's bundle from: " + bundle_dir.path)
      let dep_bundle: Bundle val = Bundle.load(bundle_dir, ctx.log)?
      fetch_bundle_deps(dep_bundle)
    else
      ctx.uout.warn("No dep bundle for: " + locator.string())
    end
