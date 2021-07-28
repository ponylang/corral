## Make `fetch` an alias for `update`

When using version constraints rather than a specific revision, `corral fetch` would never set the repo to the correct state. Instead it would always leave the "version constraint using" dependency on the branch `main`.

The has been "fixed" by making `fetch` run the `update` command. It is possible that we will revisit this in the future and try to separate them. However, fixing is non-trivial and we felt it best to correct the glaring "doesn't work" error in `corral fetch`.
