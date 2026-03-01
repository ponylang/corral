use "files"
use "../logger"
use "../bundle"
use "debug"
use "../vcs"

primitive Executor
  """
  Executor handles all the work of setting up the working environment and
  running commands. It resolves directories, creates the Project and Context
  objects, and then runs the given command.
  """
  fun execute(
    command: CmdType,
    env: Env,
    log: Logger[String],
    uout: Logger[String],
    nothing: Bool,
    quiet: Bool,
    bundle_dir_arg: String)
    // TODO: add when we have the cli flag: repo_cache_str: String
  =>
    let auth = FileAuth(env.root)

    // Resolve the bundle dir arg into a clean path string
    let bundle_dir_str =
      if bundle_dir_arg == "" then
        Path.cwd()
      else
        Path.clean(bundle_dir_arg)
      end

    // Search or resolve the dir path string into a FilePath if possible
    let bundle_dir_maybe =
      if bundle_dir_arg == "" then
        BundleDir.find(auth, bundle_dir_str, log)
      else
        BundleDir.resolve(auth, bundle_dir_str, log)
      end

    // Bail if the command requires bundle files but none were found
    if command.requires_bundle() and (bundle_dir_maybe is None) then
      if bundle_dir_arg == "" then
        uout(Error) and uout.log("Error: required bundle files not found in or above current directory: " + bundle_dir_str)
      else
        uout(Error) and uout.log("Error: required bundle files not found in given directory: " + bundle_dir_str)
      end
      env.exitcode(1)
      return
    end

    // Bail if the command requires there be no bundle files, but one was found
    // or, the directory is unavailable.
    if command.requires_no_bundle() then
      if not (bundle_dir_maybe is None) then
        if bundle_dir_arg == "" then
          uout(Error) and uout.log("Error: unexpected bundle files found in or above current directory: " + bundle_dir_str)
        else
          uout(Error) and uout.log("Error: unexpected bundle files found in given directory: " + bundle_dir_str)
        end
        env.exitcode(1)
        return
      else
        try
          let fp = FilePath(auth, bundle_dir_str)
          if not FileInfo(fp)?.directory then error end
        else
          uout(Error) and uout.log("Error: could not access directory for new bundle: " + bundle_dir_str)
          env.exitcode(1)
          return
        end
      end
    end

    // Finally, make a FilePath for the bundle dir
    let bundle_dir: FilePath =
      match \exhaustive\ bundle_dir_maybe
      | let fp: FilePath => fp
      | None => FilePath(auth, bundle_dir_str)  // placeholder for create
      end

    // Make a FilePath for the repo cache dir
    let repo_cache = try
        // TODO: move default repo_cache to user home and add flag
        // https://github.com/ponylang/corral/issues/28
        bundle_dir.join("_repos")?
      else
        log(Error) and log.log("Internal error: could not access required directories")
        env.exitcode(2)
        return
      end

    let context = Context(env, log, uout, nothing, quiet, repo_cache)
    let project = Project(auth, log, bundle_dir)
    let vcs_builder = CorralVCSBuilder(env)
    command(context, project, vcs_builder, NoOpResultReceiver)
