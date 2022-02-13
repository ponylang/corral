## Fix resolving relative paths for `corral run`

Corral was failing when running commands with a relative path to the binary. E.g. `../../build/debug/ponyc`.
This change switches relative binary resolution from using [`FilePath.from`](https://stdlib.ponylang.io/files-FilePath/#from) to [`Path.join`](https://stdlib.ponylang.io/files-Path/#join), in order to not fail if a path points to a parent directory, which is an error condition for [`FilePath.from`](https://stdlib.ponylang.io/files-FilePath/#from).

`corral run` now also resolves relative paths against the current working directory first, before checking the `$PATH` environment variable.

## Improved Error messages for `corral run`

`corral run` will now print more detailed error messages when it is not able to run the given command.

