use "json"

class ProjectData
  let info: InfoData
  let bundles: Array[BundleData]

  new create(jo: JsonObject box) =>
    info = InfoData(Json.objekt(jo, "info"))

    bundles = Array[BundleData]
    let bundles_array = Json.array(jo, "bundles")
    for bjt in bundles_array.data.values() do
      let bjo = try bjt as JsonObject box else JsonObject end
      let bd = BundleData(bjo)
      bundles.push(bd)
    end

/*
  fun json(): JsonObject =>
    let jo: JsonObject = JsonObject
    jo.data("info") = info.json()
    let bundles_array = recover ref JsonArray end
    for b in bundles.values() do
      bundles_array.data.push(b.json())
    end
    jo.data("bundles") = bundles_array
    jo
*/

class InfoData
  var name: String
  var description: String
  var homepage: String
  var license: String
  var version: String

  new create(jo: JsonObject box) =>
    name = Json.string(jo, "name")
    description = Json.string(jo, "description")
    homepage = Json.string(jo, "homepage")
    license = Json.string(jo, "license")
    version = Json.string(jo, "version")

  fun json(): JsonObject ref =>
    let jo: JsonObject = JsonObject
    Json.set_string(jo, "name", name)
    Json.set_string(jo, "description", description)
    Json.set_string(jo, "homepage", homepage)
    Json.set_string(jo, "license", license)
    Json.set_string(jo, "version", version)
    jo

class BundleData
  var source: String
  var locator: String
  var subdir: String
  var version: String

  new create(jo: JsonObject box) =>
    source = Json.string(jo, "source") // Required
    locator = Json.string(jo, "locator") // Required
    subdir = Json.string(jo, "subdir")
    version = Json.string(jo, "version")
    // TODO: validate input and log/error
    //if data.locator == "" then
    //  project.log.log("No 'locator' key in bundle: " + info.string())
    //  error
    //end

  fun json(): JsonObject ref =>
    let jo: JsonObject = JsonObject
    Json.set_string(jo, "source", source)
    Json.set_string(jo, "locator", locator)
    Json.set_string(jo, "subdir", subdir)
    Json.set_string(jo, "version", version)
    jo

class LocksData
  let locks: Array[LockData]

  new create(jo: JsonObject box) =>
    locks = Array[LockData]
    let locks_array = Json.array(jo, "locks")
    for ljt in locks_array.data.values() do
      let ljo = try ljt as JsonObject box else JsonObject end
      let ld = LockData(ljo)
      locks.push(ld)
    end

  fun json(): JsonObject =>
    let jo: JsonObject = JsonObject
    let locks_array = recover ref JsonArray end
    for l in locks.values() do
      locks_array.data.push(l.json())
    end
    jo.data("locks") = locks_array
    jo

class LockData
  var locator: String
  var revision: String  // branch, tag, hash

  new create(jo: JsonObject box) =>
    locator = Json.string(jo, "locator") // Required
    revision = Json.string(jo, "revision")
    // TODO: validate input and log/error
    //if data.locator == "" then
    //  project.log.log("No 'locator' key in bundle: " + info.string())
    //  error
    //end

  fun json(): JsonObject ref =>
    let jo: JsonObject = JsonObject
    Json.set_string(jo, "locator", locator)
    Json.set_string(jo, "revision", revision)
    jo
