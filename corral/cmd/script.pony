
use "process"
use "../bundle"
use "../util"
use "../vcs"

primitive PostFetchScript
  fun apply(ctx: Context, repo: Repo val) =>
    try
      let bundle = recover val Bundle.load(repo.workspace, ctx.log)? end
      let scripts = bundle.scripts as ScriptsData val
      ifdef windows then
        let windows_scripts = scripts.windows as ScriptCommandData val
        let post_fetch = windows_scripts.post_fetch
        if post_fetch.size() > 0 then
          let argv = post_fetch.split(" ")
          if argv.size() > 0 then
            let program = Program(ctx.env, argv.shift()?)?
            let action = Action(program, consume argv, ctx.env.vars,
              repo.workspace)
            Runner.run(action, {(result: ActionResult) =>
              match result.exit_status
              | let exited: Exited =>
                ctx.uout.fine("Succeeded: '" + post_fetch + "' in '" +
                  repo.workspace.path + "'")
                ctx.uout.fine(result.stdout)
                return
              else
                None
              end
              ctx.uout.err("Failed: '" + post_fetch + "' in '" +
                repo.workspace.path + "'")
              ctx.uout.err(result.stderr)
            })
          end
        end
      end
    end
