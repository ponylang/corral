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

  fun val begin(ws: WorkSpec) =>
    let exists = try ws.local.join(".git")?.exists() else false end
    if not exists then
      env.out.print("Cloning " + ws.remote + " into " + ws.local.path)
      _clone(ws)
    else
      env.out.print("Fetching " + ws.remote + " into " + ws.local.path)
      _fetch(ws)
    end

  fun val _clone(ws: WorkSpec) =>
    // Maybe: --recurse-submodules --quiet --verbose
    let cmd = Cmd(git,
      recover ["clone"; "--no-checkout"; ws.remote; ws.local.path] end,
      env.vars())
    Runner.run(cmd, {(cr: CmdResult)(self=this) => self._done(cr, ws)} iso)

  fun val _fetch(ws: WorkSpec) =>
    let cmd = Cmd(git,
      recover ["-C"; ws.local.path; "fetch"; "--tags"] end, env.vars())
    Runner.run(cmd, {(cr: CmdResult)(self=this) => self._done(cr, ws)} iso)

  fun val _done(cr: CmdResult, ws: WorkSpec) =>
    cr.print_to(env.out)
    next.begin(ws)

class val GitCheckoutRepo is RepoOperation
  let env: Env
  let git: Binary
  let next: RepoOperation

  new val create(env': Env, next': RepoOperation) ? =>
    env = env'
    git = Binary.on_path(env, "git")?
    next = next'

  fun val begin(ws: WorkSpec) =>
    env.out.print("Checking out @" + ws.version + " into " + ws.workspace.path)
    _reset_to_version(ws)

  fun val _reset_to_version(ws: WorkSpec) =>
    //git reset --mixed <tree-ish>
    let cmd = Cmd(git,
      recover ["-C"; ws.local.path; "reset"; "--mixed"; ws.version ] end,
      env.vars())
    Runner.run(cmd,
      {(cr: CmdResult)(self=this) => self._checkout_to_workspace(ws)} iso)

  fun val _checkout_to_workspace(ws: WorkSpec) =>
    // Maybe: --recurse-submodules --quiet --verbose
    //"git", "checkout-index", "-f", "-a", "--prefix="+path)
    let cmd = Cmd(git,
      recover [
        "-C"; ws.local.path
        "checkout-index"
        "-f"; "-a"
        "--prefix=" + ws.workspace.path + "/"
      ] end,
      env.vars())
    Runner.run(cmd,
      {(cr: CmdResult)(self=this) => self._done(cr, ws)} iso)

  fun val _done(cr: CmdResult, ws: WorkSpec) =>
    cr.print_to(env.out)
    next.begin(ws)

class val GitQueryTags is RepoOperation
  let env: Env
  let git: Binary
  let next: TagListReceiver

  new val create(env': Env, next': TagListReceiver) ? =>
    env = env'
    git = Binary.on_path(env, "git")?
    next = next'

  fun val begin(ws: WorkSpec) =>
    _get_tags(ws)

  fun val _get_tags(ws: WorkSpec) =>
    let cmd = Cmd(git,
      recover ["-C"; ws.local.path; "show-ref"] end,
      env.vars())
    Runner.run(cmd,
      {(cr: CmdResult)(self=this) => self._parse_tags(cr, ws)} iso)

  fun val _parse_tags(cr: CmdResult, ws: WorkSpec) =>
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
