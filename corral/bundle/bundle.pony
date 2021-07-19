use "collections"
use "files"
use "json"
use "logger"

class Bundle
  """
  Encapsulation of a Bundle + Lock file pair, including all file activities for
  those files.
  """
  let dir: FilePath
  let log: Logger[String]
  let info: InfoData
  let packages: Array[String]
  let deps: Map[String, Dep ref] = deps.create()
  let scripts: (ScriptsData | None)
  var modified: Bool = false

  new iso create(dir': FilePath, log': Logger[String]) =>
    dir = dir'
    log = log'
    info = InfoData(JsonObject)
    packages = Array[String]
    log(Info) and log.log("Created bundle in " + dir.path)
    scripts = None
    modified = true

  new iso load(dir': FilePath, log': Logger[String]) ? =>
    dir = dir'
    log = log'

    log(Fine) and log.log("Loading bundle: " + dir.join(Files.bundle_filename())?.path)
    let data = match Json.load_object(dir.join(Files.bundle_filename())?, log)
      | let jo: JsonObject => BundleData(jo)
      | let fe: FileErrNo =>
        log(Fine) and log.log("Bundle file not present for: " + Path.base(dir.path))
        error
      | let je: JsonError =>
        log(Error) and log.log("Bundle file unparseable for: " + Path.base(dir.path))
        error
      end
    info = data.info
    scripts = data.scripts
    packages = data.packages

    let lm = Map[String, LockData]
    try
      let locks_data = match Json.load_object(dir.join(Files.lock_filename())?, log)
        | let jo: JsonObject => LocksData(jo)
        | let fe: FileErrNo =>
          log(Fine) and log.log("Lock file not present for: " + Path.base(dir.path))
          error
        | let je: JsonError =>
          log(Error) and log.log("Lock file unparseable for: " + Path.base(dir.path))
          error
        end
      for l in locks_data.locks.values() do
        log(Fine) and log.log("Loaded " + name() + " lock: " + l.locator + " : " + l.revision)
        lm(l.locator) = l
      end
    end
    for dd in data.deps.values() do
      let d = Dep(this, dd, lm.get_or_else(dd.locator, LockData.none()))
      deps(d.data.locator) = d
      log(Fine) and log.log("Loaded " + name() + " dep: " + d.name())
    end

  fun name(): String => Path.base(dir.path)

  fun bundle_filepath(): FilePath ? => dir.join(Files.bundle_filename())?

  fun lock_filepath(): FilePath ? => dir.join(Files.lock_filename())?

  fun ref add_dep(locator: String, version: String, revision: String): Dep =>
    let dd = DepData(JsonObject)
    dd.locator = locator
    dd.version = version
    let ld = LockData(JsonObject)
    ld.locator = locator
    ld.revision = revision
    let dep = Dep(this, dd, ld)
    deps(locator) = dep
    modified = true
    dep

  fun ref remove_dep(locator: String) ? =>
    log(Fine) and log.log("Removing " + locator + " from " + "|".join(deps.keys()))
    deps.remove(locator)?
    modified = true

  fun dep_revision(locator: String): String =>
    """Returns the revision for a dep from this bundle's lock."""
    try
      deps(locator)?.revision()
    else
      ""  // No rev present for this dep in lock
    end

  fun ref lock_revision(locator: String, revision: String) =>
    """Records the revision for a dep into this bundle's lock."""
    try
      let dep = deps(locator)?
      dep.lock.locator = locator
      dep.lock.revision = revision
    else
      let dd = DepData.none()
      let ld = LockData.none()
      ld.locator = locator
      ld.revision = revision
      deps.insert(locator, Dep(this, dd, ld))
    end

  fun bundle_json(): JsonObject =>
    let jo: JsonObject = JsonObject
    jo.data("info") = info.json()

    let packages_array = recover ref JsonArray end
    for p in packages.values() do
      packages_array.data.push(p)
    end
    jo.data("packages") = packages_array

    let deps_array = recover ref JsonArray end
    for d in deps.values() do
      deps_array.data.push(d.data.json())
    end
    jo.data("deps") = deps_array

    try
      jo.data("scripts") = (scripts as this->ScriptsData).json()
    end
    jo

  fun lock_json(): JsonObject =>
    let jo: JsonObject = JsonObject
    let locks_array = recover ref JsonArray end
    for d in deps.values() do
      if d.lock.locator != "" then
        locks_array.data.push(d.lock.json())
      end
    end
    jo.data("locks") = locks_array
    jo

  fun ref save() ? =>
    if modified then
      Json.write_object(bundle_json(), bundle_filepath()?, log)
      modified = false
    end
    Json.write_object(lock_json(), lock_filepath()?, log)
