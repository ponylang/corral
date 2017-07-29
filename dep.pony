use "files"
use "json"
use "logger"

class Dep
  let bundle: Bundle box
  let data: DepData box
  let lock: LockData box

  new create(bundle': Bundle box, data': DepData box, lock': LockData box) =>
    bundle = bundle'
    data = data'
    lock = lock'
/*
    _ops = match data.source
    | "github" => _GitHubOps(this)
    | "git"    => _GitOps(this)
    | "local"  => _LocalOps(this)
    else
      error
    end

  fun root_path(): FilePath => _ops.root_path()
  fun packages_path(): FilePath => _ops.packages_path()
  fun ref fetch() ? => _ops.fetch()
*/
  fun root_path(): String =>
    _PathNameEncoder(data.locator)

  fun packages_path(): String =>
    Path.join(root_path(), data.subdir)

/*
class _NoOps
  let dep: Dep
  new create(d: Dep) => dep = d
  fun root_path(): FilePath => dep.bundle.dir
  fun packages_path(): FilePath => dep.bundle.dir
  fun ref fetch() => None

class _GitHubOps is DepOps
  let dep: Dep

  // repo: name of github repo, including the github.com part
  // subdir: subdir within repo where pony packages are based
  // tag: git tag to checkout
  //
  // <bundle.dir>/.corral/<repo>/<github_repo_cloned_here>
  // <bundle.dir>/.corral/<repo>/<subdir>/<packages_tree_here>

  new create(d: Dep) => dep = d

  fun root_path(): FilePath =>
    dep.bundle.dir.join(".corral").join(dep.data.locator)

  fun packages_path(): FilePath =>
    root_path().join(dep.data.subdir)

  fun url(): String => "https://" + dep.data.locator + ".git"

  fun ref fetch() ? =>
    try
      if FileInfo(root_path()).directory then
        Shell("git -C " + root_path() + " pull " + url())
        GitRepo
      end
    else
      Shell("mkdir -p " + root_path())
      Shell("git clone " + url() + " " + root_path())
    end
    _checkout_revision()

  fun _checkout_revision() ? =>
    if dep.lock.revision != "" then
      Shell("cd " + root_path() + " && git checkout " + dep.lock.revision)
    end

class _GitOps is DepOps
  let dep: Dep
  let package_root: String

  // [local-]path: path to a local git repo
  // git_tag: git tag to checkout
  //
  // <bundle.dir>/.corral/<encoded_local_name>/<git_repo_cloned_here>
  // <bundle.dir>/.corral/<encoded_local_name>/<packages_tree_here>

  new create(b: Dep) =>
    dep = b
    package_root = _PathNameEncoder(dep.data.locator)
    dep.bundle.log.log(package_root)

  fun root_path(): FilePath =>
    Path.join(dep.bundle.dir.path, Path.join(".corral", package_root))

  fun packages_path(): String => root_path()

  fun ref fetch() ? =>
    Shell("git clone " + dep.data.locator + " " + root_path())
    _checkout_revision()

  fun _checkout_revision() ? =>
    if dep.lock.revision != "" then
      Shell("cd " + root_path() + " && git checkout " + dep.lock.revision)
    end

class _LocalOps is DepOps
  let dep: Dep

  new create(b: Dep) =>
    dep = b

  fun root_path(): FilePath => FilePath(dep.bundle.dir, dep.data.locator)

  fun packages_path(): String => root_path()

  fun ref fetch() => None
*/
