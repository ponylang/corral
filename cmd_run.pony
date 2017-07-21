use "cli"
use "logger"

primitive CmdRun
  fun apply(env: Env, log: Logger[String], cmd: Command) =>
    env.out.print("run: " + cmd.string())
    let ponypath = try
      let bundle = BundleFile.load_bundle(env, log)
      var ponypath' = recover trn String end
      let iter = bundle.paths().values()
      for path in iter do
        ponypath'.append(path)
        if iter.has_next() then ponypath'.push(':') end
      end

      ponypath'
    else
      ""
    end
    env.out.print("run ponypath: " + ponypath)
    let args = cmd.arg("args").string_seq()
    let arr = if ponypath.size() > 0 then
        ["env"; "PONYPATH="+ponypath]
      else
        Array[String]()
      end
    try
      Shell.from_array(arr.>append(args), env~exitcode())
    end
