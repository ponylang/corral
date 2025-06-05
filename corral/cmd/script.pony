use "../logger"
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
              if not result.stderr.contains("running scripts is disabled") then
                ctx.uout(Fine) and ctx.uout.log("Succeeded: '" +
                  post_fetch_or_update + "' in '" + repo.workspace.path + "'")
                ctx.uout(Fine) and ctx.uout.log(result.stdout)
                return
              end
            else
              None
            end
            ctx.uout(Error) and ctx.uout.log("Failed: '" +
              post_fetch_or_update + "' in '" + repo.workspace.path + "'")
            ctx.uout(Error) and ctx.uout.log(result.stderr)
            ctx.env.exitcode(1)
          })
        end
      end
    end
