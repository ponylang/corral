use "../utils"

primitive ValidateFields
  fun apply(pr: Array[PreReleaseField], build: Array[String]): Array[String] =>
    let errs = Array[String]

    for (i, field) in pr.pairs() do
      match field
      | let s: String =>
        let err = _validate_string_Field("pre-release", i, s)
        if (err != "") then errs.push(err) end
      end
    end

    for (i, field) in build.pairs() do
      let err = _validate_string_Field("build", i, field)
      if (err != "") then errs.push(err) end
    end

    errs

  fun _validate_string_Field(setName: String, i: USize, field: String): String =>
    let fieldId = setName + " field " + (i + 1).string()

    if (field == "") then
      fieldId + " is blank"
    elseif (not Strings.contains_only(field, Consts.alphanums())) then
      fieldId + " contains non-alphanumeric characters"
    else
      ""
    end
