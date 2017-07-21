use "files"
use "json"
use "logger"

interface BundleOps
  fun root_path(): String
  fun packages_path(): String
  fun ref fetch() ?

class Bundle is BundleOps
  let project: Project box
  let data: BundleData box
  let lock: LockData box
  var _ops: BundleOps = _NoOps

  new create(project': Project box, data': BundleData box, lock': LockData box) ? =>
    project = project'
    data = data'
    lock = lock'
    _ops = match data.source
    | "github" => _GitHubOps(this)
    | "git"    => _GitOps(this)
    | "local"  => _LocalOps(this)
    else
      error
    end

  fun root_path(): String => _ops.root_path()
  fun packages_path(): String => _ops.packages_path()
  fun ref fetch() ? => _ops.fetch()

class _NoOps
  fun root_path(): String => ""
  fun packages_path(): String => ""
  fun ref fetch() => None

class _GitHubOps is BundleOps
  let bundle: Bundle

  // repo: name of github repo, including the github.com part
  // subdir: subdir within repo where pony packages are based
  // tag: git tag to checkout
  //
  // <project.dir>/.corral/<repo>/<github_repo_cloned_here>
  // <project.dir>/.corral/<repo>/<subdir>/<packages_tree_here>

  new create(b: Bundle) =>
    bundle = b

  fun root_path(): String =>
    Path.join(bundle.project.dir.path, Path.join(".corral", bundle.data.locator))

  fun packages_path(): String => Path.join(root_path(), bundle.data.subdir)

  fun url(): String => "https://" + bundle.data.locator + ".git"

  fun ref fetch() ? =>
    try
      Shell("test -d " + root_path())
      Shell("git -C " + root_path() + " pull " + url())
    else
      Shell("mkdir -p " + root_path())
      Shell("git clone " + url() + " " + root_path())
    end
    _checkout_revision()

  fun _checkout_revision() ? =>
    if bundle.lock.revision != "" then
      Shell("cd " + root_path() + " && git checkout " + bundle.lock.revision)
    end

class _GitOps is BundleOps
  let bundle: Bundle
  let package_root: String

  // [local-]path: path to a local git repo
  // git_tag: git tag to checkout
  //
  // <project.dir>/.corral/<encoded_local_name>/<git_repo_cloned_here>
  // <project.dir>/.corral/<encoded_local_name>/<packages_tree_here>

  new create(b: Bundle) =>
    bundle = b
    package_root = _PathNameEncoder(bundle.data.locator)
    bundle.project.log.log(package_root)

  fun root_path(): String =>
    Path.join(bundle.project.dir.path, Path.join(".corral", package_root))

  fun packages_path(): String => root_path()

  fun ref fetch() ? =>
    Shell("git clone " + bundle.data.locator + " " + root_path())
    _checkout_revision()

  fun _checkout_revision() ? =>
    if bundle.lock.revision != "" then
      Shell("cd " + root_path() + " && git checkout " + bundle.lock.revision)
    end

class _LocalOps is BundleOps
  let bundle: Bundle

  new create(b: Bundle) =>
    bundle = b

  fun root_path(): String => bundle.data.locator

  fun packages_path(): String => root_path()

  fun ref fetch() => None
