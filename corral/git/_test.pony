use "pony_test"
use sha1 = "sha1"
use inflate = "inflate"

actor \nodoc\ Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    sha1.Main.make().tests(test)
    inflate.Main.make().tests(test)
