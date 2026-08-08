"""
The solver package implements a dependency version
solver using semantic versioning constraints.
"""

use col = "collections"
use "../range"

class Solver
  """
  Resolves dependency constraints by finding compatible
  artifact versions from an ArtifactSource.
  """
  let source: ArtifactSource

  new create(source': ArtifactSource) =>
    source = source'

  fun ref solve(
    constraints: Iterator[Constraint])
    : Result
  =>
    """
    Solve the given constraints and return a Result
    containing the solution or an error message.
    """
    var pending_cells = Array[_Cell]
    for c in constraints do
      pending_cells.push(_Cell(c))
    end

    let activated_cells_by_name =
      col.Map[String, _Cell]
    var first_conflict:
      (_ConflictSnapshot | None) = None

    while pending_cells.size() > 0 do
      let new_pending_cells = Array[_Cell]

      for pcell in pending_cells.values() do
        if pcell.garbage then continue end

        let constraint = pcell.constraint
        let name = constraint.artifact_name

        // Artifact never seen before, activate its
        // cell: record its activation with the
        // global list and add its dependencies to
        // the tail of the pending cells.
        let existing_cell =
          try
            activated_cells_by_name(name)?
          else
            activated_cells_by_name(name) = pcell
            pcell.activated = true

            pcell.picks = _all_versions_of(name)
            (let match_index, let ok) =
              _index_of_first_match(
                pcell.picks,
                [ constraint.range ])
            if (not ok) then
              return Result(
                where err' =
                  "no artifacts match "
                    + constraint.string())
            end

            _pick(
              pcell,
              match_index,
              new_pending_cells)
            pcell
          end

        // New constraint is compatible with
        // existing pick
        try
          if constraint.range.contains(
            existing_cell.picks(0)?.version)
          then
            continue
          end
        end

        // New constraint is incompatible with
        // existing pick: log if this is the first
        // such conflict (in case we can't find a
        // solution), then backtrack up the tree
        // until an alternative path is found.
        if (first_conflict is None) then
          first_conflict =
            _ConflictSnapshot(
              Array[_Cell] .> concat(
                activated_cells_by_name.values()),
              pcell.constraint,
              pcell.parent)
        end

        var cell: (_Cell | None) = existing_cell
        let conflicting_constraint = constraint

        while true do
          match cell
          | let c: _Cell =>
            let ranges =
              Array[Range] .> push(
                c.constraint.range)

            // Blend in the constraint that
            // kicked this backtracking off
            if (conflicting_constraint
              .artifact_name
              == c.constraint.artifact_name)
            then
              ranges.push(
                conflicting_constraint.range)
            end

            (let match_index, let ok) =
              _index_of_first_match(
                c.picks.slice(1), ranges)
            if (ok) then
              _prune_children(
                c, activated_cells_by_name)
              _pick(
                c,
                match_index + 1,
                new_pending_cells)
              break
            end

            cell = c.parent
          else
            return Result(
              where err' =
                "no solutions found: "
                  + first_conflict.string())
          end
        end
      end

      pending_cells = new_pending_cells
    end

    let result = Result
    for cell in activated_cells_by_name.values() do
      try
        result.solution.push(cell.picks(0)?)
      end
    end
    result

  fun ref _all_versions_of(
    artifact_name: String)
    : Array[Artifact]
  =>
    // copy for isolation
    let versions =
      Array[Artifact] .> concat(
        source.all_versions_of(artifact_name))
    // reverse sort to make all the
    // 'default to latest' optimizations work
    col.Sort[Array[Artifact], Artifact](versions)
      .reverse()

  fun _index_of_first_match(
    artifacts: Array[Artifact],
    ranges: Seq[Range])
    : (USize, Bool)
  =>
    for (i, a) in artifacts.pairs() do
      var all_match = true

      for r in ranges.values() do
        if (not r.contains(a.version)) then
          all_match = false
          break
        end
      end

      if (all_match) then return (i, true) end
    end

    (0, false)

  fun _pick(
    cell: _Cell,
    index: USize,
    new_cells: Array[_Cell])
  =>
    cell.picks = cell.picks.slice(index)

    let cells_from_deps = Array[_Cell]
    try
      for dep in
        cell.picks(0)?.depends_on.values()
      do
        let c = _Cell(dep)
        c.parent = cell
        cells_from_deps.push(c)
      end
    end

    cell.children .> concat(
      cells_from_deps.values())
    new_cells .> concat(
      cells_from_deps.values())

  fun _prune_children(
    from_cell: _Cell,
    activated_cells_by_name:
      col.Map[String, _Cell])
  =>
    for cell in from_cell.children.values() do
      if cell.activated then
        try
          activated_cells_by_name.remove(
            cell.constraint.artifact_name)?
        end
      end

      cell.garbage = true
      _prune_children(
        cell, activated_cells_by_name)
    end

    from_cell.children.clear()
