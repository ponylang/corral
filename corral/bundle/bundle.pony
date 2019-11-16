use "collections"
use "files"
use "json"
use "../util"

primitive BundleFile
  """
  Loader and creator of Bundle files.
  """
  fun find_bundle_dir(env: Env, log: Log): (FilePath | None) =>
    let cwd = Path.cwd()
    var dir = cwd
    while dir.size() > 0 do
      log.fine("Looking for " + Files.bundle_filename() + " in: '" + dir + "'")
      try
        let dir_path = FilePath(env.root as AmbientAuth, dir)?
        let bundle_file = dir_path.join(Files.bundle_filename())?
        if bundle_file.exists() then
          return dir_path
        end
      end
        dir = Path.split(dir)._1
    end
    log.info("corral.json not found, looked last in: '" + dir + "'")
    None

  fun load_bundle(env: Env, log: Log): (Bundle | Error) =>
    match find_bundle_dir(env, log)
    | let dir: FilePath =>
      try
        Bundle.load(env, dir, log)?
      else
        Error("Error loading bundle files in " + dir.path)
      end
    else
      Error(
        "No " + Files.bundle_filename()
          + " in current working directory or ancestors.")
    end

  fun create_bundle(env: Env, log: Log): (Bundle | Error) =>
    try
      let dir = FilePath(env.root as AmbientAuth, Path.cwd())?
      try Files.bundle_filepath(dir)?.remove() end
      Bundle.create(env, dir, log)
    else
      Error(
        "Could not create " + Files.bundle_filename()
          + " in current working directory.")
    end

class Bundle
  """
  Encapsulation of a Bundle + Lock file pair, including all file activities.
  """
  let env: Env
  let dir: FilePath
  let log: Log
  let info: InfoData
  let deps: Map[String, Dep ref] = deps.create()
  var modified: Bool = false

  new create(env': Env, dir': FilePath, log': Log) =>
    env = env'
    dir = dir'
    log = log'
    info = InfoData(JsonObject)
    log.info("Created bundle in " + dir.path)
    modified = true

  new load(env': Env, dir': FilePath, log': Log) ? =>
    env = env'
    dir = dir'
    log = log'

    log.fine("Loading bundle: " + Files.bundle_filepath(dir)?.path)
    let data = match Json.load_object(Files.bundle_filepath(dir)?, log)
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
      let locks_data = match Json.load_object(Files.lock_filepath(dir)?, log)
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
      log.fine("Dep " + d.name())
    end

  fun box name(): String => Path.base(dir.path)

  fun box bundle_filepath(): FilePath ? => Files.bundle_filepath(dir)?

  fun box lock_filepath(): FilePath ? => Files.lock_filepath(dir)?

  fun box corral_dirpath(): FilePath ? => dir.join("_corral")?

  fun box corral_dir(): String => Path.join(dir.path, "_corral")

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
          let dbundle = Bundle.load(env, bundle_root, log)?
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

  fun ref remove_dep(d: Dep) =>
    try
      deps.remove(d.data.locator)?
      modified = true
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

  fun save() ? =>
    if modified then
      Json.write_object(bundle_json(), bundle_filepath()?, log)
    end
    Json.write_object(lock_json(), lock_filepath()?, log)


primitive Files
  fun tag bundle_filename(): String => "corral.json"

  fun tag bundle_filepath(dir: FilePath): FilePath ? =>
    dir.join(bundle_filename())?

  fun tag lock_filename(): String => "lock.json"

  fun tag lock_filepath(dir: FilePath): FilePath ? =>
    dir.join(lock_filename())?
