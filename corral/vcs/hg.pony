use "files"

primitive HgVCS is VCS
  """
  Placeholder for Mercurial VCS
  """
  fun val sync_op(next: RepoOperation): RepoOperation => NoOperation(next)

  fun val tag_query_op(next: TagListReceiver): RepoOperation => NoOperationRcv(next)

  fun val checkout_op(rev: String, next: RepoOperation): RepoOperation => NoOperation(next)
