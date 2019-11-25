use "cli"
use "collections"
use "files"
use "../bundle"
use "../util"
use "../vcs"
use sr="../semver/range"
use ss="../semver/solver"
use sv="../semver/version"

primitive CmdUpdate
  fun apply(ctx: Context, cmd: Command) =>
    ctx.log.info("update: " + cmd.string())

    ctx.env.out.print("\nupdate:")

    match recover BundleFile.load_bundle(ctx.bundle_dir, ctx.log) end
    | let bundle: Bundle iso =>
      _Updater(ctx).update_bundle_deps(consume bundle)
    | let err: Error =>
      ctx.env.out.print(err.message)
      ctx.env.exitcode(1)
    end

actor _Updater
  let ctx: Context
  let updates: MapIs[Dep tag, Dep] ref

  new create(ctx': Context) =>
    ctx = ctx'
    updates = updates.create()

  be update_bundle_deps(bundle': Bundle iso) =>
    let bundle: Bundle ref = consume bundle'
    for dep in bundle.deps.values() do
      try
        update_dep(bundle, dep)?
        //TODO: recursive
      else
        ctx.log.err("Error updating dep " + dep.name())
        // It won't get a lock. How should we handle the error?
      end
    end

  fun ref update_dep(base_bundle: Bundle box, dep: Dep) ? =>
    let local = ctx.repo_cache.join(dep.flat_repo())?
    let workspace = base_bundle.dep_workspace_root(dep)?
    let repo = Repo(dep.repo(), local, workspace)
    let vcs = VCSForType(ctx.env, dep.vcs())?

    let deptag: Dep tag = dep
    updates(deptag) = dep

    let self: _Updater tag = this
    let update_op = vcs.update_op({
      (tags: Array[String] val) => self.update_dep_tags(deptag, tags)
    } val)?
    update_op(repo)

  be update_dep_tags(dep': Dep tag, tags: Array[String] val) =>
    try
      (let deptag, let dep) = updates.remove(dep')?

      // TODO: consider parsing version much earlier, maybe in Bundle.
      // TODO: also consider allowing literal tags and not just constraints
      // expressions.
      let constraints = Constraints.parse(dep.data.version)

      ctx.log.fine(
        "tags for [" + updates.size().string() + "] " + dep.locator.string()
          + ": " + tags.size().string())

      let result = Constraints.solve(constraints, tags, ctx.log)

      // TODO: probably OK to have multiple solutions: choose 'best' with a strategy like 'latest'.
      if result.solution.size() == 1 then
        let v = result.solution(0)?.version.string()
        //dep.lock.revision = consume v
        dep.lock_version(consume v)
      end

      if updates.size() == 0 then
        try
          dep.bundle.save()?
        else
          ctx.log.err("Error saving bundle")
        end
      end
    end
