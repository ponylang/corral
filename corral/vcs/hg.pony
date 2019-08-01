use "files"

primitive HgVCS is VCS
  """
  Placeholder for Mercurial VCS
  """

  fun tag fetch_op(ver: String): RepoOperation => NoOperation

  fun tag update_op(rcv: TagListReceiver): RepoOperation => NoOperation

  fun tag tag_query_op(rcv: TagListReceiver): RepoOperation => NoOperation
