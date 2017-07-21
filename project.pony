use "collections"
use "files"
use "json"
use "logger"
//use "debug"

primitive ProjectFile
  fun find_project_dir(env: Env): (FilePath | None) =>
    let cwd = Path.cwd()
    var dir = cwd
    while dir.size() > 0 do
      //Debug.out("Looking for project.json in: '" + dir + "'")
      try
        let dir_path = FilePath(env.root as AmbientAuth, dir)
        let project_file = dir_path.join(Files.proj_filename())
        if project_file.exists() then
          return dir_path
        end
      end
        dir = Path.split(dir)._1
    end
    //Debug.out("Looked last for project.json in: '" + dir + "'")
    None

  fun load_project(env: Env, log: Logger[String]): Project ? =>
    match find_project_dir(env)
    | let dir: FilePath =>
      return Project.load(dir, log)
    else
      log.log("No " + Files.proj_filename() + " in current working directory or ancestors.")
      error
    end

  fun create_project(env: Env, log: Logger[String]): Project ? =>
    let dir = FilePath(env.root as AmbientAuth, Path.cwd())
    try Files.proj_filepath(dir).remove() end
    Project.create(dir, log)

class Project
  let dir: FilePath
  let log: Logger[String]
  let info: InfoData
  let bundles: Map[String, Bundle ref] = bundles.create()

  new create(dir': FilePath, log': Logger[String]) =>
    dir = dir'
    log = log'
    info = InfoData(JsonObject)
    log.log("Created project in " + dir.path)

  new load(dir': FilePath, log': Logger[String]) ? =>
    dir = dir'
    log = log'
    let data = ProjectData(Json.load_object(Files.proj_filepath(dir), log))
    let locks_data = LocksData(Json.load_object(Files.lock_filepath(dir), log))
    // TODO: discard all locks that don't have matching bundles
    info = data.info

    let lm = Map[String, LockData]
    for l in locks_data.locks.values() do
      lm(l.locator) = l
    end
    for bd in data.bundles.values() do
      let b = Bundle(this, bd, lm.get_or_else(bd.locator, LockData(JsonObject)))
      bundles(b.data.locator) = b
    end

  fun filepath(): FilePath ? => Files.proj_filepath(dir)

  fun lock_filepath(): FilePath ? => Files.lock_filepath(dir)

  fun name(): String => Path.base(dir.path)

  fun ref fetch() =>
    for bundle in bundles.values() do
      try
        bundle.fetch()
      end
    end
    for bundle in bundles.values() do
      // TODO: detect and prevent infinite recursion here.
      try
        let bundle_dir = FilePath(dir, bundle.packages_path())
        Project.load(bundle_dir, log).fetch()
      end
    end

  fun paths(): Array[String] val =>
    let out = recover trn Array[String] end
    for bundle in bundles.values() do
      out.push(bundle.packages_path())
    end
    for bundle in bundles.values() do
      // TODO: detect and prevent infinite recursion here.
      try
        let bundle_dir = FilePath(dir, bundle.packages_path())
        out.append(Project(bundle_dir, log).paths())
      end
    end
    out

  fun ref add_bundle(bd: BundleData) ? =>
    bundles(bd.locator) = Bundle(this, bd, LockData(JsonObject))

  fun json(): JsonObject =>
    let jo: JsonObject = JsonObject
    jo.data("info") = info.json()
    let bundles_array = recover ref JsonArray end
    for b in bundles.values() do
      bundles_array.data.push(b.data.json())
    end
    jo.data("bundles") = bundles_array
    jo

  fun lock_json(): JsonObject =>
    let jo: JsonObject = JsonObject
    let bundles_array = recover ref JsonArray end
    for b in bundles.values() do
      bundles_array.data.push(b.lock.json())
    end
    jo.data("bundles") = bundles_array
    jo

  fun save() ? =>
    Json.write_object(json(), filepath(), log)
    Json.write_object(lock_json(), lock_filepath(), log)

primitive Files
  fun tag proj_filename(): String => "project.json"
  fun tag proj_filepath(dir: FilePath): FilePath ? => dir.join(proj_filename())

  fun tag lock_filename(): String => "bundle-lock.json"
  fun tag lock_filepath(dir: FilePath): FilePath ? => dir.join(lock_filename())
