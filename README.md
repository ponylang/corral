# Corral

Pony dependency management command-line tool.

For a discussion of the requirements and design work behind Corral, see:

- [Pony Package Dependency Management](https://docs.google.com/document/d/1c7puEQLks3X1wpabuXxox8Qi1HUhfSwhobUvmVE56Rw/edit#)

Corral builds on the work done in pony-stable, adding some new things:

- Uses Pony cli package for command line parsing.
- Easy extensibility of VCS and Commands.
- Supports semver version constraints on deps.
- Supports revision locking on deps, using a lock.json file.
- Uses the Pony process package for spawning external tools like Git.
- Separate shared repo pool from per-project deps tree.

TODOs:

- Add a --path flag to allow specification of bundle dir to start in
- Improve tool output printing, verbosity levels.
- Figure out & fix layout of recursive deps. Flat?
- Allow for non-semver constraints, such as simple tags or branches.
- Honor `-n` everywhere.
- Get repo cache situated in the right location.
- Use ProcessMonitor (probably via Actions) for run command.
- Include hashes in lock file.
- Do something interesting with bundle info.
- Implement remote gitlabs repos.
- Implement local repos: skip clone/fetch, just checkout.
- Implement local paths: skip clone/fetch, version/tag query, always just checkout using symlink or copy or reference path in PONYPATH.
- Implement other VCS: Hg, Bzr, Svn, etc., as needed.
- Unit tests and automated functional tests.

## Dependencies

`corral` requires the libpcre2 library in order to operate. You'll need to install it within your environment of choice, either via your package manager or from source.

### Installing on APT based Linux distributions

```
sudo apt-get install -y libpcre2-dev
```

### Installing on Alpine Linux

```
apk add --update pcre2-dev
```

### Installing on Arch Linux

```
pacman -S pcre2

```

### Installing on DragonFly

```
sudo pkg install pcre2
```

### Installing on FreeBSD

```
sudo pkg install pcre2
```

### Installing on macOS with Homebrew

```
brew update
brew install pcre2
```

#### Installing on macOS with MacPorts

```
sudo port install pcre2
```

### Installing on OpenBSD

```
doas pkg_add pcre2
```

### Installing on RPM based Linux distributions with dnf

```
sudo dnf install pcre2-devel
```

### Installing on RPM based Linux distributions with yum

```
sudo yum install pcre2-devel
```

### Installing on RPM based Linux distributions with zypper

```
sudo zypper install pcre2-devel
```

### Installing on Windows

Download a prebuilt binary from [http://www.pcre.org/](http://www.pcre.org/).

### Building PCRE2 from source

```
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre2-10.21.tar.bz2
tar xvf pcre2-10.21.tar.bz2
cd pcre2-10.21
./configure --prefix=/usr
make
sudo make install
```