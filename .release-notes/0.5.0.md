## Change "unknown branch" default to 'main'

GitHub has switched its default branch name from `master` to `main` for newly created repositories. Given this change, we expect that eventually most repositories will have their default branch named `main`, not `master`.

Corral will now use `main` and not `master` for the branch to use when using git or hg repos as a source.

Any corral.json dependency entries that aren't using a version should be updated to include `master` as the version to continue working as they did before or if you control the dependency, update its default branch to `main` and things will continue to work as before.

## Switch support FreeBSD version

We've switched our supported FreeBSD from 12.1 to 12.2. The switch means that FreeBSD packages are tested and built on FreeBSD 12.2 and we no longer do any testing or building on 12.1.

You can continue using corral on FreeBSD 12.1 but we make no guarantees that it will work.

