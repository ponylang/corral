use "files"
use "../util"
use "process"

class val GitVCS is VCS
  """
  Git implementation of VCS
  """
  let env: Env
  let prog: Program

  new val create(env': Env) ? =>
    env = env'
    prog = Program(env, ifdef windows then "git.exe" else "git" end)?

  fun val sync_op(resultReceiver: RepoOperationResultReceiver, next: RepoOperation): RepoOperation =>
    GitSyncRepo(this, resultReceiver, next)

  fun val tag_query_op(resultReceiver: RepoOperationResultReceiver, next: TagListReceiver): RepoOperation =>
    GitQueryTags(this, resultReceiver, next)

  fun val checkout_op(rev: String, resultReceiver: RepoOperationResultReceiver, next: RepoOperation): RepoOperation =>
    GitCheckoutRepo(this, rev, resultReceiver, next)

class val GitSyncRepo is RepoOperation
  let git: GitVCS
  let next: RepoOperation
  let resultReceiver: RepoOperationResultReceiver

  new val create(git': GitVCS, resultReceiver': RepoOperationResultReceiver, next': RepoOperation) =>
    git = git'
    next = next'
    resultReceiver = resultReceiver'

  fun val apply(repo: Repo) =>
    if repo.is_remote() then
      let exists = try repo.local.join(".git")?.exists() else false end
      if not exists then
        git.env.err.print("git cloning " + repo.remote + " into " + repo.local.path)
        _clone(repo)
      else
        git.env.err.print("git fetching " + repo.remote + " into " + repo.local.path)
        _fetch(repo)
      end
    else
      next(repo) // local repos don't need syncing
    end

  fun val _clone(repo: Repo) =>
    let remote_uri = "https://" + repo.remote
    // Maybe: --recurse-submodules --quiet --verbose
    let action = Action(git.prog,
      recover ["clone"; "--no-checkout"; remote_uri; repo.local.path] end,
      git.env.vars)
    Runner.run(action, {(ar: ActionResult)(self=this) =>
      //ar.print_to(git.env.err)
      if ar.successful() then
        next(repo)
      else
        resultReceiver.reportError(repo, ar)
      end
    } iso)

  fun val _fetch(repo: Repo) =>
    let action = Action(git.prog,
      recover ["-C"; repo.local.path; "fetch"; "--tags"] end, git.env.vars)
    Runner.run(action, {(ar: ActionResult)(self=this) =>
      //ar.print_to(git.env.err)
      if ar.successful() then
        next(repo)
      else
        resultReceiver.reportError(repo, ar)
      end
    } iso)


class val GitQueryTags is RepoOperation
  let git: GitVCS
  let next: TagListReceiver
  let resultReceiver : RepoOperationResultReceiver

  new val create(git': GitVCS, resultReceiver': RepoOperationResultReceiver, next': TagListReceiver) =>
    git = git'
    next = next'
    resultReceiver = resultReceiver'

  fun val apply(repo: Repo) =>
    _get_tags(repo)

  fun val _get_tags(repo: Repo) =>
    let action = Action(git.prog,
      recover ["-C"; repo.local.path; "show-ref"] end,
      git.env.vars)
    Runner.run(action, {(ar: ActionResult)(self=this) =>
      if ar.successful() then
        self._parse_tags(ar, repo)
      else
        resultReceiver.reportError(repo, ar)
      end
    } iso)

  fun val _parse_tags(ar: ActionResult, repo: Repo) =>
    //ar.print_to(git.env.err)
    next(repo, parse_tags(ar.stdout))

  fun val parse_tags(stdout: String): Array[String] iso^ =>
    let tags = recover Array[String] end
    for line in stdout.split_by("\n").values() do
      //git.env.err.print("line: " + line)
      let matched: Array[String] = line.split_by(" refs/tags/")
      if matched.size() == 2 then
        try
          let tg: String = matched(1)?
          // TODO: consider stripping 'v' prefix on semver tag
          tags.push(tg)
          //git.env.err.print("tag: " + tg)
          // TODO: consider capturing the hash as well
        end
      end
    end
    consume tags

class val GitCheckoutRepo is RepoOperation
  let git: GitVCS
  let rev: String
  let next: RepoOperation
  let resultReceiver: RepoOperationResultReceiver

  new val create(git': GitVCS, rev': String, resultReceiver': RepoOperationResultReceiver, next': RepoOperation) =>
    git = git'
    rev = rev'
    next = next'
    resultReceiver = resultReceiver'

  fun val apply(repo: Repo) =>
    git.env.err.print("git checking out @" + rev + " into " + repo.workspace.path)
    _reset_to_revision(repo)

  fun val _reset_to_revision(repo: Repo) =>
    //git reset --mixed <tree-ish>
    let action = Action(git.prog,
      recover ["-C"; repo.local.path; "reset"; "--mixed"; rev ] end,
      git.env.vars)
    Runner.run(action, {(ar: ActionResult)(self=this) =>
      if ar.successful() then
        self._checkout_to_workspace(repo)
      else
        resultReceiver.reportError(repo, ar)
      end
    } iso)

  fun val _checkout_to_workspace(repo: Repo) =>
    // Maybe: --recurse-submodules --quiet --verbose
    //"git", "checkout-index", "-f", "-a", "--prefix="+path)
    if not repo.workspace.exists() then
      if not repo.workspace.mkdir(true) then
        resultReceiver.reportError(repo, ActionResult.fail(
          "Unable to create directory '" + repo.workspace.path + "'"
        ))
        // exit without advancing to the next operation
        return
      end
    end

    let action = Action(git.prog,
      recover [
        "-C"; repo.local.path
        "checkout-index"
        "-f"; "-a"
        "--prefix=" + repo.workspace.path + "/"
      ] end,
      git.env.vars)
    Runner.run(action, {(ar: ActionResult)(self=this) =>
      if ar.successful() then
        self._done(ar, repo)
      else
        resultReceiver.reportError(repo, ar)
      end
    } iso)

  fun val _done(ar: ActionResult, repo: Repo) =>
    // TODO: check ar.exit_code == 0 before proceeding
    //ar.print_to(git.env.err)
    next(repo)
