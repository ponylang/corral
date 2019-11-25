use "ponytest"
use "../../util"

class TestHelp is UnitTest
  fun name(): String => "integration/help"
  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h, recover ["help"] end, CheckHelp)

class CheckHelp is Checker
  fun tag apply(h: TestHelper, ar: ActionResult) =>
    h.assert_eq[I32](0, ar.exit_code)
    h.assert_true(ar.stdout.contains("usage:"))
    h.assert_true(ar.stdout.contains("Options:"))
    h.assert_true(ar.stdout.contains("Commands:"))
    h.complete(ar.exit_code == 0)
    //h.env.out.print(ar.stdout)
