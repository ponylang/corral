# Change Log

All notable changes to Corral will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a CHANGELOG](http://keepachangelog.com/).

## [unreleased] - unreleased

### Fixed


### Added


### Changed


## [0.5.7] - 2022-02-26

### Fixed

- Update to work with object capabilities changes in Pony 0.49.0 ([PR #219](https://github.com/ponylang/corral/pull/219))
- Update to address PonyTest package being renamed ([PR #220](https://github.com/ponylang/corral/pull/220))

## [0.5.6] - 2022-02-13

### Fixed

- Improved error messages for `corral run` ([PR #216](https://github.com/ponylang/corral/pull/216))
- Fix resolving relative paths with `corral run` ([PR #216](https://github.com/ponylang/corral/pull/216))

## [0.5.5] - 2022-02-10

### Fixed

- Avoid using backslashes in locator paths ([PR #215](https://github.com/ponylang/corral/pull/215))

### Added

- Support for using ponyup on Windows ([PR #213](https://github.com/ponylang/corral/pull/213))

## [0.5.4] - 2021-10-05

### Changed

- Update to compile with Pony 0.44.0 ([PR #200](https://github.com/ponylang/corral/pull/200))

## [0.5.3] - 2021-07-29

### Fixed

- Don't error out if a transitive dependency doesn't have a corral.json ([PR #199](https://github.com/ponylang/corral/pull/199))

## [0.5.2] - 2021-07-28

### Fixed

- Fix bug that prevented lock.json from being populated ([PR #193](https://github.com/ponylang/corral/pull/193))
- Fixed bug where `corral update` would result in incorrect code in the corral ([PR #194](https://github.com/ponylang/corral/pull/194))
- Fixed bug where checked out code not matching revision ([PR #198](https://github.com/ponylang/corral/pull/198))

## [0.5.1] - 2021-06-21

### Changed

- Switch supported FreeBSD to 13.0 ([PR #183](https://github.com/ponylang/corral/pull/183))

## [0.5.0] - 2021-02-27

### Changed

- Switch default branch to use when none is supplied to 'main` ([PR #171](https://github.com/ponylang/corral/pull/171))
- Switch supported FreeBSD to 12.2 ([PR #173](https://github.com/ponylang/corral/pull/173))

## [0.4.2] - 2021-02-07

### Added

- Add new `packages` field to corral.json ([PR #167](https://github.com/ponylang/corral/pull/167))

## [0.4.1] - 2021-01-28

### Fixed

- Run PostFetchScript after fetch completion ([PR #160](https://github.com/ponylang/corral/pull/160))
- Don't remove empty fields from configuration ([PR #164](https://github.com/ponylang/corral/pull/164))

### Added

- Add documentation_url to `info` section of `corral.json` ([PR #166](https://github.com/ponylang/corral/pull/166))

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

