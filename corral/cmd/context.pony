use "files"
use "../util"

class val Context
  """
  Contains options and environment for all commands.
  """
  let env: Env
  let log: Log
  let quiet: Bool
  let nothing: Bool
  let bundle_dir: FilePath
  let repo_cache: FilePath

  new val create(env': Env, log': Log,
    quiet': Bool, nothing': Bool,
    bundle_dir': FilePath, repo_cache': FilePath)
  =>
    env = env'
    log = log'
    quiet = quiet'
    nothing = nothing'
    bundle_dir = bundle_dir'
    repo_cache = repo_cache'
