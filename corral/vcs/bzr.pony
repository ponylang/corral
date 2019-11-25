use "files"

primitive BzrVCS is VCS
  """
  Placeholder for Bazaar VCS
  """

  fun tag fetch_op(ver: String, fetch_follower: RepoOperation): RepoOperation => NoOperation

  fun tag update_op(rcv: TagListReceiver): RepoOperation => NoOperation

  fun tag tag_query_op(rcv: TagListReceiver): RepoOperation => NoOperation
