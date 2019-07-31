class Result
  let solution: Array[Artifact]
  let err: String

  new create(solution': Array[Artifact] = Array[Artifact], err': String = "") =>
    solution = solution'
    err = err'

  fun isErr(): Bool =>
    err.size() != 0
