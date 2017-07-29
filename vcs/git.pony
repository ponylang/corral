use "files"
use "regex"

primitive GitOps is VcsOps
  fun tag fetch_op(env: Env): RepoOperation ? =>
    GitSyncRepo(env, GitCheckoutRepo(env, NoOperation)?)?
  fun tag tag_query_op(env: Env, rcv: TagListReceiver): RepoOperation ? =>
    GitQueryTags(env, rcv)?

class val GitSyncRepo is RepoOperation
  let env: Env
  let git: Binary
  let next: RepoOperation

  new val create(env': Env, next': RepoOperation) ? =>
    env = env'
    git = Binary.on_path(env, "git")?
    next = next'

  fun val begin(di: DepInfo) =>
    let exists = try di.local.join(".git")?.exists() else false end
    if not exists then
      env.out.print("Cloning " + di.remote + " into " + di.local.path)
      _clone(di)
    else
      env.out.print("Fetching " + di.remote + " into " + di.local.path)
      _fetch(di)
    end

  fun val _clone(di: DepInfo) =>
    // Maybe: --recurse-submodules --quiet --verbose
    let cmd = Cmd(git,
      recover ["clone"; "--no-checkout"; di.remote; di.local.path] end,
      env.vars())
    Runner.run(cmd, {(cr: CmdResult)(self=this) => self._done(cr, di)} iso)

  fun val _fetch(di: DepInfo) =>
    let cmd = Cmd(git,
      recover ["-C"; di.local.path; "fetch"; "--tags"] end, env.vars())
    Runner.run(cmd, {(cr: CmdResult)(self=this) => self._done(cr, di)} iso)

  fun val _done(cr: CmdResult, di: DepInfo) =>
    cr.print_to(env.out)
    next.begin(di)

class val GitCheckoutRepo is RepoOperation
  let env: Env
  let git: Binary
  let next: RepoOperation

  new val create(env': Env, next': RepoOperation) ? =>
    env = env'
    git = Binary.on_path(env, "git")?
    next = next'

  fun val begin(di: DepInfo) =>
    env.out.print("Checking out @" + di.version + " into " + di.workspace.path)
    _reset_to_version(di)

  fun val _reset_to_version(di: DepInfo) =>
    //git reset --mixed <tree-ish>
    let cmd = Cmd(git,
      recover ["-C"; di.local.path; "reset"; "--mixed"; di.version ] end,
      env.vars())
    Runner.run(cmd,
      {(cr: CmdResult)(self=this) => self._checkout_to_workspace(di)} iso)

  fun val _checkout_to_workspace(di: DepInfo) =>
    // Maybe: --recurse-submodules --quiet --verbose
    //"git", "checkout-index", "-f", "-a", "--prefix="+path)
    let cmd = Cmd(git,
      recover [
        "-C"; di.local.path
        "checkout-index"
        "-f"; "-a"
        "--prefix=" + di.workspace.path + "/"
      ] end,
      env.vars())
    Runner.run(cmd,
      {(cr: CmdResult)(self=this) => self._done(cr, di)} iso)

  fun val _done(cr: CmdResult, di: DepInfo) =>
    cr.print_to(env.out)
    next.begin(di)

class val GitQueryTags is RepoOperation
  let env: Env
  let git: Binary
  let next: TagListReceiver

  new val create(env': Env, next': TagListReceiver) ? =>
    env = env'
    git = Binary.on_path(env, "git")?
    next = next'

  fun val begin(di: DepInfo) =>
    _get_tags(di)

  fun val _get_tags(di: DepInfo) =>
    let cmd = Cmd(git,
      recover ["-C"; di.local.path; "show-ref"] end,
      env.vars())
    Runner.run(cmd,
      {(cr: CmdResult)(self=this) => self._parse_tags(cr, di)} iso)

  fun val _parse_tags(cr: CmdResult, di: DepInfo) =>
    cr.print_to(env.out)
    let tags = recover Array[String] end
    try
      let re = Regex("""(\w+)(?: refs/tags/)(\S+)""")?
      for line in cr.stdout.split_by("\n").values() do
        //env.out.print("line: " + line)
        try
          let matched = re(line)?
          if matched.size() >= 2 then
            let tg: String = matched(2)?
            tags.push(tg)
            env.out.print("tag: " + tg)
          end
        end
      end
    end
    next.receive(consume tags)
