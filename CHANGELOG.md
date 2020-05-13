# Change Log

All notable changes to Corral will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a CHANGELOG](http://keepachangelog.com/).

## [unreleased] - unreleased

### Fixed

- Bug introduced in Pony runtime by ponyc 0.35.0

### Added


### Changed

- Rename FreeBSD artifacts ([PR #111](https://github.com/ponylang/corral/pull/111))

## [0.3.4] - 2020-05-10

### Added

- Nothing. Fixing bad 0.3.2 release issue.

## [0.3.2] - 2020-05-10

### Added

- Add Windows Support ([PR #83](https://github.com/ponylang/corral/pull/83))
- Add FreeBSD support ([PR #91](https://github.com/ponylang/corral/pull/91))

## [0.3.1] - 2020-02-12

### Fixed

- Pass exit codes from Runners to early exit corral with same code ([PR #80](https://github.com/ponylang/corral/pull/80))

### Added

- Add macOS releases via Homebrew ([PR #74](https://github.com/ponylang/corral/pull/74))

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

