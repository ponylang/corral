use "files"

class val WorkSpec
  let remote: String
  let version: String
  let local: FilePath
  let workspace: FilePath

  new val create(
    remote': String,
    version': String,
    local': FilePath,
    workspace': FilePath)
  =>
    remote = "https://" + remote'
    local = local'
    version = if version' == "" then "HEAD" else version' end
    workspace = workspace'

primitive Vcs
  fun apply(kind: String): VcsOps val =>
    // TODO: this is where we look at remote & figure out VCS.
    match kind
    | "git" => GitOps
    | "hg"  => HgOps
    | "bzr" => BzrOps
    | "svn" => SvnOps
    else
      NoneOps
    end

trait val VcsOps
  fun tag fetch_op(env: Env): RepoOperation ?
  fun tag tag_query_op(env: Env, rcv: TagListReceiver): RepoOperation ?

class val NoneOps is VcsOps
  fun tag fetch_op(env: Env): RepoOperation => NoOperation
  fun tag tag_query_op(env: Env, rcv: TagListReceiver): RepoOperation => NoOperation

trait val RepoOperation
  fun val begin(ws: WorkSpec)

trait tag TagListReceiver
  be receive(tags: Array[String] val)

class val NoOperation is RepoOperation
  new val create() => None
  fun val begin(ws: WorkSpec) => None

actor TagQueryPrinter is TagListReceiver
  let env: Env
  new create(env': Env) => env = env'
  be receive(tags: Array[String] val) =>
    for tg in tags.values() do
      env.out.print("tag: " + tg)
    end
