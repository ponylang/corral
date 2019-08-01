use "files"

primitive SvnVCS is VCS
  """
  Placeholder for Subversion VCS
  """

  fun tag fetch_op(ver: String): RepoOperation => NoOperation

  fun tag update_op(rcv: TagListReceiver): RepoOperation => NoOperation

  fun tag tag_query_op(rcv: TagListReceiver): RepoOperation => NoOperation
