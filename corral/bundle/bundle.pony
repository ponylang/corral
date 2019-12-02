use "collections"
use "files"
use "json"
use "../util"

class Bundle
  """
  Encapsulation of a Bundle + Lock file pair, including all file activities for
  those files.
  """
  let dir: FilePath
  let log: Log
  let info: InfoData
  let deps: Map[String, Dep ref] = deps.create()
  var modified: Bool = false

  new iso create(dir': FilePath, log': Log) =>
    dir = dir'
    log = log'
    info = InfoData(JsonObject)
    log.info("Created bundle in " + dir.path)
    modified = true

  new iso load(dir': FilePath, log': Log) ? =>
    dir = dir'
    log = log'

    log.fine("Loading bundle: " + dir.join(Files.bundle_filename())?.path)
    let data = match Json.load_object(dir.join(Files.bundle_filename())?, log)
      | let jo: JsonObject => BundleData(jo)
      | let fe: FileErrNo =>
        log.fine("Bundle file not present for: " + Path.base(dir.path))
        error
      | let je: JsonError =>
        log.err("Bundle file unparseable for: " + Path.base(dir.path))
        error
      end
    info = data.info

    let lm = Map[String, LockData]
    try
      let locks_data = match Json.load_object(dir.join(Files.lock_filename())?, log)
        | let jo: JsonObject => LocksData(jo)
        | let fe: FileErrNo =>
          log.fine("Lock file not present for: " + Path.base(dir.path))
          error
        | let je: JsonError =>
          log.err("Lock file unparseable for: " + Path.base(dir.path))
          error
        end
      for l in locks_data.locks.values() do
        log.fine("Loaded " + name() + " lock: " + l.locator + " : " + l.revision)
        lm(l.locator) = l
      end
    end
    for dd in data.deps.values() do
      let d = Dep(this, dd, lm.get_or_else(dd.locator, LockData.none()))
      deps(d.data.locator) = d
      log.fine("Loaded " + name() + " dep: " + d.name())
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
    deps(dd.locator) = dep
    modified = true
    dep

  fun ref remove_dep(locator: String) ? =>
    log.fine("Removing " + locator + " from " + "|".join(deps.keys()))
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
    let deps_array = recover ref JsonArray end
    for d in deps.values() do
      deps_array.data.push(d.data.json())
    end
    jo.data("deps") = deps_array
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
