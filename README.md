# Corral

Pony dependency management command-line tool.

## Status

[![Actions Status](https://github.com/ponylang/corral/workflows/vs-ponyc-latest/badge.svg)](https://github.com/ponylang/corral/actions)

Corral is alpha level software. We advise you use [stable](https://github.com/ponylang/pony-stable) for your dependency management needs. We are looking for help building out Corral and would love if you help out with any of the [open issues](https://github.com/ponylang/corral/issues).

## About Corral

Corral is a dependency management tool for [Pony](https://www.ponylang.io). Our goal with Corral is to start from scratch and come up with a full featured replacement for [stable](https://github.com/ponylang/pony-stable), the current dependency management tool for Pony. Corral builds on the work done in stable and adds some new things:

- Uses Pony cli package for command line parsing.
- Easy extensibility of VCS and Commands.
- Supports semver version constraints on deps.
- Supports transitive deps.
- Supports revision locking on deps, using a lock.json file.
- Uses the Pony process package for running external tools like Git and ponyc.
- Separate shared repo pool from per-project deps tree.

## Installation

The following command will download the latest release of `corral` and install it to `~/.pony/ponyup/bin` by default. This requires `ponyup`, our toolchain multiplexer, to be installed. If you don't have it installed, please follow the [instructions](https://github.com/ponylang/ponyup#installing-ponyup).

```bash
ponyup update corral release
```

## Design

See [Corral Design](doc/design.md) for more details about the design of Corral. Ongoing questions and notes for future work can be found in [Questions / Notes](doc/questions_notes.md)

## Background

Check out [Pony Package Dependency Management](doc/package_dependency_management.md) for a discussion of the research and requirements work behind Corral.
