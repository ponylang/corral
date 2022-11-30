## Update Dockerfile to use Alpine 3.16 as base

The corral Dockerfile has been updated to use Alpine 3.16 as its base image. Previously we were using Alpine 3.12 which is no longer supported. 3.16 is supported until 2024.

## Switch supported FreeBSD to 13.1

As of this release, we now do all FreeBSD testing on FreeBSD 13.1 and all corral prebuilt packages are built on FreeBSD 13.1. We will make a best effort to not break prior versions of FreeBSD while they are "supported".

