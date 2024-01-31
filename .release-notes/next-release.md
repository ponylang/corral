## Use Alpine 3.18 as our base image

Previously we were using Alpine 3.16. This should have no impact on anyone unless they are using this image as the base image for another.

## Add MacOS on Apple Silicon as a fully supported platform

In August of 2023, we had to drop MacOS on Apple Silicon as we lost our build environment when we switched off of CirrusCI to GitHub Actions. GitHub just added MacOS Apple Silicon build environments, so we are bring back MacOS on Apple Silicon as a fully supported platform.

corral is once again available as a compiled arm64 MacOS binary.

