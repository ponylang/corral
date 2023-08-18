## Temporarily drop macOS on Apple Silicon as fully supported platform

We currently don't have a CI environment for macOS on Apple Silicon. This means that we can't test corral on macOS for Apple Silicon nor can we provide nightly and release binaries of corral for Apple Silicon computers.

We are "temporarily" dropping support for corral on macOS on Apple Silicon. GitHub Actions is supposed to be adding support for Apple Silicon in Q4 of 2023. When Apple Silicon macOS runners are added, we'll elevate macOS on Apple Silicon back to a fully supported platform.

In the meantime, we have CI for macOS on Intel which should provide reasonable assurance that we don't accidentally break macOS related functionality.
