use "collections"
use "files"
use "json"
use "../util"
//use "debug"

primitive BundleFile
  """Loader and creator of Bundle files."""
  fun find_bundle_dir(env: Env): (FilePath | None) =>
    let cwd = Path.cwd()
    var dir = cwd
    while dir.size() > 0 do
      //Debug.out("Looking for bundle.json in: '" + dir + "'")
      try
        let dir_path = FilePath(env.root as AmbientAuth, dir)?
        let bundle_file = dir_path.join(Files.bundle_filename())?
        if bundle_file.exists() then
          return dir_path
        end
      end
        dir = Path.split(dir)._1
    end
    //Debug.out("Looked last for bundle.json in: '" + dir + "'")
    None

  fun load_bundle(env: Env, log: Log): Bundle ? =>
    match find_bundle_dir(env)
    | let dir: FilePath =>
      try
        Bundle.load(env, dir, log)?
      else
        log.err("Error loading bundle files in " + dir.path)
        error
      end
    else
      log.err("No " + Files.bundle_filename() + " in current working directory or ancestors.")
      error
    end

  fun create_bundle(env: Env, log: Log): Bundle ? =>
    let dir = FilePath(env.root as AmbientAuth, Path.cwd())?
    try Files.bundle_filepath(dir)?.remove() end
    Bundle.create(env, dir, log)

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

  new load(env': Env, dir': FilePath, log': Log) ? =>
    env = env'
    dir = dir'
    log = log'

    log.fine("Loading bundle: " + Files.bundle_filepath(dir)?.path)
    let data = BundleData(Json.load_object(Files.bundle_filepath(dir)?, log)?)
    info = data.info

    let lm = Map[String, LockData]
    try
      let locks_data = LocksData(Json.load_object(Files.lock_filepath(dir)?, log)?)
      for l in locks_data.locks.values() do
        log.fine("Lock " + l.locator + " : " + l.revision)
        lm(l.locator) = l
      end
    else
      log.err("Lock file unreadable")
    end
    for dd in data.deps.values() do
      let d = Dep(this, dd, lm.get_or_else(dd.locator, LockData.none()))
      deps(d.data.locator) = d
      log.fine("Dep " + d.name())
    end

  fun bundle_filepath(): FilePath ? => Files.bundle_filepath(dir)?

  fun lock_filepath(): FilePath ? => Files.lock_filepath(dir)?

  fun name(): String => Path.base(dir.path)

  fun corral_path(): String => Path.join(dir.path, "_corral")

  fun bundle_roots(): Array[String] val =>
    let out = recover trn Array[String] end
    for dep in deps.values() do
      out.push(dep.bundle_root())
    end
    for dep in deps.values() do
      // TODO: detect and prevent infinite recursion here.
      try
        let bundle_dir = dir.join(dep.bundle_root())?
        out.append(Bundle(env, bundle_dir, log).bundle_roots())
      end
    end
    out

/*
  fun all_deps(): Array[Dep] =>
    let out = recover trn Array[Dep] end
    for dep in deps.values() do
      out.push(dep)
    end
    for dep in deps.values() do
      // TODO: detect and prevent infinite recursion here.
      try
        let bundle_dir = dir.join(dep.packages_path())?
        out.append(Bundle(env, bundle_dir, log).paths())
      end
    end
    out
*/

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
  fun tag bundle_filename(): String => "bundle.json"
  fun tag bundle_filepath(dir: FilePath): FilePath ? => dir.join(bundle_filename())?

  fun tag lock_filename(): String => "lock.json"
  fun tag lock_filepath(dir: FilePath): FilePath ? => dir.join(lock_filename())?
