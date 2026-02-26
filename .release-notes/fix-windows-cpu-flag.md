## Fix intermittent corral Windows build failures

The Windows build script (`make.ps1`) was not passing the `--cpu` flag to ponyc, unlike the Linux and macOS builds which pass `--cpu` via the Makefile. Without an explicit CPU target, ponyc defaults to the build machine's native CPU features. When the CI runner building corral nightlies had an AVX-512 capable CPU, the resulting binary contained AVX-512 instructions that would crash with an illegal instruction exception (`0xc000001d`) on runners without AVX-512 support.

The fix adds `--cpu "$Arch"` to both `BuildCorral` and `BuildTest` ponyc invocations, matching what the Makefile already does with `$(arch_arg)`.
