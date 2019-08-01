use "files"
use "json"
use "../util"

primitive JsonError

primitive Json
  fun load_object(file_path: FilePath, log: Log)
    : (JsonObject | FileErrNo | JsonError)
  =>
    log.fine("Reading " + file_path.path)
    let file = match OpenFile(file_path)
    | let f: File => f
    | let e: FileErrNo => return e
    end
    let content: String = file.read_string(file.size())
    //log.log("Read: " + content + ".")
    let json: JsonDoc ref = JsonDoc
    try
      json.parse(content)?
      json.data as JsonObject
    else
      (let err_line, let err_message) = json.parse_report()
      log.err(
        "JSON error at: " + file.path.path + ":" + err_line.string() + " : "
          + err_message)
      JsonError
    end

  fun write_object(jo: JsonObject, file_path: FilePath, log: Log) =>
    log.fine("Going to write " + file_path.path)
    try
      let file = CreateFile(file_path) as File
      log.info("Writing " + file.path.path)
      file.set_length(0)
      let json: JsonDoc = JsonDoc
      json.data = jo
      file.print(json.string("  ", true))
      file.dispose()
    else
      log.err("Error writing " + file_path.path + ".")
    end

  fun string(jt: JsonType box, name: String): String =>
    try
      (jt as JsonObject box).data(name)? as String
    else
      ""
    end

  fun set_string(jo: JsonObject, name: String, value: String) =>
    if value != "" then
      jo.data(name) = value
    end

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
