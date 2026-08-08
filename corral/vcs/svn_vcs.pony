use "files"

primitive SvnVCS is VCS
  """
  Placeholder for Subversion VCS.
  """

  fun sync_op(
    result_receiver: RepoOperationResultReceiver,
    next: RepoOperation)
    : RepoOperation
  =>
    NoOperation(next)

  fun tag_query_op(
    result_receiver: RepoOperationResultReceiver,
    next: TagListReceiver)
    : RepoOperation
  =>
    NoOperationRcv(next)

  fun checkout_op(
    rev: String,
    result_receiver: RepoOperationResultReceiver,
    next: RepoOperation)
    : RepoOperation
  =>
    NoOperation(next)
