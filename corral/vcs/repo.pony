use "files"
use "../util"

class val Repo
  """
  Generalized details for any kind of VCS repo.
  """
  let remote: String // Remote URI to retrieve the repo
  let local: FilePath // Local clone of the repo
  let workspace: FilePath // Workspace to checkout into

  new val create(
    remote': String,
    local': FilePath,
    workspace': FilePath)
  =>
    remote = remote'
    local = local'
    workspace = workspace'

  fun string(): String =>
    "[" + remote + "," + local.path
      + "," + workspace.path + "]"

  fun is_remote(): Bool => remote != ""
