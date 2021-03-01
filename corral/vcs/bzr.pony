use "files"

primitive BzrVCS is VCS
  """
  Placeholder for Bazaar VCS
  """
  fun val sync_op(resultReceiver: RepoOperationResultReceiver, next: RepoOperation): RepoOperation => NoOperation(next)

  fun val tag_query_op(resultReceiver: RepoOperationResultReceiver, next: TagListReceiver): RepoOperation => NoOperationRcv(next)

  fun val checkout_op(rev: String, resultReceiver: RepoOperationResultReceiver, next: RepoOperation): RepoOperation => NoOperation(next)
