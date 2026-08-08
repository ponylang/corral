use "../util"

interface val RepoOperation
  """
  A RepoOperation encapsulates a high-level operation on
  a repo that is comprised of a chain of one or more
  smaller steps that all operate on a single given Repo
  and are initiated with apply().
  """

  fun val apply(repo: Repo)
  """
  Execute this operation on the given repo.
  """

interface tag RepoOperationResultReceiver
  """
  Receives error reports from repo operations.
  """

  be report_error(
    repo: Repo,
    action_result: ActionResult)
  """
  Report an error that occurred during a repo operation.
  """
