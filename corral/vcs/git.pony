use "files"
use "../util"
use "process"

class val GitVCS is VCS
  """
  Git implementation of VCS.
  """
  let env: Env
  let prog: Program

  new val create(env': Env) ? =>
    env = env'
    prog =
      Program(
        env,
        ifdef windows then
          "git.exe"
        else
          "git"
        end)?

  fun val sync_op(
    result_receiver: RepoOperationResultReceiver,
    next: RepoOperation)
    : RepoOperation
  =>
    GitSyncRepo(this, result_receiver, next)

  fun val tag_query_op(
    result_receiver: RepoOperationResultReceiver,
    next: TagListReceiver)
    : RepoOperation
  =>
    GitQueryTags(this, result_receiver, next)

  fun val checkout_op(
    rev: String,
    result_receiver: RepoOperationResultReceiver,
    next: RepoOperation)
    : RepoOperation
  =>
    GitCheckoutRepo(this, rev, result_receiver, next)

class val GitSyncRepo is RepoOperation
  """
  Clones or fetches a git repo.
  """
  let git: GitVCS
  let next: RepoOperation
  let result_receiver: RepoOperationResultReceiver

  new val create(
    git': GitVCS,
    result_receiver': RepoOperationResultReceiver,
    next': RepoOperation)
  =>
    git = git'
    next = next'
    result_receiver = result_receiver'

  fun val apply(repo: Repo) =>
    if repo.is_remote() then
      let exists =
        try repo.local.join(".git")?.exists()
        else false
        end
      if not exists then
        git.env.err.print(
          "git cloning " + repo.remote
            + " into " + repo.local.path)
        _clone(repo)
      else
        git.env.err.print(
          "git fetching " + repo.remote
            + " into " + repo.local.path)
        _fetch(repo)
      end
    else
      // local repos don't need syncing
      next(repo)
    end

  fun val _clone(repo: Repo) =>
    let remote_uri =
      recover val "https://" + repo.remote end
    // Maybe: --recurse-submodules --quiet --verbose
    let action =
      Action(
        git.prog,
        recover
          [ "clone"
            "--no-checkout"
            remote_uri
            repo.local.path]
        end,
        git.env.vars)
    Runner.run(
      action,
      {(ar: ActionResult)(self = this) =>
        // ar.print_to(git.env.err)
        if ar.successful() then
          next(repo)
        else
          result_receiver.report_error(repo, ar)
        end
      } iso)

  fun val _fetch(repo: Repo) =>
    let action =
      Action(
        git.prog,
        recover
          ["-C"; repo.local.path; "fetch"; "--tags"]
        end,
        git.env.vars)
    Runner.run(
      action,
      {(ar: ActionResult)(self = this) =>
        // ar.print_to(git.env.err)
        if ar.successful() then
          next(repo)
        else
          result_receiver.report_error(repo, ar)
        end
      } iso)

class val GitQueryTags is RepoOperation
  """
  Queries tags from a git repo.
  """
  let git: GitVCS
  let next: TagListReceiver
  let result_receiver: RepoOperationResultReceiver

  new val create(
    git': GitVCS,
    result_receiver': RepoOperationResultReceiver,
    next': TagListReceiver)
  =>
    git = git'
    next = next'
    result_receiver = result_receiver'

  fun val apply(repo: Repo) =>
    _get_tags(repo)

  fun val _get_tags(repo: Repo) =>
    let action =
      Action(
        git.prog,
        recover
          ["-C"; repo.local.path; "show-ref"]
        end,
        git.env.vars)
    Runner.run(
      action,
      {(ar: ActionResult)(self = this) =>
        if ar.successful() then
          self._parse_tags(ar, repo)
        else
          result_receiver.report_error(repo, ar)
        end
      } iso)

  fun val _parse_tags(ar: ActionResult, repo: Repo) =>
    // ar.print_to(git.env.err)
    next(repo, parse_tags(ar.stdout))

  fun val parse_tags(stdout: String)
    : Array[String] iso^
  =>
    let tags = recover Array[String] end
    for line in stdout.split_by("\n").values() do
      // git.env.err.print("line: " + line)
      let matched: Array[String] =
        line.split_by(" refs/tags/")
      if matched.size() == 2 then
        try
          let tg: String = matched(1)?
          // TODO: consider stripping 'v' prefix on
          // semver tag
          tags.push(tg)
          // TODO: consider capturing the hash as well
        end
      end
    end
    consume tags

class val GitCheckoutRepo is RepoOperation
  """
  Checks out a specific revision from a git repo into
  a workspace directory.
  """
  let git: GitVCS
  let rev: String
  let next: RepoOperation
  let result_receiver: RepoOperationResultReceiver

  new val create(
    git': GitVCS,
    rev': String,
    result_receiver': RepoOperationResultReceiver,
    next': RepoOperation)
  =>
    git = git'
    rev = rev'
    next = next'
    result_receiver = result_receiver'

  fun val apply(repo: Repo) =>
    git.env.err.print(
      "git checking out @" + rev
        + " into " + repo.workspace.path)
    _reset_to_revision(repo)

  fun val _reset_to_revision(repo: Repo) =>
    // git reset --mixed <tree-ish>
    let action =
      Action(
        git.prog,
        recover
          [ "-C"; repo.local.path
            "reset"; "--mixed"; rev]
        end,
        git.env.vars)
    Runner.run(
      action,
      {(ar: ActionResult)(self = this) =>
        if ar.successful() then
          self._checkout_to_workspace(repo)
        else
          result_receiver.report_error(repo, ar)
        end
      } iso)

  fun val _checkout_to_workspace(repo: Repo) =>
    // Maybe: --recurse-submodules --quiet --verbose
    // git checkout-index -f -a --prefix=<path>
    if not repo.workspace.exists() then
      if not repo.workspace.mkdir(true) then
        result_receiver.report_error(
          repo,
          ActionResult.fail(
            "Unable to create directory '"
              + repo.workspace.path + "'"))
        // exit without advancing to the next operation
        return
      end
    end

    let action =
      Action(
        git.prog,
        recover
          [ "-C"; repo.local.path
            "checkout-index"
            "-f"; "-a"
            "--prefix=" + repo.workspace.path + "/"]
        end,
        git.env.vars)
    Runner.run(
      action,
      {(ar: ActionResult)(self = this) =>
        if ar.successful() then
          self._done(ar, repo)
        else
          result_receiver.report_error(repo, ar)
        end
      } iso)

  fun val _done(ar: ActionResult, repo: Repo) =>
    // TODO: check ar.exit_code == 0 before proceeding
    // ar.print_to(git.env.err)
    next(repo)
