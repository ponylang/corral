use "files"
use "debug"

primitive NoneVCS is VCS
  """
  NoneVCS is a no-op VCS that invokes its callbacks
  without doing any work.
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

class val NoOperation is RepoOperation
  """
  NoOperation is a no-op RepoOperation that chains to
  the next RepoOperation.
  """

  let next: RepoOperation

  new val create(next': RepoOperation) =>
    next = next'

  fun val apply(repo: Repo) => next(repo)

class val NoOperationRcv is RepoOperation
  """
  NoOperationRcv is a no-op RepoOperation that chains to
  the next TagListReceiver.
  """

  let next: TagListReceiver

  new val create(next': TagListReceiver) =>
    next = next'

  fun apply(repo: Repo) =>
    next(repo, recover iso Array[String] end)

class val NoReceiver is TagListReceiver
  """
  NoReceiver is a no-op TagListReceiver that chains to
  the next RepoOperation.
  """

  let next: RepoOperation

  new val create(next': RepoOperation) =>
    next = next'

  fun apply(repo: Repo, tags: Array[String] val) =>
    next(repo)
