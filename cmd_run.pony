use "cli"
use "logger"

primitive CmdRun
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("run: " + cmd.string())
    let ponypath = try
      let project = ProjectFile.load_project(env, log)
      var ponypath' = recover trn String end
      let iter = project.paths().values()
      for path in iter do
        ponypath'.append(path)
        if iter.has_next() then ponypath'.push(':') end
      end

      ponypath'
    else
      ""
    end
    env.out.print("run ponypath: " + ponypath)
    let rest = ["xxx"]
    try
      Shell.from_array(
        ["env"; "PONYPATH="+ponypath].>append(rest), env~exitcode()
      )
    end
