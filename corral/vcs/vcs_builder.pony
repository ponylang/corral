interface val VCSBuilder
  """
  Factory for creating VCS instances by name.
  """

  fun val apply(kind: String): VCS ?
  """
  Return a VCS instance for the given VCS kind.
  """

class val CorralVCSBuilder
  """
  Default VCSBuilder that creates real VCS instances.
  """
  let _env: Env

  new val create(env: Env) =>
    _env = env

  fun val apply(kind: String): VCS ? =>
    """
    Returns a VCS instance for any given VCS by name.
    """

    // TODO: this shouldn't be partial. That's a smell
    // that a constructor can be partial

    match kind
    | "git" => GitVCS(_env)?
    | "hg"  => HgVCS
    | "bzr" => BzrVCS
    | "svn" => SvnVCS
    else
      NoneVCS
    end
