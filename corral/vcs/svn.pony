use "files"

primitive SvnVCS is VCS
  """
  Placeholder for Subversion VCS
  """
  fun sync_op(resultReceiver: RepoOperationResultReceiver, next: RepoOperation): RepoOperation => NoOperation(next)

  fun tag_query_op(resultReceiver: RepoOperationResultReceiver, next: TagListReceiver): RepoOperation => NoOperationRcv(next)

  fun checkout_op(rev: String, resultReceiver: RepoOperationResultReceiver, next: RepoOperation): RepoOperation => NoOperation(next)
