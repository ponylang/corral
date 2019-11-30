use "files"

primitive SvnVCS is VCS
  """
  Placeholder for Subversion VCS
  """
  fun sync_op(next: RepoOperation): RepoOperation => NoOperation(next)

  fun tag_query_op(next: TagListReceiver): RepoOperation => NoOperationRcv(next)

  fun checkout_op(rev: String, next: RepoOperation): RepoOperation => NoOperation(next)
