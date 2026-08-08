class _Cell
  let constraint: Constraint
  var parent: (_Cell | None) = None
  var picks: Array[Artifact] = Array[Artifact]
  let children: Array[_Cell] = Array[_Cell]
  var activated: Bool = false
  var garbage: Bool = false

  new create(constraint': Constraint) =>
    constraint = constraint'
