use "cli"
use "collections"
use "files"
use "../bundle"
use "../util"
use "../vcs"

class CmdUpdate is CmdType

  new create(cmd: Command) => None

  fun apply(ctx: Context, project: Project) =>
    ctx.uout.info("update:")
    match project.load_bundle()
    | let bundle: Bundle iso =>
      _Updater(ctx, project, consume bundle)
    | let err: Error =>
      ctx.uout.err(err.message)
      ctx.env.exitcode(1)
    end

actor _Updater
  let ctx: Context
  let project: Project
  let base_bundle: Bundle ref

  let deps_seen: Map[Locator, Dep] ref = deps_seen.create()
  let deps_to_load: Map[Locator, Dep] ref = deps_to_load.create()
  let dep_tags: Map[Locator, Array[String] val] ref = dep_tags.create()

  new create(ctx': Context, project': Project, base_bundle': Bundle iso) =>
    ctx = ctx'
    project = project'
    base_bundle = consume base_bundle'
    ctx.log.info("Updating direct deps of project bundle: " + base_bundle.name())
    load_bundle_deps(base_bundle)

  fun ref load_bundle_deps(bundle: Bundle) =>
    for dep in bundle.deps.values() do
      if not ctx.nothing then
        if not deps_seen.contains(dep.locator) then
          ctx.uout.info("update: will load dep: " + dep.name() + " @ " + dep.version())
          deps_seen(dep.locator) = dep
          deps_to_load(dep.locator) = dep
        else
          ctx.uout.info("update: skipping seen dep: " + dep.name() + " @ " + dep.version())
        end
      else
        ctx.uout.info("update: would have loaded dep: " + dep.name() + " @ " + dep.version())
      end
    end
    load_queued_deps()

  fun ref load_queued_deps() =>
    for dep in deps_to_load.values() do
      try
        load_dep(dep)?
      else
        ctx.uout.err("Error loading dep " + dep.name())
        // It won't get a lock. How should we handle/report the error?
      end
    end
    //try_complete()

  fun load_dep(dep: Dep) ? =>
    let vcs = VCSForType(ctx.env, dep.vcs())?
    let repo = RepoForDep(ctx, project, dep)?

    let self: _Updater tag = this
    let locator: Locator = dep.locator

    ctx.log.info("Loading dep: " + locator.path())

    let checkout_op = vcs.checkout_op("master", {
        (repo: Repo) =>
          self.load_transitive_dep(locator)
      } val)

    let tag_query_op = vcs.tag_query_op({
        (repo: Repo, tags: Array[String] val) =>
          self.collect_dep_tags(locator, tags)
          checkout_op(repo)
      } val)

    let sync_handler = {(repo: Repo) =>
        tag_query_op(repo)
      } val
    let sync_op = vcs.sync_op(sync_handler)
    sync_op(repo)

  be load_transitive_dep(locator: Locator) =>
    ctx.log.info("Fetching transitive dep: " + locator.path())
    try
      let bundle_dir = project.dep_bundle_root(locator)?
      ctx.log.fine("Fetching dep's bundle from: " + bundle_dir.path)
      let dep_bundle: Bundle ref = Bundle.load(bundle_dir, ctx.log)?
      ctx.log.fine("Fetched dep's bundle is: " + dep_bundle.name())
      load_bundle_deps(dep_bundle)
    else
      ctx.uout.err("Error loading/fetching dep bundle: " + locator.flat_name())
      ctx.env.exitcode(1)
    end

  be collect_dep_tags(locator: Locator, tags: Array[String] val) =>
    ctx.log.info("Collected " + tags.size().string() + " tags for dep: " + locator.path())
    try
      // If this remove fails, it just means another path got here first.
      (_, let dep) = deps_to_load.remove(locator)?
      ctx.log.fine("tags for " + dep.locator.string() + ": " + tags.size().string())
      dep_tags(locator) = tags
    end
    try_complete()

  be try_complete() =>
    if deps_to_load.size() > 0 then
      ctx.log.fine("try_complete still have deps to load: " + deps_to_load.size().string())
      //try_complete()  // Still working, try again.
      load_queued_deps()
    else
      ctx.log.fine("try_complete done loading deps")
      if dep_tags.size() > 0 then
        for loc in dep_tags.keys() do
          try
            update_dep(deps_seen(loc)?, dep_tags(loc)?)
          end
        end
        dep_tags.clear()
        try
          base_bundle.save()?
        else
          ctx.uout.err("Error saving project bundle")
        end
        // All done, should quiesce now...
        ctx.log.fine("try_complete all done.")
      end
    end

  fun ref update_dep(dep: Dep, tags: Array[String] val) =>
    try
      // TODO: consider parsing version much earlier, maybe in Bundle.
      // TODO: also consider allowing literal tags and not just constraints
      // expressions.
      // https://github.com/ponylang/corral/issues/26
      let constraints = Constraints.parse(dep.data.version)

      let result = Constraints.solve(constraints, tags, ctx.log)

      // TODO: probably OK to have multiple solutions: choose 'best' with a strategy like 'latest'.
      // https://github.com/ponylang/corral/issues/63
      if result.solution.size() == 1 then
        let rev: String = result.solution(0)?.version.string()
        //dep.lock.revision = consume rev
        //dep.lock_revision(consume rev)
        ctx.log.fine("solution for " + dep.locator.string() + ": " + rev)
        base_bundle.lock_revision(dep.locator.string(), rev)
      else
        ctx.log.fine("no single solution for " + dep.locator.string() + ": " + result.solution.size().string())
      end
    end
