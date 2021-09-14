use "ponytest"
use ".."
use "../../util"

class TestHelp is UnitTest
  fun name(): String => "integration/help"
  fun apply(h: TestHelper) =>
    h.long_test(30_000_000_000)
    Execute(h,
      recover ["help"] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](0, ar.exit_code())
        h.assert_true(ar.stdout.contains("usage:"))
        h.assert_true(ar.stdout.contains("Options:"))
        h.assert_true(ar.stdout.contains("Commands:"))
        h.complete(ar.exit_code() == 0)
      })
