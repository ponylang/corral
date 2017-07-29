use "cli"
use "files"
use "logger"
use "vcs"

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
    let dd = dep.data
    let local = ctx.repo_cache.join(_PathNameEncoder(dd.locator))?
    let workspace = ctx.corral_base.join(dep.root_path())?
    let di = DepInfo(dd.locator, dd.version, local, workspace)
    let vo = Vcs(di)
    let ro = vo.fetch_op(ctx.env)?
    ro.begin(di)

"""
VCS Operations:
  - clone if new, pull (all branches) otherwise.
  - checkout revision
  - export_dir to bundle_dir
"""
