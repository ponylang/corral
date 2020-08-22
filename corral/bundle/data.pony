use "json"

class BundleData
  let info: InfoData
  let deps: Array[DepData]
  let scripts: (ScriptsData | None)

  new create(jo: JsonObject box) =>
    // TODO: iterate over jo's map and verify we just have "info" or "deps"
    // https://github.com/ponylang/corral/issues/64
    info = InfoData(Json.objekt(jo, "info"))

    deps = Array[DepData]
    let bundles_array = Json.array(jo, "deps")
    for bjt in bundles_array.data.values() do
      // TODO: somehow, catch and return error if bjt is not a JsonObject
      let bjo = try bjt as JsonObject box else JsonObject end
      let bd = DepData(bjo)
      deps.push(bd)
    end

    let scripts_obj = Json.objekt(jo, "scripts")
    scripts = if scripts_obj.data.size() > 0 then ScriptsData(scripts_obj) else None end

/*
  TODO: Currently in Bundle.bundle_json()
  fun json(): JsonObject =>
    let jo: JsonObject = JsonObject
    jo.data("info") = info.json()
    let bundles_array = recover ref JsonArray end
    for b in deps.values() do
      bundles_array.data.push(b.json())
    end
    jo.data("deps") = bundles_array
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

class ScriptsData
  var windows: (ScriptCommandData | None) = None
  var posix: (ScriptCommandData | None) = None

  new create(jo: JsonObject box) =>
    let win_obj = Json.objekt(jo, "windows")
    if win_obj.data.size() > 0 then
      windows = ScriptCommandData(win_obj)
    end
    let posix_obj = Json.objekt(jo, "posix")
    if posix_obj.data.size() > 0 then
      posix = ScriptCommandData(posix_obj)
    end

  fun json(): JsonObject ref =>
    let jo = JsonObject
    try
      jo.data("windows") = (windows as this->ScriptCommandData).json()
    end
    try
      jo.data("posix") = (posix as this->ScriptCommandData).json()
    end
    jo

class ScriptCommandData
  var post_fetch_or_update: String

  new create(jo: JsonObject box) =>
    post_fetch_or_update = Json.string(jo, "post_fetch_or_update")

  fun json(): JsonObject ref =>
    let jo = JsonObject
    Json.set_string(jo, "post_fetch_or_update", post_fetch_or_update)
    jo

class DepData
  var locator: String
  var version: String

  new create(jo: JsonObject box) =>
    locator = Json.string(jo, "locator")
    version = Json.string(jo, "version")

  new none() =>
    locator = ""
    version = ""

  fun json(): JsonObject ref =>
    let jo: JsonObject = JsonObject
    Json.set_string(jo, "locator", locator)
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
  var locator: String   // Present when locked
  var revision: String  // branch, tag, hash

  new create(jo: JsonObject box) =>
    locator = Json.string(jo, "locator")
    revision = Json.string(jo, "revision")

  new none() =>
    locator = ""
    revision = ""

  fun json(): JsonObject ref =>
    let jo: JsonObject = JsonObject
    Json.set_string(jo, "locator", locator)
    Json.set_string(jo, "revision", revision)
    jo
