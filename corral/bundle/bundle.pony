use "collections"
use "files"
use "json"
use "../util"

primitive Files
  fun tag bundle_filename(): String => "corral.json"
  fun tag lock_filename(): String => "lock.json"
  fun tag corral_dirname(): String => "_corral"

primitive BundleFile
  """
  Locator, loader and creator of Bundle files.
  """
  fun find_bundle_dir(auth: AmbientAuth, dir: String, log: Log): (FilePath | None) =>
    var dir' = dir
    while dir'.size() > 0 do
      log.info("Looking for " + Files.bundle_filename() + " in: '" + dir' + "'")
      try
        let dir_path = FilePath(auth, dir')?
        let bundle_file = dir_path.join(Files.bundle_filename())?
        if bundle_file.exists() then
          return dir_path
        end
      end
      dir' = Path.split(dir')._1
    end
    log.info(Files.bundle_filename() + " not found, looked last in: '" + dir' + "'")
    None

  fun resolve_bundle_dir(auth: AmbientAuth, dir: String, log: Log): (FilePath | None) =>
    log.info("Checking for " + Files.bundle_filename() + " in: '" + dir + "'")
    try
      let dir_path = FilePath(auth, dir)?
      let bundle_file = dir_path.join(Files.bundle_filename())?
      if bundle_file.exists() then
        return dir_path
      end
    end
    log.info(Files.bundle_filename() + " not found")
    None

  fun load_bundle(dir: FilePath, log: Log): (Bundle iso^ | Error) =>
    try
      Bundle.load(dir, log)?
    else
      Error("Error loading bundle files in " + dir.path)
    end

  fun create_bundle(dir: FilePath, log: Log): (Bundle iso^ | Error) =>
    try dir.join(Files.bundle_filename())?.remove() end
    Bundle.create(dir, log)

class Bundle
  """
  Encapsulation of a Bundle + Lock file pair, including all file activities.
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
        log.fine("Bundle file not present.")
        error
      | let je: JsonError =>
        log.err("Bundle file unparseable.")
        error
      end
    info = data.info

    let lm = Map[String, LockData]
    try
      let locks_data = match Json.load_object(dir.join(Files.lock_filename())?, log)
        | let jo: JsonObject => LocksData(jo)
        | let fe: FileErrNo =>
          log.fine("Lock file not present.")
          error
        | let je: JsonError =>
          log.err("Lock file unparseable.")
          error
        end
      for l in locks_data.locks.values() do
        log.fine("Lock " + l.locator + " : " + l.revision)
        lm(l.locator) = l
      end
    end
    for dd in data.deps.values() do
      let d = Dep(this, dd, lm.get_or_else(dd.locator, LockData.none()))
      deps(d.data.locator) = d
      log.fine("Dep of " + name() + ": " + d.name())
    end

  fun box name(): String => Path.base(dir.path)

  fun box bundle_filepath(): FilePath ? => dir.join(Files.bundle_filename())?

  fun box lock_filepath(): FilePath ? => dir.join(Files.lock_filename())?

  fun box corral_dirpath(): FilePath ? => dir.join(Files.corral_dirname())?

  fun box corral_dir(): String => Path.join(dir.path, Files.corral_dirname())

  fun box dep_workspace_root(dep: Dep box): FilePath ? =>
    corral_dirpath()?.join(dep.flat_name())?

  fun box dep_bundle_root(dep: Dep box): FilePath ? =>
    corral_dirpath()?.join(Path.join(dep.flat_name(), dep.locator.bundle_path))?

  fun box transitive_deps(): Map[String, Dep box] box =>
    """Return all immediate and transitive deps, with no duplicates."""
    let tran_deps = Map[String, Dep box]
    _transitive_deps(this, tran_deps)
    tran_deps

  fun box _transitive_deps(
    base_bundle: Bundle box,
    tran_deps: Map[String, Dep box])
  =>
    for dep in deps.values() do
      try
        if not tran_deps.contains(dep.name()) then
          tran_deps(dep.name()) = dep
          let bundle_root = base_bundle.dep_bundle_root(dep)?
          let dbundle: Bundle val = Bundle.load(bundle_root, log)?
          dbundle._transitive_deps(base_bundle, tran_deps)
        end
      else
        log.err("Bundle: error finding bundle dir for tdep: " + dep.name())
      end
    end

  fun box bundle_roots(): Array[String] val =>
    let tran_deps = transitive_deps()
    let roots = recover trn Array[String] end
    for dep in tran_deps.values() do
      let dr = Path.join(
        corral_dir(),
        Path.join(dep.flat_name(), dep.locator.bundle_path))
      roots.push(dr)
    end
    consume roots

  fun ref add_dep(dd: DepData, ld: LockData) =>
    deps(dd.locator) = Dep(this, dd, ld)
    modified = true

  fun ref remove_dep(locator: String) ? =>
    log.fine("Removing " + locator + " from " + "|".join(deps.keys()))
    deps.remove(locator)?
    modified = true

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

  fun save() ? =>
    if modified then
      Json.write_object(bundle_json(), bundle_filepath()?, log)
    end
    Json.write_object(lock_json(), lock_filepath()?, log)
