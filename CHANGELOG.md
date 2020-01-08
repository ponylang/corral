# Change Log

All notable changes to Corral will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a CHANGELOG](http://keepachangelog.com/).

## [unreleased] - unreleased

### Fixed


### Added

- Add macOS releases via Homebrew ([PR #74](https://github.com/ponylang/corral/pull/74))
- Add '--repo_cache_dir' to allow specification of the repo cache directory. ([PR #79](https://github.com/ponylang/corral/pull/79))

### Changed

- The default repo cache directory has been moved from <bundle-dir>/_repos to '/corral/repos' under the platform-specific user data directory. E.g. `~/.local/share/corral/repos/` on Unix and macOS. ([PR #79](https://github.com/ponylang/corral/pull/79))

## [0.3.0] - 2019-12-21

### Fixed

- Fix `corral run` should work if there is no corral.json ([PR #57](https://github.com/ponylang/corral/pull/57))
- Fix `corral run` only looking for binaries on $PATH ([PR #56](https://github.com/ponylang/corral/pull/56))

### Added

- Add --path flag ([PR #53](https://github.com/ponylang/corral/pull/53))

### Changed

- Update '--directory' to '--bundle_dir', resolve it early, and ensure other dirs are based on it. ([PR #60](https://github.com/ponylang/corral/pull/60))

## [0.2.0] - 2019-11-16

### Changed

- Rename bundle.json to corral.json ([PR #52](https://github.com/ponylang/corral/pull/52))

## [0.1.0] - 2019-11-11

### Added

- Initial alpha release
