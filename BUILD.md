# Building Corral From Source

You will need `ponyc` in your PATH.

### From Source (FreeBSD)

```bash
git clone https://github.com/ponylang/corral
cd corral
gmake
sudo gmake install
```

### From Source (Linux/macOS)

```bash
git clone https://github.com/ponylang/corral
cd corral
make
sudo make install
```

### From Source (Windows)

In PowerShell:

```
git clone https://github.com/ponylang/corral
cd corral
.\make.ps1 build
.\make.ps1 test
```

You can make a debug build with `.\make.ps1 build -Config Debug`