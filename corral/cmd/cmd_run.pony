use "cli"
use "process"
use "../bundle"
use "../util"

class CmdRun is CmdType
  let args: Array[String] val
  let exec:Bool

  new create(cmd: Command, exec':Bool) =>
    let argss = cmd.arg("args").string_seq()
    args = recover val Array[String].create() .> append(argss) end
    exec = exec'

  fun requires_bundle(): Bool => false

  fun apply(ctx: Context, project: Project) =>
    ctx.uout.info("run: " + " ".join(args.values()))

    // Build a : separated path from bundle roots.
    let ponypath = recover val
      match project.load_bundle()
      | let bundle: Bundle =>
        let ponypath' = recover trn String end
        let iter = project.transitive_deps(bundle).values()
        for d in iter do
          try
            ponypath'.append(project.dep_bundle_root(d.locator)?.path)
            if iter.has_next() then ponypath'.push(':') end
          end
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
      
      // if we use the exec option, replace this process with the run command
      // allows for use of things like corral run -- lldb ponyc
      if exec then
        ifdef posix then
          let cargs = Array[Pointer[U8] tag](32)
          for a in args.values() do
            cargs.push(a.cstring())
          end
          cargs.push(Pointer[U8])
  
          let cvars = Array[Pointer[U8] tag](32)
          for a in vars.values() do
            cvars.push(a.cstring())
          end
          cvars.push(Pointer[U8])
          
          @execve[I32](prog.path.path.cstring(), cargs.cpointer(), cvars.cpointer())
        else
          ctx.uout.err("exec command is only supported on posix, switching to run command")
        end
      end
      
      let a = Action(prog, recover args.slice(1) end, vars)
      if not ctx.nothing then
        Runner.run(a, {(result: ActionResult) => 
          result.print_to(ctx.env.out)
          if result.exit_code != 0 then
            ctx.env.exitcode(result.exit_code)
          end
        })
      end
    else
      ctx.uout.err("run: " + "couldn't run program: " + " ".join(args.values()))
      ctx.env.exitcode(1)
      return
    end
