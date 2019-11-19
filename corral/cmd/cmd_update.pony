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

    match recover BundleFile.load_bundle(ctx.env, ctx.directory, ctx.log) end
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

      ctx.log.fine(
        "tags for [" + updates.size().string() + "] " + dep.locator.string()
          + ": " + tags.size().string())
      let source: ss.InMemArtifactSource = source.create()

      for tg in tags.values() do
        ctx.log.fine("  tag:" + tg)
        let artifact = ss.Artifact("A", sv.ParseVersion(tg))
        source.add(artifact)
      end
      ctx.log.fine("")

      // TODO: consider parsing version much earlier, before we even get here.
      // TODO: also consider allowing literal tags and not just constraints
      // expressions.
      let constraints = parse_constraints(dep.data.version)
      let result = ss.Solver(source).solve(constraints.values())

      ctx.log.fine("result err: " + result.err)
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

  fun parse_constraints(constraint_str: String box): Array[ss.Constraint] =>
    let constraints: Array[ss.Constraint] = constraints.create()
    for c in constraint_str.split_by(" ").values() do
      let cs = recover val c.clone().>strip() end
      if cs != "" then
        try
          constraints.push(parse_constraint(cs)?)
        else
          // How should we report a bad constraint?
          None // ctx.log.warn("Error parsing constraint " + cs)
        end
      end
    end
    constraints

  fun parse_constraint(c: String box): ss.Constraint ? =>
    for pre in ["<="; "<"; ">="; ">"; "="; "^"; "~" ].values() do  // "-"; "+"
      if not c.at(pre) then continue end
      let part = recover val c.substring(pre.size().isize()) end
      let version = sv.ParseVersion(part)
      if pre.at("=") then
        let range = sr.Range(version, version, true, true)
        return ss.Constraint("A", range)
      elseif pre.at("^") then
        None
      elseif pre.at("~") then
        None
      else
        let from_version = if pre.at(">") then version else None end
        let to_version = if pre.at("<") then version else None end
        let inclusive = pre.at("=", 1)
        let range = sr.Range(from_version, to_version, inclusive, inclusive)
        return ss.Constraint("A", range)
      end
    end
    error
