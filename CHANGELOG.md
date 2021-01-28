# Change Log

All notable changes to Corral will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a CHANGELOG](http://keepachangelog.com/).

## [unreleased] - unreleased

### Fixed

- Run PostFetchScript after fetch completion ([PR #160](https://github.com/ponylang/corral/pull/160))
- Don't remove empty fields from configuration ([PR #164](https://github.com/ponylang/corral/pull/164))

### Added


### Changed


## [0.4.0] - 2020-08-22

### Added

- Add the ability to run a script after fetching or updating a dependency ([PR #151](https://github.com/ponylang/corral/pull/151))

### Changed

- Make corral less verbose ([PR #137](https://github.com/ponylang/corral/pull/137))
- Update Dockerfile to use Alpine 3.12 ([PR #153](https://github.com/ponylang/corral/pull/153))
- Change status to beta ([PR #154](https://github.com/ponylang/corral/pull/154))

## [0.3.6] - 2020-06-07

### Fixed

- Remove extraneous CR in outputs on Windows ([PR #115](https://github.com/ponylang/corral/pull/115))
- Use correct path separator in PONYPATH on Windows ([PR #117](https://github.com/ponylang/corral/pull/117))
- Don't update dependencies more than once ([PR #132](https://github.com/ponylang/corral/pull/132))

## [0.3.5] - 2020-05-13

### Fixed

- Bug introduced in Pony runtime by ponyc 0.35.0

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

