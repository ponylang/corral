use "cli"
use "files"
use "logger"
use "../bundle"
use "../vcs"

class CmdFetch
  let ctx: Context
  let cmd: Command

  new create(ctx': Context, cmd': Command) =>
    ctx = ctx'
    cmd = cmd'

    ctx.env.out.print("fetch: " + cmd.string())
    try
      let bundle = BundleFile.load_bundle(ctx.env, ctx.log)?
      fetch_bundle_deps(bundle)
    else
      ctx.log.log("Error loading bundle")
    end

  fun fetch_bundle_deps(bundle: Bundle) =>
    for dep in bundle.deps.values() do
      try
        ctx.env.out.print("fetching: " + dep.data.locator)
        fetch(dep)?
      end
    end
    /*
    for dep in bundle.deps.values() do
      // TODO: detect and prevent infinite recursion here.
      try
        let bundle_dir = bundle.dir.join(dep.packages_path())
        fetch_bundle(Bundle.load(bundle_dir, log))
      end
    end*/

  fun fetch(dep: Dep) ? =>
    let local = ctx.repo_cache.join(dep.flat_repo())?
    let workspace = FilePath(ctx.env.root as AmbientAuth, dep.repo_root())?
    let ws = WorkSpec(dep.repo(), dep.version(), local, workspace)
    let vo = Vcs(dep.vcs())
    let ro = vo.fetch_op(ctx.env)?
    ro.begin(ws)
