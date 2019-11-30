use "files"

primitive BzrVCS is VCS
  """
  Placeholder for Bazaar VCS
  """
  fun val sync_op(next: RepoOperation): RepoOperation => NoOperation(next)

  fun val tag_query_op(next: TagListReceiver): RepoOperation => NoOperationRcv(next)

  fun val checkout_op(rev: String, next: RepoOperation): RepoOperation => NoOperation(next)
