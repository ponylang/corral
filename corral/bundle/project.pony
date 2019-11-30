use "collections"
use "files"
use "json"
use "../util"

primitive Files
  fun tag bundle_filename(): String => "corral.json"
  fun tag lock_filename(): String => "lock.json"
  fun tag corral_dirname(): String => "_corral"

primitive BundleDir
  """
  Locates project bundle directories either by direct resolving of bundle
  files, or searching up the directory tree until the files are found.
  """
  fun find(auth: AmbientAuth, dir: String, log: Log): (FilePath | None) =>
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

  fun resolve(auth: AmbientAuth, dir: String, log: Log): (FilePath | None) =>
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

class val Project
  """
  Project assists with the performing operations on bundles and deps of a
  project.
  """
  let auth: AmbientAuth
  let log: Log
  let dir: FilePath

  new val create(auth': AmbientAuth, log': Log, dir': FilePath) =>
    auth = auth'
    log = log'
    dir = dir'

  fun val load_bundle(): (Bundle iso^ | Error) =>
    try
      Bundle.load(dir, log)?
    else
      Error("Error loading bundle files in " + dir.path)
    end

  fun create_bundle(): (Bundle iso^ | Error) =>
    Bundle.create(dir, log)

  fun corral_dirpath(): FilePath ? => dir.join(Files.corral_dirname())?

  // For VCS only (not for local-direct)
  fun dep_workspace_root(locator: Locator): FilePath ? =>
    """
    Returns the VCS workspace root for a given dep. Not used for local-direct deps.
    """
    let root = if locator.is_local_direct() then
      error
    else
      corral_dirpath()?.join(locator.flat_name())?
    end
    root

  fun dep_bundle_root(locator: Locator): FilePath ? =>
    let root = if locator.is_local_direct() then
      FilePath(auth, Path.join(dir.path, locator.bundle_path))?
    else
      corral_dirpath()?.join(Path.join(locator.flat_name(), locator.bundle_path))?
    end
    root

  fun transitive_deps(base_bundle: Bundle box): Map[Locator, Dep box] box =>
    """Return all immediate and transitive deps, with no duplicates."""
    let tran_deps = Map[Locator, Dep box]
    _transitive_deps(base_bundle, tran_deps)
    tran_deps

  fun _transitive_deps(
    bundle: Bundle box,
    tran_deps: Map[Locator, Dep box])
  =>
    for dep in bundle.deps.values() do
      try
        if not tran_deps.contains(dep.locator) then
          tran_deps(dep.locator) = dep
          let dbundle_root = dep_bundle_root(dep.locator)?
          let dbundle: Bundle val = Bundle.load(dbundle_root, log)?
          _transitive_deps(dbundle, tran_deps)
        end
      else
        log.err("Project: error finding/loading bundle for dep: " + dep.name())
      end
    end
