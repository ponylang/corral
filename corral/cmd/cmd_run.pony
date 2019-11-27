use "cli"
use "process"
use "../bundle"
use "../util"

class CmdRun
  new create(ctx: Context, cmd: Command) =>
    let argss = cmd.arg("args").string_seq()
    let args = recover val Array[String].create() .> append(argss) end

    ctx.uout.info("run: " + " ".join(args.values()))

    // Build a : separated path from bundle roots.
    let ponypath = recover val
      match BundleFile.load_bundle(ctx.bundle_dir, ctx.log)
      | let bundle: Bundle =>
        var ponypath' = recover trn String end
        let iter = bundle.bundle_roots().values()
        for path in iter do
          ponypath'.append(path)
          if iter.has_next() then ponypath'.push(':') end
        end
        ponypath'
      | let err: Error =>
        ctx.uout.warn("run: continuing without a corral.json")
        String
      end
    end
    ctx.log.info("run ponypath: " + ponypath)

    try
      let prog = Program(ctx.env, args(0)?)?
      let vars = if ponypath.size() > 0 then
          recover val ["PONYPATH=" + ponypath] .> append(ctx.env.vars) end
        else
          ctx.env.vars
        end
      let a = Action(prog, recover args.slice(1) end, vars)
      if not ctx.nothing then
        Runner.run(a, {(result: ActionResult) => result.print_to(ctx.env.out) })
      end
    else
      ctx.uout.err("run: " + "couldn't run program: " + cmd.string())
      ctx.env.exitcode(1)
      return
    end
