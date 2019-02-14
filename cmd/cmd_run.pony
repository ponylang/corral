use "cli"
use "../bundle"
use "../util" // Shell, Log

primitive CmdRun
  fun apply(ctx: Context, cmd: Command) =>
    ctx.env.out.print("run: " + cmd.string())
    let ponypath =
      try
        let bundle = BundleFile.load_bundle(ctx.env, ctx.log)?
        var ponypath' = recover trn String end
        let iter = bundle.bundle_roots().values()
        for path in iter do
          ponypath'.append(path)
          if iter.has_next() then ponypath'.push(':') end
        end
        ponypath'
      else
        ""
      end
    ctx.log.info("run ponypath: " + ponypath)
    let args = cmd.arg("args").string_seq()
    let arr = if ponypath.size() > 0 then
        ["env"; "PONYPATH="+ponypath]
      else
        Array[String]()
      end
    try
      // TODO: need to pass env in here...
      Shell.from_array(arr.>append(args), ctx.env.exitcode)?
    end
