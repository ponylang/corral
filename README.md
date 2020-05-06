# Corral

A Pony dependency management command-line tool.

Keep your ponies in a corral to prevent them from getting lost.

<a href="http://clipart-library.com/clipart/488719.htm">
  <img src="http://clipart-library.com/image_gallery/488719.png" width="346" height="161" />
</a>

## Status

[![Actions Status](https://github.com/ponylang/corral/workflows/vs-ponyc-latest/badge.svg)](https://github.com/ponylang/corral/actions)

Corral is alpha level software. We advise you use [stable](https://github.com/ponylang/pony-stable) for your dependency management needs. We are looking for help building out Corral and would love if you help out with any of the [open issues](https://github.com/ponylang/corral/issues).

## About Corral

Corral is a dependency management tool for [Pony](https://www.ponylang.io). Our goal with Corral is to start from scratch and come up with a full featured replacement for [stable](https://github.com/ponylang/pony-stable), the current dependency management tool for Pony. Corral builds on the work done in stable and adds some new things:

* Uses Pony cli package for command line parsing.
* Provides extensibility for VCS and Commands.
* Supports semver version constraints on dependencies.
* Supports transitive dependencies.
* Supports revision locking on dependencies using a lock.json file.
* Uses the Pony process package for running external tools like Git and ponyc.
* Uses a distinct shared VCS repo pool from per-project dependency workspace tree.

### Design

See [Corral Design](doc/design.md) for more details about the design of Corral. Ongoing questions and notes for future work can be found in [Questions / Notes](doc/questions_notes.md)

### Background

Check out [Pony Package Dependency Management](doc/package_dependency_management.md) for a discussion of the research and requirements work behind Corral.

## Installation

Use [ponyup](https://github.com/ponylang/ponyup) to install corral.

The following command will download the latest release of `corral` and install it to `~/.pony/ponyup/bin` by default. This requires `ponyup`, our toolchain multiplexer, to be installed. If you don't have it installed, please follow the [instructions](https://github.com/ponylang/ponyup#installing-ponyup).

```bash
ponyup update corral release
```

## Building From Source

You will need `ponyc` in your PATH.

### From Source (Unix/Linux)

```bash
git clone https://github.com/ponylang/corral
cd corral
make
sudo make install
```

### From Source (Windows)

In PowerShell:

```
git clone https://github.com/ponylang/corral
cd corral
.\make.ps1 build
.\make.ps1 test
```

You can make a debug build with `.\make.ps1 build -Config Debug`

## Create a project with dependencies

### GitHub or GitLab or Bitbucket

Use a bundle from the internet.

```bash
mkdir myproject && cd myproject

corral add github.com/jemc/pony-inspect.git

echo '
use "inspect"
actor Main
  new create(env: Env) =>
    env.out.print(Inspect("Hello, World!"))
' > main.pony
```

This form works the same way for gitlab.com and bitbucket.com.

You can also include additional bundle paths after the repo, such as:
`github.com/ponylang/corral-test-repo.git/bundle1`

In addition, you can specify version constraints using this form:
`--version='>=1.1.0 <2.0.0`
or specific tags or commits like `--version='1.2.3'` or `--version=c061655c`.

### Local git Bundle

Use a bundle from a local repo that might have private changes or is not yet pushed.

```bash
mkdir myproject && cd myproject

corral add ../pony-inspect.git

echo '
use "inspect"
actor Main
  new create(env: Env) =>
    env.out.print(Inspect("Hello, World!"))
' > main.pony
```

The bundle path and version specification work the same as remote git.

### Local Direct Bundle

Use a bundle from local code that you are working on live.

```bash
mkdir myproject && cd myproject

corral add ../pony-inspect

echo '
use "inspect"
actor Main
  new create(env: Env) =>
    env.out.print(Inspect("Hello, World!"))
' > main.pony
```

The bundle path works the same as remote git, but versions are not applicable as the local bundle directory is referenced directly.

## Update Dependency Revisions

This step will fetch all dependencies, including transitive dependencies, and then it will calculate the best revisions for each and write them to the `lock.json` file. This file can also be edited by hand, or the update command run periodically to refresh dependencies to the latest constrained versions.

It is recommended that `lock.json` be checked in along with `corral.json` so that subsequent builds of the shared project use the same revisions for reproducability.

```bash
corral update
```

```bash
git cloning github.com/jemc/pony-inspect.git into _repos/github_com_jemc_pony_inspect_git
git checking out @master into _corral/github_com_jemc_pony_inspect
```

## Fetch dependencies

This step will fetch dependencies using the current revisions in the `lock.json` file, or latest constrained version if there is no locked revision. This operation can be done after a new clone, or pull or other changes to the `lock.json` file to ensure that the checked out dependencies are present and up to date.

Remote repos will be cloned into the *repo_cache* (<project>/_repo) and checked-out revisions will be placed in the *corral_dir* (<project>/_corral).

```bash
corral fetch
```

```bash
git cloning github.com/jemc/pony-inspect.git into _repos/github_com_jemc_pony_inspect_git
git checking out @master into _corral/github_com_jemc_pony_inspect
```

## Compile With a Corral

The local paths to the dependency's bundle directories will be included in the `PONYPATH` environment variable, and available for use in the `ponyc` invocation.
You can run any custom command here - not just `ponyc`.

```bash
corral run -- ponyc --debug
```

```bash
run: ponyc --debug
  exit: 0
  out:
  err: Building builtin -> /usr/local/Cellar/ponyc/0.33.0/packages/builtin
Building . -> /Users/carl/ws/pony/cquinn/corral/corral/test/testdata/readme
Building inspect -> /Users/carl/ws/pony/cquinn/corral/corral/test/testdata/readme/_corral/github_com_jemc_pony_inspect/inspect
Building format -> /usr/local/Cellar/ponyc/0.33.0/packages/format
Building collections -> /usr/local/Cellar/ponyc/0.33.0/packages/collections
Building ponytest -> /usr/local/Cellar/ponyc/0.33.0/packages/ponytest
Building time -> /usr/local/Cellar/ponyc/0.33.0/packages/time
Building random -> /usr/local/Cellar/ponyc/0.33.0/packages/random
Generating
 Reachability
 Selector painting
 Data prototypes
 Data types
 Function prototypes
 Functions
 Descriptors
Writing ./readme.o
Linking ./readme
```
