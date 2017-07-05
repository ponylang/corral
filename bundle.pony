use "files"
use "json"
use "logger"

trait Bundle
  fun root_path(): String
  fun packages_path(): String
  fun ref fetch() ?

primitive BundleFor
  fun apply(project: Project box, data: BundleData box): Bundle ? =>
    match data.source
    | "github" => BundleGitHub(project, data)
    | "git"    => BundleGit(project, data)
    | "local"  => BundleLocal(project, data)
    else
      error
    end

class BundleGitHub is Bundle
  let project: Project box
  let data: BundleData box

  // repo: name of github repo, including the github.com part
  // subdir: subdir within repo where pony packages are based
  // tag: git tag to checkout
  //
  // <project.dir>/.corral/<repo>/<github_repo_cloned_here>
  // <project.dir>/.corral/<repo>/<subdir>/<packages_tree_here>

  new create(p: Project box, d: BundleData box) =>
    project = p
    data = d
    // TODO: we will assume data has been validated

  fun root_path(): String =>
    Path.join(project.dir.path, Path.join(".corral", data.locator))

  fun packages_path(): String => Path.join(root_path(), data.subdir)

  fun url(): String => "https://" + data.locator + ".git"

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
    if data.revision != "" then
      Shell("cd " + root_path() + " && git checkout " + data.revision)
    end

class BundleGit is Bundle
  let project: Project box
  let data: BundleData box
  let package_root: String

  // [local-]path: path to a local git repo
  // git_tag: git tag to checkout
  //
  // <project.dir>/.corral/<encoded_local_name>/<git_repo_cloned_here>
  // <project.dir>/.corral/<encoded_local_name>/<packages_tree_here>

  new create(p: Project box, d: BundleData box) =>
    project = p
    data = d
    // TODO: we will assume data has been validated
    package_root = _PathNameEncoder(data.locator)
    project.log.log(package_root)

  fun root_path(): String =>
    Path.join(project.dir.path, Path.join(".corral", package_root))

  fun packages_path(): String => root_path()

  fun ref fetch() ? =>
    Shell("git clone " + data.locator + " " + root_path())
    _checkout_revision()

  fun _checkout_revision() ? =>
    if data.revision != "" then
      Shell("cd " + root_path() + " && git checkout " + data.revision)
    end

class BundleLocal is Bundle
  let project: Project box
  let data: BundleData box

  new create(p: Project box, d: BundleData box) =>
    project = p
    data = d

  fun root_path(): String => data.locator

  fun packages_path(): String => root_path()

  fun ref fetch() => None
