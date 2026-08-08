use "../utils"

primitive ValidateFields
  """
  Validates pre-release and build metadata fields
  of a semantic version string.
  """
  fun apply(
    pr: Array[PreReleaseField],
    build: Array[String])
    : Array[String]
  =>
    """
    Return an array of validation error messages,
    empty if all fields are valid.
    """
    let errs = Array[String]

    for (i, field) in pr.pairs() do
      match field
      | let s: String =>
        let err =
          _validate_string_field(
            "pre-release", i, s)
        if (err != "") then errs.push(err) end
      end
    end

    for (i, field) in build.pairs() do
      let err =
        _validate_string_field(
          "build", i, field)
      if (err != "") then errs.push(err) end
    end

    errs

  fun _validate_string_field(
    set_name: String,
    i: USize,
    field: String)
    : String
  =>
    let field_id =
      set_name + " field " + (i + 1).string()

    if (field == "") then
      field_id + " is blank"
    elseif (not Strings.contains_only(
      field, Consts.alphanums()))
    then
      field_id
        + " contains non-alphanumeric characters"
    else
      ""
    end
