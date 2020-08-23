# Pony Package Dependency Management

This is a survey of package and dependency management tools in a few languages, including Pony Stable. The goal is to provide some insight into how this is done in similar languages and communities to help inform any improvements we make to Pony tools.

## Other Languages

We can learn a lot by looking at other languages and their package managers. The Go community did an interesting comparison that can be found here:

- [https://docs.google.com/document/d/19HNnqMsETTdwwQd0I0zq2rg1IrJtaoFEA1B1OpJGNUg/edit](https://docs.google.com/document/d/19HNnqMsETTdwwQd0I0zq2rg1IrJtaoFEA1B1OpJGNUg/edit)

And Rust has a nice way of specifying version constraints:

- [http://doc.crates.io/specifying-dependencies.html](http://doc.crates.io/specifying-dependencies.html)

Go has gone through quite an evolution and eventually settled on a versioned module system:

- [https://go.googlesource.com/proposal/+/master/design/24301-versioned-go.md](https://go.googlesource.com/proposal/+/master/design/24301-versioned-go.md)
- [https://github.com/golang/go/wiki/Modules](https://github.com/golang/go/wiki/Modules)

## Pony and Go

Pony is similar to Go in that it is a compiled language that imports and compiles dependencies from source, and so needs to address source repo retrieval concerns, but not binary artifact and ABI versioning concerns.

Golang's initial dependency management was quite weak, putting off the hard work to the community to figure out the details. But since fall '16, they’ve had a nice model and spec, transitioned to a standard tool called `dep` for a while, then in Go 1.11 introduced an integrated module system.

Pony hasn't made some mistakes that I think Go had, and we are still greenfield and can learn from the Go community and where they eventually arrived. The main issues that I think Go had/have are:

- The inclusion of the full package source location with the package name in the imports made things quite messy for a while. In particular, it makes using forks or locally-cached copies of packages difficult, and requires source re-writing or special handling by the package manager. Given the recent ability for package managers to alias-in alternatives, it isn’t quite so bad anymore.

- The giant GOPATH workspace that Go originally relied on to manage compilation of all dependencies made it hard to work on multiple projects that had dependencies at different versions: that is anything not at latest. This was fixed in Go 1.5 with the Go 1.5 Vendor Experiment, which allowed the community to converge on a few management solutions that were rolled into the ‘dep’ tool, and then the module system.

Go calls one aspect of their approach to managing dependent sources "vendoring" as it relies on copying or vendoring dependencies into a project `vendor/` subdir, and often (but not necessarily) committing that as source with the project. That latter step ensures that the right dependencies’ sources are always accessible at build, even if the original is lost, moved, or slow/hard/broken to retrieve over the network. But, it is clunky, obscures code reviews, and can invite sneaky errors when people tweak the committed source.

## Existing Tools

The most popular dependency management tools in the Go ecosystem, plus Pony Stable:

- Glide
  - [https://github.com/Masterminds/glide](https://github.com/Masterminds/glide)
  - Mature and most popular
  - Very complete, supports semantic versions and ranges
  - A bit complex? Seems to have evolved and simplified since Go 1.6
  - Model: Packages contain Subpackages

- Govendor
  - [https://github.com/kardianos/govendor](https://github.com/kardianos/govendor)
  - [https://github.com/kardianos/govendor/blob/master/doc/whitepaper.md](https://github.com/kardianos/govendor/blob/master/doc/whitepaper.md)
  - Mature and popular
  - Simple and easy to use, mixes well with the older GOPATH model
  - Missing some glide features like versioning constraints
  - Model: ? contains Packages. Maybe. Or is it flat?

- Golang go dep (experiment)
  - [https://github.com/golang/dep](https://github.com/golang/dep)
  - Young but was intended to combine the community tools
  - Simplified command set: init, ensure, status, prune
  - Heavily relies on deriving project paths from package imports in source
  - Model: Projects contain Packages

- Golang Modules: go mod
  - [https://github.com/golang/go/wiki/Modules](https://github.com/golang/go/wiki/Modules)
  - Integrated into the standard language tooling
  - In the process of being adopted, is the default but users can opt out for one more rev
  - Can derive project paths from package imports in source
  - Model: Projects contain Packages

- Pony Stable
  - [https://github.com/ponylang/pony-stable](https://github.com/ponylang/pony-stable)
  - What Pony has now, and a great model to start with
  - Model: Bundles contain Packages

This is a good feature matrix of the Go tools from the Glide repo:

- [https://github.com/Masterminds/glide/wiki/Go-Package-Manager-Comparison](https://github.com/Masterminds/glide/wiki/Go-Package-Manager-Comparison)

## Models

They all have a similar model and comparable workflows.

- A dependency manifest file managed by the tool and/or user edited.

  - Glide: glide.yaml
  - Govendor: vendor/vendor.json
  - Dep: Gopkg.toml
  - Go Modules: go.mod
  - Stable: bundle.json

- A parallel lock file that is produced at sync/update time to record all the specific revisions and SHAs in order to reproduce an exact build at any time. Having locking in addition to flexible constraints allows pinning to exact revisions to ensure reproducible rebuilds. Having the locks in a file distinct from the main dependency file simplifies the workflow of committing it only after tests pass and reused it for subsequent rebuilds, or wiping it to get a clean snapshot.

  - Glide: glide.lock
  - Govendor: (included in vendor.json)
  - Dep: Gopkg.lock
  - Go Modules: go.sum
  - Stable: N/A

- A subdir where all of the vendored sources are kept.
  - Go’s standard since 1.5 is vendor/
  - Go Modules:
  - Downloaded modules unpacked: ~/go/pkg/mod/<module/trees>
  - Scratch build files: ~/.cache/go-build/
  - Stable: .deps/

## Commands and Workflows

### Getting started

- create, init (glide)
  - Initialize a new project, creating a glide.yaml file.
- init (govendor)
  - Create the "vendor" folder and the "vendor.json" file.
- init (dep)
  - Initialize a new project with manifest and lock files.
  - Initialize the project at filepath root by parsing its dependencies, writing manifest and lock files, and vendoring the dependencies. Can import from other tools.
- init (go mod)
  - Init initializes and writes a new go.mod to the current directory, in effect creating a new module rooted at the current directory.
- N/A (stable)
Stable creates the bundle.json on first add

### Reporting

- list (glide)
  - List prints all dependencies that the present code references.
- novendor (glide)
  - List all non-vendor paths in a directory.
- info (glide)
  - Info prints information about this project
- name (glide)
  - Print the name of this project.
- list (govendor)
  - Lists dependencies and their status as follows.
    - One of:
      - l: local: package is in the project
      - e: external: package is on $GOPATH but not vendored
      - v: vendor: package is vendored
      - s: std: package is part of the standard library
    - Zero or one of:
      - x: excluded: external package excluded from vendoring
      - u: unused: package is vendored but unused in the code
      - m: missing: source depends but there is no resolution
    - Zero or one of:
      - p: program: package is a main package (Go treats main specially, does Pony need to?)
- status (govendor)
  - Lists dependencies that are missing, out-of-date, or modified locally.
- status (dep)
  - Report (list) the status of the project's dependencies.
  - For each project, lists:
    - PROJECT.    Import path
    - CONSTRAINT  Version constraint, from the manifest
    - VERSION     Version chosen, from the lock
    - REVISION    VCS revision of the chosen version
    - LATEST      Latest VCS revision available
    - PKGS USED   Number of packages from this project that are actually used
- graph (go mod)
  - Graph prints the module requirement graph (with replacements applied) in text form.
- why (go mod)
  - Why shows a shortest path in the import graph from the main module to each of the listed packages.
- (stable)
  - The bundle.json can be examined by hand.

### Adding packages to the working set

- get (glide)
  - Adds a package from a remote repo to the vendor space
- add (govendor)
  - Add packages from $GOPATH.
- fetch (govendor)
  - Add new or update vendor folder packages from remote repository.
- ensure (dep) <spec>...
  - Ensure is used to fetch project dependencies into the vendor folder, as well as to set version constraints for specific dependencies.
  - It takes user input, solves the updated dependency graph of the project, writes any changes to the lock file, and places dependencies in the vendor folder.
  - spec: <path>[:alt-location][@<version-specifier>]
- get (go get)
  - Get resolves and adds dependencies to the current development module and then builds and installs them.
  - Also, go.mod file can be edited by hand
- add (stable)
  - Adds a package from github, local-git or local path to the stable

### Updating packages in the working set

- update (glide)
  - Update a project's dependencies
- fetch (govendor)
  - Add new or update vendor folder packages from remote repository.
- update (govendor)
  - Update packages from $GOPATH.
- ensure (dep) -update [<spec>...]
  - ensure dependencies are at the latest version allowed by the manifest (default: false).
- tidy (go mod)
  - Tidy makes sure go.mod matches the source code in the module.
  - It adds any missing modules necessary to build the current module's packages and dependencies, and it removes unused modules that don't provide any relevant packages.
- (stable)
  - See fetch below.

### Removing packages from the working set

- remove (glide)
  - Remove a package from the glide.yaml file, and regenerate the lock file.
- remove (govendor) [+status_type]
  - Remove packages from the vendor folder.
  - Easy to remove +unused packages
- ensure (dep)
  - ?
- prune (dep)
  - Prune the vendor tree of unused packages. (May be removed)
- tidy (go mod)
  - (see above)
- (stable)
  - The bundle.json can be edited by hand.

### Aliases or mirrors

- mirror (glide)
  - Manage mirrors. Mirrors provide the ability to replace a repo location with another location that's a mirror of the original.
  - Another form of Aliasing.

### Populating or updating the working set from the manifest+lock

- update (glide)
  - Update a project's dependencies.
  - Updates the dependencies by scanning the codebase to determine the needed dependencies and fetching them following the rules in the glide.yaml file.
- install (glide)
  - Install a project's dependencies.
  - There are two ways a project’s dependencies can be installed. When there is a glide.yaml file defining the dependencies but no lock file (glide.lock) the dependencies are installed using the "update" command and a glide.lock file is generated pinning all dependencies. If a glide.lock file is already present the dependencies are installed or updated from the lock file.
- sync (govendor)
  - Pull packages into vendor folder from remote repository with revisions from vendor.json file.
- ensure (dep)
  - Without -update it just ensures the locked versions are present in the working set.
- download (go mod)
  - Download downloads the named modules, which can be module patterns selecting dependencies of the main module or module queries of the form path@version. With no arguments, download applies to all dependencies of the main module.
- verify (go mod)
  - Verify checks that the dependencies of the current module, which are stored in a local downloaded source cache, have not been modified since being downloaded.
- fetch (stable)
  - Fetch/update the deps for this bundle

### Misc maintenance

- cache-clear (glide)
  - Clears the Glide cache.
- config-wizard (glide)
  - Wizard that makes optional suggestions to improve config in a glide.yaml file.
- edit (go mod)
  - Edit provides a command-line interface for editing go.mod, for use primarily by tools or scripts.
- vendor (go mod)
  - Vendor resets the main module's vendor directory to include all packages needed to build and test all the main module's packages.

### Running compiler and other tools in the environment of the working set

- rebuild (glide),
  - Rebuild ('go build') the dependencies
- install (glide)
  - Install a project's dependencies
- shell (govendor)
  - Run a "shell" to make multiple subcommands more efficient for large projects.
  - More like a repl for other govendor commands
- (go mod)
  - Standard go tools implicitly use the module system.
- env (stable)
  - Execute the following shell command inside an environment with $PONYPATH set to include deps directories
