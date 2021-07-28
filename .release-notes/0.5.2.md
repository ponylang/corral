## Fix bug that prevented lock.json from being populated

After resolving version constraints, the correct revision was being determined but wasn't written to the lock.json file.

## Fixed bug where corral update would result in incorrect code in the corral

When a dependency had a version constraint rather than a single value, the first time `corral update` was run, you wouldn't end up with the correct code checked out. The constraint was correctly solved, but the checked out code would be for branch `main`.

## Make `fetch` an alias for `update`

When using version constraints rather than a specific revision, `corral fetch` would never set the repo to the correct state. Instead it would always leave the "version constraint using" dependency on the branch `main`.

The has been "fixed" by making `fetch` run the `update` command. It is possible that we will revisit this in the future and try to separate them. However, fixing is non-trivial and we felt it best to correct the glaring "doesn't work" error in `corral fetch`.

