## Stop having a base imageAdd commentMore actions

Previously we were using Alpine 3.20 as the base image for the corral container image. We've switched to using the `scratch` image instead. This means that the container image is now much smaller and only contains the `corral` binary.
