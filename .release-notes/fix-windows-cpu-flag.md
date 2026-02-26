## Fix intermittent corral Windows build failures

The Windows build was not setting a minimum CPU target, so the compiled binary could contain instructions specific to the build machine's CPU. If your machine didn't support all the same instructions, corral would crash on startup. We now set a minimum CPU target on Windows, matching what the Linux and macOS builds already do.
