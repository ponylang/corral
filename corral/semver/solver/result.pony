class Result
  let solution: Array[Artifact]
  let err: String

  new create(solution': Array[Artifact] = Array[Artifact], err': String = "") =>
    solution = solution'
    err = err'

  fun is_err(): Bool =>
    err.size() != 0
