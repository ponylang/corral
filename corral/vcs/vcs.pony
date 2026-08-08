"""
The vcs package provides version control system
abstractions for syncing, querying tags, and checking
out repositories.
"""

interface val VCS
  """
  A VCS provides functions to perform high-level VCS
  operations that commands use to work with repos.
  """

  fun val sync_op(
    result_receiver: RepoOperationResultReceiver,
    next: RepoOperation)
    : RepoOperation
  """
  Create a sync operation for this VCS.
  """

  fun val tag_query_op(
    result_receiver: RepoOperationResultReceiver,
    receiver: TagListReceiver)
    : RepoOperation
  """
  Create a tag query operation for this VCS.
  """

  fun val checkout_op(
    rev: String,
    result_receiver: RepoOperationResultReceiver,
    next: RepoOperation)
    : RepoOperation
  """
  Create a checkout operation for this VCS.
  """
