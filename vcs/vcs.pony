use "files"

class val DepInfo
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
    remote = remote'
    local = local'
    version = if version' == "" then "HEAD" else version' end
    workspace = workspace'

primitive Vcs
  fun apply(di: DepInfo): VcsOps =>
    // TODO: this is where we look at remote & figure out VCS.
    GitOps

trait val VcsOps
  fun tag fetch_op(env: Env): RepoOperation ?
  fun tag tag_query_op(env: Env, rcv: TagListReceiver): RepoOperation ?

trait val RepoOperation
  fun val begin(di: DepInfo)

trait tag TagListReceiver
  be receive(tags: Array[String] val)

class val NoOperation is RepoOperation
  new val create() => None
  fun val begin(di: DepInfo) => None

actor TagQueryPrinter is TagListReceiver
  let env: Env
  new create(env': Env) => env = env'
  be receive(tags: Array[String] val) =>
    for tg in tags.values() do
      env.out.print("tag: " + tg)
    end
