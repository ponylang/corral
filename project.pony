use "files"
use "json"
use "logger"
//use "debug"

primitive ProjectFile
  fun filename(): String => "project.json"

  fun filepath(dir: FilePath): FilePath ? =>
    dir.join(ProjectFile.filename())

  fun find_project_dir(env: Env): (FilePath | None) =>
    let cwd = Path.cwd()
    var dir = cwd
    while dir.size() > 0 do
      //Debug.out("Looking for project.json in: '" + dir + "'")
      try
        let dir_path = FilePath(env.root as AmbientAuth, dir)
        let project_file = dir_path.join(filename())
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
      let project_path = dir.join(ProjectFile.filename())
      return Project.load(dir, log)
    else
      log.log("No " + filename() + " in current working directory or ancestors.")
      error
    end

  fun create_project(env: Env, log: Logger[String]): Project ? =>
    let dir = FilePath(env.root as AmbientAuth, Path.cwd())
    try filepath(dir).remove() end
    Project.create(dir, log)

class Project
  let dir: FilePath
  let log: Logger[String]
  let data: ProjectData

  new create(dir': FilePath, log': Logger[String]) =>
    dir = dir'
    log = log'
    data = ProjectData(JsonObject)
    log.log("Created project in " + dir.path)

  new load(dir': FilePath, log': Logger[String]) ? =>
    dir = dir'
    log = log'

    let file_path = ProjectFile.filepath(dir)
    log.log("Opening existing project " + file_path.path + ".")
    let file = OpenFile(file_path) as File // FileErrNo?
    let content: String = file.read_string(file.size())
    //log.log("Read: " + content + ".")
    let json: JsonDoc ref = JsonDoc
    try
      json.parse(content)
      data = ProjectData(json.data as JsonObject)
      return
    end
    (let err_line, let err_message) = json.parse_report()
    log(Error) and log.log(
      "JSON error at: " + file.path.path + ":" + err_line.string() + " : " + err_message
    )
    data = ProjectData.empty()
    error

  fun filepath(): FilePath ? => ProjectFile.filepath(dir)

  fun name(): String => Path.base(dir.path)

  fun bundles(): Iterator[Bundle] =>
    //ArrayValues[Bundle,Array[Bundle]](data.bundles)
    object is Iterator[Bundle]
      let project: Project box = this
      var i: USize = 0
      fun ref has_next(): Bool => i < project.data.bundles.size()
      fun ref next(): Bundle^ ? =>
        let b = BundleFor(project, project.data.bundles(i))
        i = i + 1
        b
    end

  fun fetch() =>
    for bundle in bundles() do
      try
        bundle.fetch()
      end
    end
    for bundle in bundles() do
      // TODO: detect and prevent infinite recursion here.
      try
        let bundle_dir = FilePath(dir, bundle.packages_path())
        Project(bundle_dir, log).fetch()
      end
    end

  fun paths(): Array[String] val =>
    let out = recover trn Array[String] end
    for bundle in bundles() do
      out.push(bundle.packages_path())
    end
    for bundle in bundles() do
      // TODO: detect and prevent infinite recursion here.
      try
        let bundle_dir = FilePath(dir, bundle.packages_path())
        out.append(Project(bundle_dir, log).paths())
      end
    end
    out

  fun ref add_bundle(bundle: BundleData) =>
    data.bundles.push(bundle)

  fun save() =>
    log.log("Going to save " + ProjectFile.filename() + " in " + dir.path)
    try
      let file = CreateFile(filepath()) as File
      log.log("Saving " + file.path.path)
      file.set_length(0)
      let json: JsonDoc = JsonDoc
      json.data = data.json()
      file.print(json.string("  ", true))
      file.dispose()
    else
      log.log("Error saving " + ProjectFile.filename() + " in " + dir.path)
    end
