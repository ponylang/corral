# Change Log

All notable changes to Corral will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a CHANGELOG](http://keepachangelog.com/).

## [unreleased] - unreleased

### Fixed

- Fix `corral run` should work if there is no corral.json ([PR #57](https://github.com/ponylang/corral/pull/57))
- Fix `corral run` only looking for binaries on $PATH ([PR #56](https://github.com/ponylang/corral/pull/56))
- ([PR #60](https://github.com/ponylang/corral/pull/60))
  - #10: Added integration tests
  - #23: Updated '--directory' to '--bundle_dir', resolved it early, and made sure other dirs are based on it.
  - #25: Ensured that fetched bundles are placed in the corral correctly.
  - #29: Verified ProcessMonitor use is correct.

### Added

- Add --path flag ([PR #53](https://github.com/ponylang/corral/pull/53))

### Changed


## [0.2.0] - 2019-11-16

### Changed

- Rename bundle.json to corral.json ([PR #52](https://github.com/ponylang/corral/pull/52))

## [0.1.0] - 2019-11-11

### Added

- Initial alpha release
