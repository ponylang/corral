use "files"
use "regex"

primitive BzrOps is VcsOps
  fun tag fetch_op(env: Env): RepoOperation ? =>
    GitSyncRepo(env, GitCheckoutRepo(env, NoOperation)?)?
  fun tag tag_query_op(env: Env, rcv: TagListReceiver): RepoOperation ? =>
    GitQueryTags(env, rcv)?

