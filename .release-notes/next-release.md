## Fix bundle scripts running during fetch of git repository

Corral was executing the bundle scripts while the git repository was being fetched. This was most noticable when downloading a bundle for the first time, as it was likely that the bundle file wasn't on disk when Corral tried to find the scripts to run.

The fix waits for the repository to be successfully fetched before executing the bundle scripts.

## Don't remember empty optional fields from corral.json

Empty "info" object fields were previously removed from corral.json. This made it hard to know what additional information you should be providing as a library author.

## Add `documentation_url` entry to bundle manifest

documentation_url will allow a forthcoming feature in the pony compiler to generate documentation for code that uses a given bundle to link to the documentation for that bundle from the code in question.

For example, `ponylang/http` will have its documentation link directly to the documentation for `ponylang/regex` and `ponylang/net_ssl` for types that come from those bundles.

