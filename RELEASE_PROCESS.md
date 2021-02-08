# How to cut a release

This document is aimed at members of the team who might be cutting a release. It serves as a checklist that can take you through doing a release step-by-step.

## Prerequisites

* You must have commit access to the this repository.
* It would be helpful to have read and write access to the ponylang [cloudsmith](https://cloudsmith.io/) account.

## Releasing

Please note that this document was written with the assumption that you are using a clone of this repo. You have to be using a clone rather than a fork. It is advised to your do this by making a fresh clone of the repo from which you will release.

Before getting started, you will need a number for the version that you will be releasing as well as an agreed upon "golden commit" that will form the basis of the release.

The "golden commit" must be `HEAD` on the `main` branch of this repository. At this time, releasing from any other location is not supported.

For the duration of this document, that we are releasing version is `0.3.1`. Any place you see those values, please substitute your own version.

```bash
git tag release-0.3.1
git push origin release-0.3.1
```

## If something goes wrong

The release process can be restarted at various points in its life-cycle by pushing specially crafted tags.

## Start a release

As documented above, a release is started by pushing a tag of the form `release-x.y.z`.

## Build artifacts

The release process can be manually restarted from here by pushing a tag of the form `x.y.z`. The pushed tag must be on the commit to build the release artifacts from. During the normal process, that commit is the same as the one that `release-x.y.z`.

### Updating Homebrew

Fork the [homebrew-core repo](https://github.com/Homebrew/homebrew-core) and then clone it locally. You are going to be editing "Formula/corral.rb". If you already have a local copy of homebrew-core, make sure you sync up with the main Homebrew repo otherwise you might change an older version of the formula and end up with merge conflicts.

Make sure you do your changes on a branch:

* git checkout -b corral-0.3.1

HomeBrew has [directions](https://github.com/Homebrew/homebrew-core/blob/main/CONTRIBUTING.md#submit-a-123-version-upgrade-for-the-foo-formula) on what specifically you need to update in a formula to account for an upgrade. If you are on macOS and are unsure of how to get the SHA of the release .tar.gz, download the release file (make sure it does unzip it) and run `shasum -a 256 corral-0.3.1.tar.gz`. If you are on macOS, its quite possible it will try to unzip the file on your. In Safari, right clicking and selecting "Download Linked File" will get your the complete .tar.gz.

After updating the corral formula, push to your fork and open a PR against homebrew-core. According to the homebrew team, their preferred naming for such PRs is `corral 0.3.1` that is, the name of the formula being updated followed by the new version number.

## Announce release

The release process can be manually restarted from here by push a tag of the form `announce-x.y.z`. The tag must be on a commit that is after "Release x.y.z" commit that was generated during the `Start a release` portion of the process.

If you need to restart from here, you will need to pull the latest updates from the repo as it will have changed and the commit you need to tag will not be available in your copy of the repo with pulling.
