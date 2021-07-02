use "files"
use "json"
use "logger"

primitive JsonError

primitive Json
  fun load_object(file_path: FilePath, log: Logger[String])
    : (JsonObject | FileErrNo | JsonError)
  =>
    let file = match OpenFile(file_path)
    | let f: File => f
    | let e: FileErrNo => return e
    end
    let content: String = file.read_string(file.size())
    let json: JsonDoc ref = JsonDoc
    try
      json.parse(content)?
      json.data as JsonObject
    else
      (let err_line, let err_message) = json.parse_report()
      log(Error) and log.log(
        "JSON error at: " + file.path.path + ":" + err_line.string() + " : "
          + err_message)
      JsonError
    end

  fun write_object(jo: JsonObject, file_path: FilePath, log: Logger[String]) =>
    log(Fine) and log.log("Going to write " + file_path.path)
    try
      let file = CreateFile(file_path) as File
      log(Info) and log.log("Writing " + file.path.path)
      file.set_length(0)
      let json: JsonDoc = JsonDoc
      json.data = jo
      file.print(json.string("  ", true))
      file.dispose()
    else
      log(Error) and log.log("Error writing " + file_path.path + ".")
    end

  fun string(jt: JsonType box, name: String): String =>
    try
      (jt as JsonObject box).data(name)? as String
    else
      ""
    end

  fun set_string(jo: JsonObject, name: String, value: String) =>
    jo.data(name) = value

  fun string_must(jt: JsonType box, name: String): String ? =>
    (jt as JsonObject box).data(name)? as String

  fun array(jt: JsonType box, name: String): JsonArray box =>
    try
      (jt as JsonObject box).data(name)? as JsonArray box
    else
      JsonArray
    end

  fun objekt(jt: JsonType box, name: String): JsonObject box =>
    try
      (jt as JsonObject box).data(name)? as JsonObject box
    else
      JsonObject
    end
