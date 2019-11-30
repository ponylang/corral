use "files"
use "../util"

class val Context
  """
  Context holds options and environment for all commands.
  """
  let env: Env
  let log: Log
  let uout: Log
  let nothing: Bool
  let repo_cache: FilePath

  new val create(
    env': Env,
    log': Log,
    uout': Log,
    nothing': Bool,
    repo_cache': FilePath)
  =>
    env = env'
    log = log'
    uout = uout'
    nothing = nothing'
    repo_cache = repo_cache'
