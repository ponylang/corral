## Add arm64 Linux as a supported platform

We are adding arm64 Linux as a supported platform for Corral. This means that we will be providing pre-built binaries for arm64 Linux in our releases, and we will be testing Corral on this platform to ensure compatibility.

## Add Windows on arm64 as a fully supported platform

We've added Windows on Arm64 as a fully supported platform. This means that we test corral on Windows on Arm64 and provide nightly and release binaries of corral.

## Stop having a base image

Previously we were using Alpine 3.20 as the base image for the corral container image. We've switched to using the `scratch` image instead. This means that the container image is now much smaller and only contains the `corral` binary.
## Handle PowerShell execution policy errors better

On Windows, if the PowerShell execution policy prevents running a post-update script, the child process exits with zero, but an error message is printed to standard error.  Corral will now check for this error message and print the error message, instead of erroneously continuing as if the script succeeded.

