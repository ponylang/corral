# Corral Design

The corral name represents the place where all the ponies are kept outside when they are working and playing. I picked this name because it is like a ‘stable’ but distinct to avoid confusion.

Pony source files are organized into directories, each representing a ‘package’. Corral introduces the notion of a collection of packages developed and delivered together as being a ‘bundle’. Bundles are maintained in VCS under a ‘repo’. So:

- A **package** belongs to a **bundle**, and a **bundle** contains one or more **packages**.
- A **bundle** resides in a **repo**, and a **repo** hosts one or more **bundles**.

Pony source files contains `use` statements that refer to packages by their short name or a (dot-prefixed) relative path. Short name usages are assumed to be references into other bundles, while relative paths refer to packages within the same bundle. So, for example, referring to a sibling package within the same bundle would look like `use "../sister"` and referring to a child package in the same bundle would look like `use "./child"`.

[We could introduce a foreign bundle prefix, like `"bundle//package"` or `"bundle:package"` or `"bundle::package"`. This would disambiguate foreign from child package references, as well as differentiate same-name packages from different bundles. The lack of a prefix would imply a Pony stdlib package.]

## Repos and Directories

[TODO: Draw a tree layout of remote and local repos, containing bundles, containing packages.]

## Corral Directories

Corral uses a few directories to keep its settings and state and scratch areas to do its work. These all have default values, but can be overridden with environment variables or common command line options.

Corral manages dependency bundles in two directories. One is its shared **repo-cache** where it manages cloned remote repos (with no workspaces) and which can be safely shared between projects. The other is the per-project **bundle-corral** and is where project dependencies are checked out and where `PONYPATH` entries are pointed into. Specifically:

- The **corral-home** is where Corral keeps its configuration options that are common to the user. This directory defaults to `~/.corral`, but can be overridden using `CORRAL_HOME=dir` or `--home=dir`.
    [TODO: was this actually needed / used? Maybe should be, and add a corral-home/config.json too.]

