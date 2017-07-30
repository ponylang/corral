use "files"
use "logger"

class Context
  """ Contains options and environment for all commands"""
  let env: Env
  let log: Logger[String]
  let quiet: Bool
  let nothing: Bool
  let repo_cache: FilePath
  let corral_base: FilePath

  new create(env': Env,
    log': Logger[String],
    quiet': Bool, nothing': Bool, repo_cache': String, corral_base': String) ?
  =>
    env = env'
    log = log'
    quiet = quiet'
    nothing = nothing'
    repo_cache = FilePath(env.root as AmbientAuth, repo_cache')?
    corral_base = FilePath(env.root as AmbientAuth, corral_base')?
