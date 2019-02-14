# Corral

Pony dependency management command-line tool. Corral builds on the work done in pony-stable,
adding a few new things:

- Using Pony cli package for command line parsing.
- Having a complete command set for managing dependency files.
- Extensibility in VCS and Commands.
- Support for semver version constraints on deps.
- Support for revision locking on deps, using a lock.json file.
- Uses the Pony process package for spawning external tools like Git.

TODOs:

- Improve tool output printing, verbosity levels.
- Honor `-n` everywhere.
- Figure out layout of recursive deps.
- Allow for non-semver constraints, such as simple tags or branches.
- Include hash in lockfile.
- Do something interesting with bundle info.
- Implement local repos: skip clone/fetch, just checkout.
- Implement local paths: skip all version/tag query, always checkout using symlink.
- Implement other VCS: Hg, Bzr, Svn, etc.

For a discussion of the requirements and design work behind Corral, see:

- [Pony Deps Doc](https://docs.google.com/document/d/1c7puEQLks3X1wpabuXxox8Qi1HUhfSwhobUvmVE56Rw/edit#)