- The **repo-cache** is where Corral manages remote repos. The default location for the **repo-cache** is under **corral-home**, i.e. **~/.corral/repo-cache/**, but it can be relocated under the project dir or any other dir using: `CORRAL_REPO_CACHE=dir` or `--repo-cache=dir`. Corral clones and syncs remote repos under this directory to keep them up to date. This directory can be deleted at any time and Corral will rebuild it as needed.

- The **bundle-corral** contains a flattened tree copy of all of the bundle dependencies, each in its own subdirectory and at its specific revision. The default location for bundle-corral is `<bundle-dir>/_corral`. The bundles here are obtained by:
  - For remote repos, they are checked out from the repo-cache.
  - For local repos, they are checked out from the local repo.
  - For local paths, they are copied (cp -R) from their local path.
     [TODO: should we symlink them instead?]

## Project Files

A project bundle contains a **corral.json** file as well as a **lock.json** file in the top level directory. Other encoding syntaxes might be more user-friendly once Pony has libraries for them. Examples: yaml, toml, pbtxt or hcl.

The `corral.json` file is managed by the Corral tool, but can also be edited by hand. It contains these JSON objects:

- **info**: Information about this bundle:
  - **name**: The name of the bundle, which should be its canonical location. [is this redundant with its implicit location?]
  - **description**: More text description about the bundle.
  - **homepage**: URL of the bundle home page.
  - **documentation_url**: URL of the documentation for the bundle, used in cross-linking during documentation generation of the package.
  - **license**: License type, e.g. BSD, MIT, Apache, etc., or URL to it.
  - **version**: The version of this bundle.
     [TODO: is this redundant with the tags + revision/commits? I think so.]

- **deps**: A list of bundle dependencies that this bundle depends on. Each of these dependencies include the following needed to retrieve the bundle from a local or remote VCS repo, or a local path:

  - **locator**: The unique bundle locator that contains all the information needed to retrieve the bundle. The locators are composed of multiple parts which determine how they are accessed and which (if any) VCS is used. The general syntax is:
    - locator := repo_path[.suffix][/bundle_path]
      - Where repo_path is a remote or local path to a repository
      - And suffix is a VCS suffix, one of: git, hg, bzr or svn
      - And bundle_path is a relative path within the repo to the bundle’s package base.
    - For remote VCS
      - The repo_path will include the VCS repo host, org, project. Host being a valid hostname is a key identifier.
      - The suffix must be included to identify VCS.
      - The bundle_path is optional.
      - locator := host.name/org/reponame.suffix[/bundle_path]
    - For local VCS
      - The repo_path will be a local relative or absolute path. Starting with a ‘.’ or a ‘/’ is a key identifier.
      - The suffix must be included to identify VCS.
      - The bundle_path is optional.
      - locator := localpath.suffix[/bundle_path]
      - And localpath.suffix is a VCS repo metadata dir.
    - For local path direct
      - The repo_path will be a local relative or absolute path. Starting with a ‘.’ or a ‘/’ is a key identifier.
      - The suffix must not be included to identify VCS.
      - The bundle_path is not applicable since the local path points right to the bundle’s package base
      - locator := localpath

  - **version**: Version constraint expression to use when selecting the best version from a VCS repo. Version takes on a different form when the bundle is a local path. This can be any number of references that can be used to select a specific revision.
    - A semver constraint string. See: [https://github.com/cquinn/pony-semver](https://github.com/cquinn/pony-semver)
    - A specific tag or branch or commit-ish.
    - See: [https://docs.npmjs.com/misc/semver](https://docs.npmjs.com/misc/semver)
    - See: [http://doc.crates.io/specifying-dependencies.html](http://doc.crates.io/specifying-dependencies.html)
    - See: [https://github.com/Masterminds/semver](https://github.com/Masterminds/semver)

- TODO, as needed: An optional list of packages with their supplier-bundle by name. This is normally inferred by listing the packages from the referenced bundles and cross referenced with use statements in the bundle source. But, in theory, the entries can be adjusted to hide packages when there are collisions.
  - **package**: the name of the package in the same form as in use statements.
  - **supplier**: the bundle.name above that supplies this package.

The `lock.json` file contains:

- An entry for each bundle reference in `corral.json` that indicates the specific revision of each bundle that was resolved at update time.
  - **bundle**: The bundle locator that this lock applies to.
  - **revision**: The revision that this bundle is locked to; typically a commit hash.

## Corral Commands

- init : Initializes the corral.json and lock.json files with skeletal information. Creates the **bundle-corral** subdirectory.
  - No bundle information can be extracted from source, since use statements specify only package names.
  - *TODO: We could parse Pony source to create an initial package list here, with blank supplier-bundles to be filled in later.*

- info : Prints all or specific information about the bundle from corral.json.
  - TODO.

- add : Adds one or more bundles to the corral.
  - At minimum the bundle location must be specified
  - Version constraints may be specified; default is to just use `main@head`.
  - Package list may be specified; default is to include all packages from the bundle.

- remove : Removes one or more bundles from the corral.
  - Removes the bundle entries from the `corral.json`
  - Removes any supplier references to the bundles
  - Removes the bundle trees from the **bundle-corral** directory.
  - *TODO: The --prune option can be used to remove unused packages and bundles. Parses Pony source to get required package list for this option.*

- list : Lists the bundles and packages, including corralled information.
  - For each bundle
    - location, version, local and latest revision.
    - supplied packages, which are used, none if unused
  - For each package
    - name, supplier bundle or missing if none, or unused
  - *TODO: Parses Pony source to get required package list.*

- clean : Clean up and remove all of the directories and files under this bundle’s corral dir.
  - If `--repos` is given, then clean up the repo-cache instead.
  - If `--all` is given, then clean up both.

- update : Updates one or more or all of the bundles in the corral to their best revision.
  - Examines each of the bundles specified and looks for newer revisions in the VCS location that meet the version constraints.
  - Prints current and newer revisions if an update is needed.
  - Retrieves newer revisions of the bundle and updates `lock.json` (if -n is not specified).

- fetch : Fetches one or more or all of the bundles into the corral.
  - Uses the bundle list plus the bundle-lock to determine if the specific revisions of the bundles specified need to be retrieved.
  - Prints the bundles with revisions that need retrieval.
  - Retrieves the bundles from the VCS location (if -n is not specified)

- run : Runs a sub process inside an environment with each bundle-corral subdir on the PONYPATH.

- TODO: package / supplier management?
  - Do we need a command to allow adjusting of which bundle should supply which package.
  - May be useful if a package name is duplicated from more than one bundle.
  - Could do this with remove if a bundle:package can be specified

- Should we have a command to scan source and refresh the packages list?
