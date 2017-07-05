use "json"

primitive Field
  fun string(jt: JsonType box, name: String): String =>
    try
      (jt as JsonObject box).data(name) as String
    else
      ""
    end

  fun set_string(jo: JsonObject, name: String, value: String) =>
    if value != "" then
      jo.data(name) = value
    end

  fun string_must(jt: JsonType box, name: String): String ? =>
    (jt as JsonObject box).data(name) as String

  fun array(jt: JsonType box, name: String): JsonArray box =>
    try
      (jt as JsonObject box).data(name) as JsonArray box
    else
      JsonArray
    end

  fun objekt(jt: JsonType box, name: String): JsonObject box =>
    try
      (jt as JsonObject box).data(name) as JsonObject box
    else
      JsonObject
    end

class ProjectData
  let info: InfoData
  let bundles: Array[BundleData]

  new create(jo: JsonObject box) =>
    info = InfoData(Field.objekt(jo, "info"))
    bundles = Array[BundleData]
    let bundles_array = Field.array(jo, "bundles")
    for bjt in bundles_array.data.values() do
      let bjo = try bjt as JsonObject box else JsonObject end
      let bd = BundleData(bjo)
      bundles.push(bd)
    end

  new empty() =>
    info = InfoData.empty()
    bundles = Array[BundleData]

  fun json(): JsonObject =>
    let jo: JsonObject = JsonObject
    jo.data("info") = info.json()
    let bundles_array = recover ref JsonArray end
    for b in bundles.values() do
      bundles_array.data.push(b.json())
    end
    jo.data("bundles") = bundles_array
    jo

class InfoData
  var name: String
  var description: String
  var homepage: String
  var license: String
  var version: String

  new create(jo: JsonObject box) =>
    name = Field.string(jo, "name")
    description = Field.string(jo, "description")
    homepage = Field.string(jo, "homepage")
    license = Field.string(jo, "license")
    version = Field.string(jo, "version")

  new empty() =>
    name = ""
    description = ""
    homepage = ""
    license = ""
    version = ""

  fun json(): JsonObject ref =>
    let jo: JsonObject = JsonObject
    Field.set_string(jo, "name", name)
    Field.set_string(jo, "description", description)
    Field.set_string(jo, "homepage", homepage)
    Field.set_string(jo, "license", license)
    Field.set_string(jo, "version", version)
    jo

class BundleData
  var source: String
  var locator: String
  var subdir: String
  var version: String
  var revision: String  // branch, tag, hash

  new create(jo: JsonObject box) =>
    source = Field.string(jo, "source") // Required
    locator = Field.string(jo, "locator") // Required
    subdir = Field.string(jo, "subdir")
    version = Field.string(jo, "version")
    revision = Field.string(jo, "revision")
    // TODO: validate input and log/error
    //if data.locator == "" then
    //  project.log.log("No 'locator' key in bundle: " + info.string())
    //  error
    //end

  new empty() =>
    source = ""
    locator = ""
    subdir = ""
    version = ""
    revision = ""

  fun json(): JsonObject ref =>
    let jo: JsonObject = JsonObject
    Field.set_string(jo, "source", source)
    Field.set_string(jo, "locator", locator)
    Field.set_string(jo, "subdir", subdir)
    Field.set_string(jo, "version", version)
    Field.set_string(jo, "revision", revision)
    jo
