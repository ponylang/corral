use "ponytest"
use "../.."
use "../../util"

class TestVersion is UnitTest
  fun name(): String => "integration/version"
  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h, recover ["version"] end, CheckVersion)

class CheckVersion is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    h.assert_eq[I32](0, ar.exit_code)
    h.assert_true(ar.stdout.at("corral "))
    h.assert_true(ar.stdout.at(Info.version(), 7))
    h.complete(ar.exit_code == 0)
    //h.env.out.print(ar.stdout)
