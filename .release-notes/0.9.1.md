## Stop Building Corral Docker Images

We've stopped building and publishing Corral Docker images. Corral is available in the ponyc images and can be used from there. Additionally, the only thing in the images was a statically linked binary, which can be downloaded Cloudsmith or installed via ponyup. The image itself provided no real value.

## Fix `corral --quiet run` not suppressing output

Previously, `corral --quiet run` still printed `exit:`, `out:`, and `err:` headers. The `--quiet` flag now correctly suppresses this output.

