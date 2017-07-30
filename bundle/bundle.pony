use "collections"
use "files"
use "json"
use "logger"
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

  fun load_bundle(env: Env, log: Logger[String]): Bundle ? =>
    match find_bundle_dir(env)
    | let dir: FilePath =>
      try
        Bundle.load(env, dir, log)?
      else
        log.log("Error loading bundle files in " + dir.path)
        error
      end
    else
      log.log("No " + Files.bundle_filename() + " in current working directory or ancestors.")
      error
    end

  fun create_bundle(env: Env, log: Logger[String]): Bundle ? =>
    let dir = FilePath(env.root as AmbientAuth, Path.cwd())?
    try Files.bundle_filepath(dir)?.remove() end
    Bundle.create(env, dir, log)

class Bundle
  """Encapsulation of a Bundle + Lock file pair, including all file activities."""
  let env: Env
  let dir: FilePath
  let log: Logger[String]
  let info: InfoData
  let deps: Map[String, Dep ref] = deps.create()

  new create(env': Env, dir': FilePath, log': Logger[String]) =>
    env = env'
    dir = dir'
    log = log'
    info = InfoData(JsonObject)
    log.log("Created bundle in " + dir.path)

  new load(env': Env, dir': FilePath, log': Logger[String]) ? =>
    env = env'
    dir = dir'
    log = log'

    let data = BundleData(Json.load_object(Files.bundle_filepath(dir)?, log)?)
    info = data.info

    let lm = Map[String, LockData]
    try
      let locks_data = LocksData(Json.load_object(Files.lock_filepath(dir)?, log)?)
      for l in locks_data.locks.values() do
        lm(l.locator) = l
      end
    end
    for dd in data.deps.values() do
      let d = Dep(this, dd, lm.get_or_else(dd.locator, LockData(JsonObject)))
      deps(d.data.locator) = d
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

  fun ref remove_dep(d: Dep) =>
    try deps.remove(d.data.locator)? end

  fun bundle_json(): JsonObject =>
    let jo: JsonObject = JsonObject
    jo.data("info") = info.json()
    let bundles_array = recover ref JsonArray end
    for b in deps.values() do
      bundles_array.data.push(b.data.json())
    end
    jo.data("deps") = bundles_array
    jo

  fun lock_json(): JsonObject =>
    let jo: JsonObject = JsonObject
    let bundles_array = recover ref JsonArray end
    for b in deps.values() do
      bundles_array.data.push(b.lock.json())
    end
    jo.data("deps") = bundles_array
    jo

  fun save() ? =>
    Json.write_object(bundle_json(), bundle_filepath()?, log)
    Json.write_object(lock_json(), lock_filepath()?, log)

primitive Files
  fun tag bundle_filename(): String => "bundle.json"
  fun tag bundle_filepath(dir: FilePath): FilePath ? => dir.join(bundle_filename())?

  fun tag lock_filename(): String => "lock.json"
  fun tag lock_filepath(dir: FilePath): FilePath ? => dir.join(lock_filename())?
