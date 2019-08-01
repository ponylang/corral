use "files"

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
    remote = "https://" + remote'
    local = local'
    workspace = workspace'

primitive VCSForType
  """
  This factory returns a VCS instance for any given VCS by name.
  """
  fun apply(env: Env, kind: String): VCS val ? =>
    match kind
    | "git" => GitVCS(env)?
    | "hg"  => HgVCS
    | "bzr" => BzrVCS
    | "svn" => SvnVCS
    else
      NoneVCS
    end

interface val VCS
  """
  A Vcs provides functions to perform high-level VCS operations that commands
  use to work with repos.
  """
  fun val fetch_op(ver: String): RepoOperation ?
  fun val update_op(rcv: TagListReceiver): RepoOperation ?
  fun val tag_query_op(rcv: TagListReceiver): RepoOperation ?

primitive NoneVCS is VCS
  """
  NoneVcs is a no-op VCS.
  """
  fun tag fetch_op(ver: String): RepoOperation => NoOperation
  fun tag update_op(rcv: TagListReceiver): RepoOperation => NoOperation
  fun tag tag_query_op(rcv: TagListReceiver): RepoOperation => NoOperation

interface val RepoOperation
  """
  A RepoOperation encapsualtes a high-level operation on a repo that is
  comprised of a chain of one or more smaller steps that all operate on a
  single given Repo and are initiated with apply().
  """
  fun val apply(repo: Repo)

class val NoOperation is RepoOperation
  """
  NoOperation is a no-op RepoOperation.
  """
  new val create() => None
  fun val apply(repo: Repo) => None

type TagListReceiver is {(Array[String] val)} val

actor TagQueryErrPrinter is TagListReceiver
  let env: Env
  new create(env': Env) => env = env'
  be apply(tags: Array[String] val) =>
    for tg in tags.values() do
      env.err.print("tag: " + tg)
    end
