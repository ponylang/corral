use "files"
use "../regex"
use "../util"

class val GitVCS is VCS
  """
  Git implementation of VCS
  """
  let env: Env
  let prog: Program

  new val create(env': Env) ? =>
    env = env'
    prog = Program.on_path(env, "git")?

  fun val fetch_op(ver: String): RepoOperation =>
    """A fetch for Git is a Sync followed by a Checkout."""
    GitSyncRepo(this, GitCheckoutRepo(this, ver, NoOperation))

  fun val update_op(rcv: TagListReceiver): RepoOperation =>
    """An update for Git is a Sync followed by a Tag Query."""
    GitSyncRepo(this, GitQueryTags(this, rcv))

  fun val tag_query_op(rcv: TagListReceiver): RepoOperation =>
    """A query for Git is a Tag Query."""
    GitQueryTags(this, rcv)

class val GitSyncRepo is RepoOperation
  let git: GitVCS
  let next: RepoOperation

  new val create(git': GitVCS, next': RepoOperation) =>
    git = git'
    next = next'

  fun val apply(repo: Repo) =>
    let exists = try repo.local.join(".git")?.exists() else false end
    if not exists then
      git.env.err.print("git cloning " + repo.remote + " into " + repo.local.path)
      _clone(repo)
    else
      git.env.err.print("git fetching " + repo.remote + " into " + repo.local.path)
      _fetch(repo)
    end

  fun val _clone(repo: Repo) =>
    // Maybe: --recurse-submodules --quiet --verbose
    let action = Action(git.prog,
      recover ["clone"; "--no-checkout"; repo.remote; repo.local.path] end,
      git.env.vars)
    Runner.run(action, {(ar: ActionResult)(self=this) => self._done(ar, repo)} iso)

  fun val _fetch(repo: Repo) =>
    let action = Action(git.prog,
      recover ["-C"; repo.local.path; "fetch"; "--tags"] end, git.env.vars)
    Runner.run(action, {(ar: ActionResult)(self=this) => self._done(ar, repo)} iso)

  fun val _done(ar: ActionResult, repo: Repo) =>
    //ar.print_to(git.env.err)
    next(repo)

class val GitCheckoutRepo is RepoOperation
  let git: GitVCS
  let ver: String
  let next: RepoOperation

  new val create(git': GitVCS, ver': String, next': RepoOperation) =>
    git = git'
    ver = ver'
    next = next'

  fun val apply(repo: Repo) =>
    git.env.err.print("git checking out @" + ver + " into " + repo.workspace.path)
    _reset_to_version(repo)

  fun val _reset_to_version(repo: Repo) =>
    //git reset --mixed <tree-ish>
    let action = Action(git.prog,
      recover ["-C"; repo.local.path; "reset"; "--mixed"; ver ] end,
      git.env.vars)
    Runner.run(action,
      {(ar: ActionResult)(self=this) => self._checkout_to_workspace(repo)} iso)

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
    Runner.run(action,
      {(ar: ActionResult)(self=this) => self._done(ar, repo)} iso)

  fun val _done(ar: ActionResult, repo: Repo) =>
    // TODO: check ar.exit_code == 0 before proceeding
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

  fun val _get_tags(repo: Repo) =>
    let action = Action(git.prog,
      recover ["-C"; repo.local.path; "show-ref"] end,
      git.env.vars)
    Runner.run(action,
      {(ar: ActionResult)(self=this) => self._parse_tags(ar, repo)} iso)

  fun val _parse_tags(ar: ActionResult, repo: Repo) =>
    //ar.print_to(git.env.err)
    let tags = recover Array[String] end
    try
      let re = Regex("""(\w+)(?: refs/tags/)(\S+)""")?
      for line in ar.stdout.split_by("\n").values() do
        //git.env.err.print("line: " + line)
        try
          let matched = re(line)?
          if matched.size() >= 2 then
            let tg: String = matched(2)?
            // TODO: consider stripping 'v' prefix on semver tag
            tags.push(tg)
            //git.env.err.print("tag: " + tg)
            // TODO: consider capturing the hash as well
          end
        end
      end
    end
    next(consume tags)
