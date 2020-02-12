use "files"
use "../util"

class val GitVCS is VCS
  """
  Git implementation of VCS
  """
  let env: Env
  let prog: Program

  new val create(env': Env) ? =>
    env = env'
    prog = Program(env, "git")?

  fun val sync_op(next: RepoOperation): RepoOperation =>
    GitSyncRepo(this, next)

  fun val tag_query_op(next: TagListReceiver): RepoOperation =>
    GitQueryTags(this, next)

  fun val checkout_op(rev: String, next: RepoOperation): RepoOperation =>
    GitCheckoutRepo(this, rev, next)

class val GitSyncRepo is RepoOperation
  let git: GitVCS
  let next: RepoOperation

  new val create(git': GitVCS, next': RepoOperation) =>
    git = git'
    next = next'

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

  fun val _log_err(ar: ActionResult) =>
    if ar.exit_code != 0 then
      ar.print_to(git.env.err)
    end

  fun val _clone(repo: Repo) =>
    let remote_uri = "https://" + repo.remote
    // Maybe: --recurse-submodules --quiet --verbose
    let action = Action(git.prog,
      recover ["clone"; "--no-checkout"; remote_uri; repo.local.path] end,
      git.env.vars)
    Runner.run(action, {(ar: ActionResult)(self=this) => 
      self._log_err(ar)
      if ar.exit_code != 0 then
        git.env.exitcode(ar.exit_code)
      end
      self._done(ar, repo)
    } iso)

  fun val _fetch(repo: Repo) =>
    let action = Action(git.prog,
      recover ["-C"; repo.local.path; "fetch"; "--tags"] end, git.env.vars)
    Runner.run(action, {(ar: ActionResult)(self=this) => 
      self._log_err(ar)
      if ar.exit_code != 0 then
        git.env.exitcode(ar.exit_code)
      end
      self._done(ar, repo)
    } iso)

  fun val _done(ar: ActionResult, repo: Repo) =>
    //ar.print_to(git.env.err)
    next(repo)

class val GitQueryTags is RepoOperation
  let git: GitVCS
  let next: TagListReceiver

  new val create(git': GitVCS, next': TagListReceiver) =>
    git = git'
    next = next'

  fun val apply(repo: Repo) =>
    _get_tags(repo)

  fun val _log_err(ar: ActionResult) =>
    if ar.exit_code != 0 then
      ar.print_to(git.env.err)
    end

  fun val _get_tags(repo: Repo) =>
    let action = Action(git.prog,
      recover ["-C"; repo.local.path; "show-ref"] end,
      git.env.vars)
    Runner.run(action, {(ar: ActionResult)(self=this) => 
      self._log_err(ar)
      if ar.exit_code != 0 then
        git.env.exitcode(ar.exit_code)
      end
      self._parse_tags(ar, repo)
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

  new val create(git': GitVCS, rev': String, next': RepoOperation) =>
    git = git'
    rev = rev'
    next = next'

  fun val apply(repo: Repo) =>
    git.env.err.print("git checking out @" + rev + " into " + repo.workspace.path)
    _reset_to_revision(repo)

  fun val _log_err(ar: ActionResult) =>
    if ar.exit_code != 0 then
      ar.print_to(git.env.err)
    end

  fun val _reset_to_revision(repo: Repo) =>
    //git reset --mixed <tree-ish>
    let action = Action(git.prog,
      recover ["-C"; repo.local.path; "reset"; "--mixed"; rev ] end,
      git.env.vars)
    Runner.run(action, {(ar: ActionResult)(self=this) =>
      self._log_err(ar)
      if ar.exit_code != 0 then
        git.env.exitcode(ar.exit_code)
      end
      self._checkout_to_workspace(repo)
    } iso)

  fun val _checkout_to_workspace(repo: Repo) =>
    // Maybe: --recurse-submodules --quiet --verbose
    //"git", "checkout-index", "-f", "-a", "--prefix="+path)
    let action = Action(git.prog,
      recover [
        "-C"; repo.local.path
        "checkout-index"
        "-f"; "-a"
        "--prefix=" + repo.workspace.path + "/"
      ] end,
      git.env.vars)
    Runner.run(action, {(ar: ActionResult)(self=this) => 
      self._log_err(ar)
      if ar.exit_code != 0 then
        git.env.exitcode(ar.exit_code)
      end
      self._done(ar, repo)
    } iso)

  fun val _done(ar: ActionResult, repo: Repo) =>
    // TODO: check ar.exit_code == 0 before proceeding
    //ar.print_to(git.env.err)
    next(repo)
