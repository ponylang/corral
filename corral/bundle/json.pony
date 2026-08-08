use "files"
use "../json"
use "../logger"

primitive JSONError
  """
  Sentinel value indicating a JSON parse error.
  """

primitive JSON
  """
  Helpers for loading and writing JSON bundle files.
  """

  fun load_object(
    file_path: FilePath,
    log: Logger[String])
    : (JSONObject | FileErrNo | JSONError)
  =>
    """
    Load a JSON object from a file.
    """
    let file =
      match \exhaustive\ OpenFile(file_path)
      | let f: File => f
      | let e: FileErrNo => return e
      end
    let content: String = file.read_string(file.size())
    let json: JSONDoc ref = JSONDoc
    try
      json.parse(content)?
      json.data as JSONObject
    else
      (let err_line, let err_message) =
        json.parse_report()
      log(Error) and log.log(
        "JSON error at: " + file.path.path
          + ":" + err_line.string()
          + " : " + err_message)
      JSONError
    end

  fun write_object(
    jo: JSONObject,
    file_path: FilePath,
    log: Logger[String])
  =>
    log(Fine) and log.log(
      "Going to write " + file_path.path)
    try
      let file = CreateFile(file_path) as File
      log(Info) and log.log(
        "Writing " + file.path.path)
      file.set_length(0)
      let json: JSONDoc = JSONDoc
      json.data = jo
      file.print(json.string("  ", true))
      file.dispose()
    else
      log(Error) and log.log(
        "Error writing " + file_path.path + ".")
    end

  fun string(jt: JSONType box, name: String): String =>
    try
      (jt as JSONObject box).data(name)? as String
    else
      ""
    end

  fun set_string(
    jo: JSONObject,
    name: String,
    value: String)
  =>
    jo.data(name) = value

  fun string_must(
    jt: JSONType box,
    name: String)
    : String ?
  =>
    (jt as JSONObject box).data(name)? as String

  fun array(
    jt: JSONType box,
    name: String)
    : JSONArray box
  =>
    try
      (jt as JSONObject box).data(name)?
        as JSONArray box
    else
      JSONArray
    end

  fun objekt(
    jt: JSONType box,
    name: String)
    : JSONObject box
  =>
    try
      (jt as JSONObject box).data(name)?
        as JSONObject box
    else
      JSONObject
    end
