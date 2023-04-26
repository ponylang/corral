## Remove macOS on Intel as a supported platform

We are no longer supporting macOS on Intel.

## Correctly set exit code on script failure

Previously, when a "post fetch" script failed, the exit code wasn't correctly set. This could result in scripts that automate corral not realizing that an error had occurred.

