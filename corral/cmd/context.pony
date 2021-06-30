use "files"
use "logger"

class val Context
  """
  Context holds options and environment for all commands.
  """
  let env: Env
  let log: Logger[String]
  let uout: Logger[String]
  let nothing: Bool
  let repo_cache: FilePath

  new val create(
    env': Env,
    log': Logger[String],
    uout': Logger[String],
    nothing': Bool,
    repo_cache': FilePath)
  =>
    env = env'
    log = log'
    uout = uout'
    nothing = nothing'
    repo_cache = repo_cache'
