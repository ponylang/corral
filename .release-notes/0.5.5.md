## Fix backslashes in locator paths in lock.json

We were using Path.join to construct locator paths for lock files. On Windows, this will use backslashes, which for locators that are URL paths, is incorrect. This change makes all locator paths use forward slashes instead. This is OK on Windows even for local filesystem dependencies since Windows understands forward slashes.

## Support Ponyup on Windows

To support ponyup on Windows, updated corral to be able to run `X.bat` files when given `X` as a command to run. Also changes to the Windows `make.ps1` script to make sure it still works with ponyup on Windows.

