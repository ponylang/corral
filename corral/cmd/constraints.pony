use "collections"
use sr="../semver/range"
use ss="../semver/solver"
use sv="../semver/version"
use "../util"

primitive Constraints
  fun parse(constraint_str: String box): Array[ss.Constraint] =>
    let constraints: Array[ss.Constraint] = constraints.create()
    for c in constraint_str.split_by(" ").values() do
      let cs = recover val c.clone().>strip() end
      if cs != "" then
        try
          constraints.push(_parse_constraint(cs)?)
        else
          // How should we report a bad constraint?
          None // ctx.log.warn("Error parsing constraint " + cs)
        end
      end
    end
    constraints

  fun _parse_constraint(c: String box): ss.Constraint ? =>
    for pre in ["<="; "<"; ">="; ">"; "="; "^"; "~" ].values() do  // "-"; "+"
      if not c.at(pre) then continue end
      let part = recover val c.substring(pre.size().isize()) end
      let version = sv.ParseVersion(part)
      if pre.at("=") then
        let range = sr.Range(version, version, true, true)
        return ss.Constraint("A", range)
      elseif pre.at("^") then
        None
      elseif pre.at("~") then
        None
      else
        let from_version = if pre.at(">") then version else None end
        let to_version = if pre.at("<") then version else None end
        let inclusive = pre.at("=", 1)
        let range = sr.Range(from_version, to_version, inclusive, inclusive)
        return ss.Constraint("A", range)
      end
    end
    error

  fun solve(constraints: Array[ss.Constraint], tags: Array[String] val, log: Log): ss.Result
  =>
      let source: ss.InMemArtifactSource = source.create()
      for tg in tags.values() do
        log.fine("  tag:" + tg)
        let artifact = ss.Artifact("A", sv.ParseVersion(tg))
        source.add(artifact)
      end
      let result = ss.Solver(source).solve(constraints.values())
      if result.is_err() then
        log.fine("result err: " + result.err)
      end
      result
