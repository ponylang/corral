use "cli"
use "collections"
use "files"
use "logger"
use "../bundle"
use "../util"
use "../vcs"

class CmdUpdate is CmdType
  new create(cmd: Command) =>
    None

  fun apply(ctx: Context,
    project: Project,
    vcs_builder: VCSBuilder,
    results_receiver: CmdResultReceiver)
  =>
    ctx.uout(Info) and ctx.uout.log("update: updating from " + project.dir.path)
    match project.load_bundle()
    | let bundle: Bundle iso =>
      _Updater(ctx, project, consume bundle, vcs_builder, results_receiver)
    | let err: String =>
      ctx.uout(Error) and ctx.uout.log(err)
      ctx.env.exitcode(1)
    end

actor _Updater is RepoOperationResultReceiver
  let ctx: Context
  let project: Project
  let base_bundle: Bundle ref

  let deps_seen: Map[Locator, Dep] ref = deps_seen.create()
  let deps_to_load: Map[Locator, Dep] ref = deps_to_load.create()
  let deps_loading: Map[Locator, Dep] ref = deps_loading.create()
  let dep_tags: Map[Locator, Array[String] val] ref = dep_tags.create()
  let co_revisions: Map[Locator, String] ref = co_revisions.create()
  let _vcs_builder: VCSBuilder
  let _results_receiver: CmdResultReceiver

  new create(ctx': Context,
    project': Project,
    base_bundle': Bundle iso,
    vcs_builder: VCSBuilder,
    results_receiver: CmdResultReceiver)
  =>
    ctx = ctx'
    project = project'
    base_bundle = consume base_bundle'
    _vcs_builder = vcs_builder
    _results_receiver = results_receiver
    ctx.log(Info) and ctx.log.log("Updating direct deps of project bundle: " + base_bundle.name())
    load_bundle_deps(base_bundle)

  fun ref load_bundle_deps(bundle: Bundle) =>
    for dep in bundle.deps.values() do
      if not ctx.nothing then
        if not deps_seen.contains(dep.locator) then
          ctx.uout(Info) and ctx.uout.log("update: will load dep: " + dep.name() + " @ " + dep.version())
          deps_seen(dep.locator) = dep
          deps_to_load(dep.locator) = dep
        else
          ctx.uout(Info) and ctx.uout.log("update: skipping seen dep: " + dep.name() + " @ " + dep.version())
        end
      else
        ctx.uout(Info) and ctx.uout.log("update: would have loaded dep: " + dep.name() + " @ " + dep.version())
      end
    end
    load_queued_deps()

  fun ref load_queued_deps() =>
    for dep in deps_to_load.values() do
      if not deps_loading.contains(dep.locator) then
        try
          load_dep(dep)?
        else
          ctx.uout(Error) and ctx.uout.log("Error loading dep " + dep.name())
          // It won't get a lock. How should we handle/report the error?
        end
      end
    end
    if deps_to_load.size() == 0 then
      _results_receiver.cmd_completed()
    end

  be reportError(repo: Repo, actionResult: ActionResult) =>
    ctx.env.err.print("Error loading dep: " + repo.string())
    actionResult.print_to(ctx.env.err)
    ctx.env.exitcode(actionResult.exit_code())

  fun ref load_dep(dep: Dep) ? =>
    let vcs = _vcs_builder(dep.vcs())?
    let repo = RepoForDep(ctx, project, dep)?

    let self: _Updater tag = this
    let locator: Locator = dep.locator

    ctx.log(Info) and ctx.log.log("Loading dep: " + locator.path())

    let revision = Constraints.best_revision(
      base_bundle.dep_revision(dep.locator.string()),
      dep.revision(),
      dep.version())

    co_revisions(locator) = revision

    let checkout_op = vcs.checkout_op(revision, this, {
        (repo: Repo) =>
          self.load_transitive_dep(locator)
          PostFetchScript(ctx, repo)
      } val)

    let tag_query_op = vcs.tag_query_op(this, {
        (repo: Repo, tags: Array[String] val) =>
          self.collect_dep_tags(locator, tags)
          checkout_op(repo)
      } val)

    let sync_handler = {(repo: Repo) =>
        tag_query_op(repo)
      } val
    let sync_op = vcs.sync_op(this, sync_handler)
    sync_op(repo)

    deps_loading(locator) = dep

  be load_transitive_dep(locator: Locator) =>
    ctx.log(Info) and ctx.log.log("Loading transitive dep: " + locator.path())
    try
      let bundle_dir = project.dep_bundle_root(locator)?
      ctx.log(Fine) and ctx.log.log("Loading dep's bundle from: " + bundle_dir.path)
      let dep_bundle: Bundle ref = Bundle.load(bundle_dir, ctx.log)?
      ctx.log(Fine) and ctx.log.log("Loading dep's bundle is: " + dep_bundle.name())
      load_bundle_deps(dep_bundle)
    else
      ctx.uout(Error) and ctx.uout.log("Error loading dep bundle: " + locator.flat_name())
      ctx.env.exitcode(1)
    end

  be collect_dep_tags(locator: Locator, tags: Array[String] val) =>
    ctx.log(Info) and ctx.log.log("Collected " + tags.size().string() + " tags for dep: " + locator.path())
    try
      // If this remove fails, it just means another path got here first.
      (_, let dep) = deps_to_load.remove(locator)?
      deps_loading.remove(locator)?
      ctx.log(Fine) and ctx.log.log("tags for " + dep.locator.string() + ": " + tags.size().string())
      dep_tags(locator) = tags
    end
    try_complete()

  be try_complete() =>
    if deps_to_load.size() > 0 then
      ctx.log(Fine) and ctx.log.log("try_complete still have deps to load: " + deps_to_load.size().string())
      load_queued_deps()
    else
      ctx.log(Fine) and ctx.log.log("try_complete done loading deps")
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
          ctx.uout(Error) and ctx.uout.log("Error saving project bundle")
        end
        _results_receiver.cmd_completed()
        // All done, should quiesce now...
        ctx.log(Fine) and ctx.log.log("try_complete all done.")
      end
    end

  fun ref update_dep(dep: Dep, tags: Array[String] val) =>
    // TODO: consider parsing version much earlier, maybe in Bundle.
    // https://github.com/ponylang/corral/issues/26
    let revision =
      match Constraints.resolve_version(dep.data.version, tags, ctx.log)
      | "" => Constraints.best_revision(
        base_bundle.dep_revision(dep.locator.string()),
        dep.revision(),
        dep.version())
      | let rev: String => rev
      end

    base_bundle.lock_revision(dep.locator.string(), revision)

    try
      if revision != co_revisions(dep.locator)? then
        // what we have checked out is incorrect.
        // we need to run another checkout
        load_dep(dep)?
      end
    end
