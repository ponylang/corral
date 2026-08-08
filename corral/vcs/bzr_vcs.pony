use "files"

primitive BzrVCS is VCS
  """
  Placeholder for Bazaar VCS.
  """

  fun val sync_op(
    result_receiver: RepoOperationResultReceiver,
    next: RepoOperation)
    : RepoOperation
  =>
    NoOperation(next)

  fun val tag_query_op(
    result_receiver: RepoOperationResultReceiver,
    next: TagListReceiver)
    : RepoOperation
  =>
    NoOperationRcv(next)

  fun val checkout_op(
    rev: String,
    result_receiver: RepoOperationResultReceiver,
    next: RepoOperation)
    : RepoOperation
  =>
    NoOperation(next)
