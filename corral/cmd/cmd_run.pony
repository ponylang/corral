use "cli"
use "files"
use "logger"
use "process"
use "../bundle"
use "../util"
use "../vcs"

class CmdRun is CmdType
  let args: Array[String] val

  new create(cmd: Command) =>
    let argss = cmd.arg("args").string_seq()
    args = recover val Array[String].create() .> append(argss) end

  fun requires_bundle(): Bool => false

  fun apply(ctx: Context,
    project: Project,
    vcs_builder: VCSBuilder,
    result_receiver: CmdResultReceiver)
  =>
    ctx.uout(Info) and ctx.uout.log("run: " + " ".join(args.values()))

    // Build a : separated path from bundle roots.
    let ponypath = recover val
      match project.load_bundle()
      | let bundle: Bundle =>
        let ponypath' = recover trn String end
        let iter = project.transitive_deps(bundle).values()
        for d in iter do
          try
            ponypath'.append(project.dep_bundle_root(d.locator)?.path)
            if iter.has_next() then ponypath'.append(Path.list_sep()) end
          end
        end
        ponypath'
      | let err: String =>
        ctx.uout(Warn) and ctx.uout.log("run: continuing without a corral.json")
        String
      end
    end
    ctx.log(Info) and ctx.log.log("run ponypath: " + ponypath)

    let binary =
      try
        args(0)?
      else
        ctx.uout(Error) and ctx.uout.log("run: no run command provided")
        ctx.env.exitcode(1)
        return
      end
    let prog =
      try
        Program(ctx.env, binary)?
      else
        ctx.uout(Error) and ctx.uout.log("run: unable to find binary \"" + binary + "\" either in current directory or on $PATH.")
        ctx.env.exitcode(1)
        return
      end

    let vars = if ponypath.size() > 0 then
        recover val [as String: "PONYPATH=" + ponypath] .> append(ctx.env.vars) end
      else
        ctx.env.vars
      end
    let a = Action(prog, recover args.slice(1) end, vars)
    if not ctx.nothing then
      Runner.run(a, {(result: ActionResult) =>
        result.print_to(ctx.env.out)
        if not result.successful() then
          ctx.env.exitcode(result.exit_code())
        end
      })
    end
