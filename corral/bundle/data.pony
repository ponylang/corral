use "../json"

class BundleData
  """
  Parsed representation of a corral.json bundle file.
  """
  let info: InfoData
  let packages: Array[String]
  let deps: Array[DepData]
  let scripts: (ScriptsData | None)

  new create(jo: JSONObject box) =>
    // TODO: iterate over jo's map and verify we just have
    // "info" or "deps"
    // https://github.com/ponylang/corral/issues/64
    info = InfoData(JSON.objekt(jo, "info"))

    packages = Array[String]
    let packages_array = JSON.array(jo, "packages")
    for pjt in packages_array.data.values() do
      let s = try pjt as String else "" end
      packages.push(s)
    end

    deps = Array[DepData]
    let bundles_array = JSON.array(jo, "deps")
    for bjt in bundles_array.data.values() do
      // TODO: somehow, catch and return error if bjt is
      // not a JSONObject
      let bjo =
        try bjt as JSONObject box else JSONObject end
      let bd = DepData(bjo)
      deps.push(bd)
    end

    let scripts_obj = JSON.objekt(jo, "scripts")
    scripts =
      if scripts_obj.data.size() > 0 then
        ScriptsData(scripts_obj)
      else
        None
      end

/*
  TODO: Currently in Bundle.bundle_json()
  fun json(): JSONObject =>
    let jo: JSONObject = JSONObject
    jo.data("info") = info.json()
    let bundles_array = recover ref JSONArray end
    for b in deps.values() do
      bundles_array.data.push(b.json())
    end
    jo.data("deps") = bundles_array
    jo
*/
class InfoData
  """
  Parsed representation of the info section in a bundle file.
  """
  var name: String
  var description: String
  var homepage: String
  var documentation_url: String
  var license: String
  var version: String

  new create(jo: JSONObject box) =>
    name = JSON.string(jo, "name")
    description = JSON.string(jo, "description")
    homepage = JSON.string(jo, "homepage")
    documentation_url =
      JSON.string(jo, "documentation_url")
    license = JSON.string(jo, "license")
    version = JSON.string(jo, "version")

  fun json(): JSONObject ref =>
    """
    Serialize to a JSON object.
    """
    let jo: JSONObject = JSONObject
    JSON.set_string(jo, "name", name)
    JSON.set_string(jo, "description", description)
    JSON.set_string(jo, "homepage", homepage)
    JSON.set_string(
      jo, "documentation_url", documentation_url)
    JSON.set_string(jo, "license", license)
    JSON.set_string(jo, "version", version)
    jo

class ScriptsData
  """
  Parsed representation of the scripts section.
  """
  var windows: (ScriptCommandData | None) = None
  var posix: (ScriptCommandData | None) = None

  new create(jo: JSONObject box) =>
    let win_obj = JSON.objekt(jo, "windows")
    if win_obj.data.size() > 0 then
      windows = ScriptCommandData(win_obj)
    end
    let posix_obj = JSON.objekt(jo, "posix")
    if posix_obj.data.size() > 0 then
      posix = ScriptCommandData(posix_obj)
    end

  fun json(): JSONObject ref =>
    """
    Serialize to a JSON object.
    """
    let jo = JSONObject
    try
      jo.data("windows") =
        (windows as this->ScriptCommandData).json()
    end
    try
      jo.data("posix") =
        (posix as this->ScriptCommandData).json()
    end
    jo

class ScriptCommandData
  """
  Parsed representation of a single script command entry.
  """
  var post_fetch_or_update: String

  new create(jo: JSONObject box) =>
    post_fetch_or_update =
      JSON.string(jo, "post_fetch_or_update")

  fun json(): JSONObject ref =>
    """
    Serialize to a JSON object.
    """
    let jo = JSONObject
    JSON.set_string(
      jo, "post_fetch_or_update", post_fetch_or_update)
    jo

class DepData
  """
  Parsed representation of a single dependency entry.
  """
  var locator: String
  var version: String

  new create(jo: JSONObject box) =>
    locator = JSON.string(jo, "locator")
    version = JSON.string(jo, "version")

  new none() =>
    locator = ""
    version = ""

  fun json(): JSONObject ref =>
    """
    Serialize to a JSON object.
    """
    let jo: JSONObject = JSONObject
    JSON.set_string(jo, "locator", locator)
    JSON.set_string(jo, "version", version)
    jo

class LocksData
  """
  Parsed representation of a lock file.
  """
  let locks: Array[LockData]

  new create(jo: JSONObject box) =>
    locks = Array[LockData]
    let locks_array = JSON.array(jo, "locks")
    for ljt in locks_array.data.values() do
      let ljo =
        try ljt as JSONObject box else JSONObject end
      let ld = LockData(ljo)
      locks.push(ld)
    end

  fun json(): JSONObject =>
    """
    Serialize to a JSON object.
    """
    let jo: JSONObject = JSONObject
    let locks_array = recover ref JSONArray end
    for l in locks.values() do
      locks_array.data.push(l.json())
    end
    jo.data("locks") = locks_array
    jo

class LockData
  """
  Parsed representation of a single lock entry.
  """
  var locator: String   // Present when locked
  var revision: String  // branch, tag, hash

  new create(jo: JSONObject box) =>
    locator = JSON.string(jo, "locator")
    revision = JSON.string(jo, "revision")

  new none() =>
    locator = ""
    revision = ""

  fun json(): JSONObject ref =>
    """
    Serialize to a JSON object.
    """
    let jo: JSONObject = JSONObject
    JSON.set_string(jo, "locator", locator)
    JSON.set_string(jo, "revision", revision)
    jo
