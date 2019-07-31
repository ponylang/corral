use "../range"

class Constraint is Stringable
  let artifact_name: String
  let range: Range

  new create(artifact_name': String, range': Range) =>
    artifact_name = artifact_name'
    range = range'

  fun string(): String iso^ =>
    let result = recover String() end
    result.append(artifact_name + " [" + range.string() + "]")
    result
