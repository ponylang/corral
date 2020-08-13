
use "process"
use "../bundle"
use "../util"
use "../vcs"

primitive PostFetchScript
  fun apply(ctx: Context, repo: Repo val) =>
    try
      let bundle = recover val Bundle.load(repo.workspace, ctx.log)? end
      let scripts = bundle.scripts as ScriptsData val
      let platform_scripts =
        ifdef windows then
          scripts.windows as ScriptCommandData val
        else
          scripts.posix as ScriptCommandData val
        end

      let post_fetch_or_update = platform_scripts.post_fetch_or_update
      if post_fetch_or_update.size() > 0 then
        let argv = post_fetch_or_update.split(" ")
        if argv.size() > 0 then
          let program = Program(ctx.env, argv.shift()?)?
          let action = Action(program, consume argv, ctx.env.vars,
            repo.workspace)
          Runner.run(action, {(result: ActionResult) =>
            match result.exit_status
            | let exited: Exited =>
              ctx.uout.fine("Succeeded: '" + post_fetch_or_update + "' in '" +
                repo.workspace.path + "'")
              ctx.uout.fine(result.stdout)
              return
            else
              None
            end
            ctx.uout.err("Failed: '" + post_fetch_or_update + "' in '" +
              repo.workspace.path + "'")
            ctx.uout.err(result.stderr)
          })
        end
      end
    end
