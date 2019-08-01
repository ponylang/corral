# Corral

Pony dependency management command-line tool.

For a discussion of the requirements and design work behind Corral, see:

- [Pony Package Dependency Management](https://docs.google.com/document/d/1c7puEQLks3X1wpabuXxox8Qi1HUhfSwhobUvmVE56Rw/edit#)

Corral builds on the work done in pony-stable, and adds some new things:

- Uses Pony cli package for command line parsing.
- Easy extensibility of VCS and Commands.
- Supports semver version constraints on deps.
- Supports transitive deps.
- Supports revision locking on deps, using a lock.json file.
- Uses the Pony process package for running external tools like Git and ponyc.
- Separate shared repo pool from per-project deps tree.

## Status

[![CircleCI](https://circleci.com/gh/ponylang/corral.svg?style=svg)](https://circleci.com/gh/ponylang/corral)

Corral is alpha level software. We advise you use [stable](https://github.com/ponylang/pony-stable) for your dependency management needs. We are looking for help building out Corral and would love if you help out with any of the [open issues](https://github.com/ponylang/corral/issues).

