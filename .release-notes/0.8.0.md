## Switch supported MacOS version to Ventura

We've switched our supported MacOS version from Monterey to Ventura.

"Supported" means that all corral changes are tested on Ventura rather than Monterey and our pre-built corral distribution is built on Ventura.

## Add macOS on Intel as a fully supported platform

We've added macOS on Intel as a fully supported platform. This means that we test corral on macOS on Intel and provide nightly and release binaries of corral.

We plan to maintain macOS on Intel support for as long as we have access to a CI environment that supports it or until Apple stops supporting new macOS versions on Intel CPUs.

## Releases are no longer available for FreeBSD

We no longer do nightly or release builds for FreeBSD. You can still build corral from source on FreeBSD.

## Temporarily drop macOS on Apple Silicon as fully supported platform

We currently don't have a CI environment for macOS on Apple Silicon. This means that we can't test corral on macOS for Apple Silicon nor can we provide nightly and release binaries of corral for Apple Silicon computers.

We are "temporarily" dropping support for corral on macOS on Apple Silicon. GitHub Actions is supposed to be adding support for Apple Silicon in Q4 of 2023. When Apple Silicon macOS runners are added, we'll elevate macOS on Apple Silicon back to a fully supported platform.

In the meantime, we have CI for macOS on Intel which should provide reasonable assurance that we don't accidentally break macOS related functionality.

