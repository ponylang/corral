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
    "[" + remote + "," + local.path + "," + workspace.path + "]"

  fun is_remote(): Bool => remote != ""

interface val VCS
  """
  A Vcs provides functions to perform high-level VCS operations that commands
  use to work with repos.
  """
  fun val sync_op(resultReceiver: RepoOperationResultReceiver, next: RepoOperation): RepoOperation
  fun val tag_query_op(resultReceiver: RepoOperationResultReceiver, receiver: TagListReceiver): RepoOperation
  fun val checkout_op(rev: String, resultReceiver: RepoOperationResultReceiver, next: RepoOperation): RepoOperation

interface val RepoOperation
  """
  A RepoOperation encapsualtes a high-level operation on a repo that is
  comprised of a chain of one or more smaller steps that all operate on a
  single given Repo and are initiated with apply().
  """
  fun val apply(repo: Repo)

interface tag RepoOperationResultReceiver
  be reportError(repo: Repo, actionResult: ActionResult)

interface val TagListReceiver
  fun apply(repo: Repo, tags: Array[String] val)

class TagQueryPrinter is TagListReceiver
  let out: OutStream
  new create(out': OutStream) => out = out'
  fun apply(repo: Repo, tags: Array[String] val) =>
    for tg in tags.values() do
      out.print("tag: " + tg)
    end
