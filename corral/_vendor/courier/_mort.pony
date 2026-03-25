use @exit[None](status: I32)
use @fprintf[I32](stream: Pointer[None] tag, fmt: Pointer[U8] tag, ...)
use @pony_os_stderr[Pointer[None]]()

primitive _IllegalState
  """
  To be used to exit early if we called a function that shouldn't be possible
  in our current state.
  """
  fun apply(loc: SourceLoc = __loc) =>
    @fprintf(
      @pony_os_stderr(),
      ("An illegal state was encountered in %s at line %s\n" +
        "Please open an issue at " +
        "https://github.com/ponylang/courier/issues")
        .cstring(),
      loc.file().cstring(),
      loc.line().string().cstring())
    @exit(1)

primitive _Unreachable
  """
  To be used in places that the compiler can't prove is unreachable but we are
  certain is unreachable and if we reach it, we'd be silently hiding a bug.
  """
  fun apply(loc: SourceLoc = __loc) =>
    @fprintf(
      @pony_os_stderr(),
      ("The unreachable was reached in %s at line %s\n" +
        "Please open an issue at " +
        "https://github.com/ponylang/courier/issues")
        .cstring(),
      loc.file().cstring(),
      loc.line().string().cstring())
    @exit(1)
