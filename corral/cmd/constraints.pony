use "collections"
use sr="../semver/range"
use ss="../semver/solver"
use sv="../semver/version"
use "../util"

primitive Constraints

  fun resolve_version(version: String, tags: Array[String] val, log: Log): String
  =>
    """
    Returns the best revision given a version string and an array of tag
    choices. If version is a tag, hash or other non-constraint, then return
    that.
    """
    // Attempt to parse version as constraints.
    let constraints =
      try
        _parse_constraints(version)?
      else
        return version // interpret version as a literal tag or hash
      end

    let result = _solve_constraints(constraints, tags, log)

    // TODO: probably OK to have multiple solutions: choose 'best' with a strategy like 'latest'.
    // https://github.com/ponylang/corral/issues/63

    try
      if (result.solution.size() == 0) or (result.is_err()) then
        log.warn("no solution for " + version + ": " + result.err)
        ""
      elseif result.solution.size() == 1 then
        let rev: String = result.solution(0)?.version.string()
        log.fine("single solution for " + version + ": " + rev)
        rev
      else
        log.fine("multiple solutions for " + version + ": " + result.solution.size().string())
        let max_heap = MaxHeap[ss.Artifact box](result.solution.size())
        max_heap.append(result.solution) // Could use itertools.map() to get a String iter
        let rev_arti = max_heap.pop()?
        log.fine("  selected: " + rev_arti.string())
        rev_arti.string()
      end
    else
      "" // Should not happen since we know collections accessed are not empty
    end


  fun best_revision(lrevision: String, drevision: String, version: String): String
  =>
    """
    Returns the best choice of possible: a lock revision, a fallback dep revision, and a version.
    TODO https://github.com/ponylang/corral/issues/59
    """
    if lrevision != "" then
      lrevision  // Base lock revision is always best
    elseif drevision != "" then
      drevision  // Dep lock revision is second best
    else
      try
        Constraints._parse_constraints(version)?
        "master" // Is a constraint: use main until update.
      else
        if version != "" then
          version  // Version is not a constraint, use that.
        else
          "master"  // Get the latest master if no constraints at all.
        end
      end
    end

  fun _parse_constraints(constraint_str: String box): Array[ss.Constraint] ? =>
    let constraints: Array[ss.Constraint] = constraints.create()
    for c in constraint_str.split_by(" ").values() do
      let cs = recover val c.clone().>strip() end
      if cs != "" then
        constraints.push(_parse_constraint(cs)?)
      end
    end
    if constraints.size() == 0 then
      error
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

  fun _solve_constraints(constraints: Array[ss.Constraint], tags: Array[String] val, log: Log): ss.Result
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
