class val VCSBuilder
  let _env: Env

  new val create(env: Env) =>
    _env = env

  fun val apply(kind: String): VCS ? =>
    """
    Returns a VCS instance for any given VCS by name.
    """

    // TODO: this shouldn't be partial. That's a smell that
    // a constructor can be partial

    match kind
    | "git" => GitVCS(_env)?
    | "hg"  => HgVCS
    | "bzr" => BzrVCS
    | "svn" => SvnVCS
    else
      NoneVCS
    end
