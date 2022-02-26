use "pony_test"
use ".."
use "../.."
use "../../util"

class  \nodoc\ TestVersion is UnitTest
  fun name(): String => "integration/version"
  fun apply(h: TestHelper) =>
    h.long_test(30_000_000_000)
    Execute(h, recover ["version"] end, CheckVersion)

class  \nodoc\ CheckVersion is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    h.assert_eq[I32](0, ar.exit_code())
    h.assert_true(ar.stdout.at("version: "))
    h.assert_true(ar.stdout.at(Version(), 9))
    h.complete(ar.exit_code() == 0)
