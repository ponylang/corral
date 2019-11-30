use "files"
use "ponytest"
use ".."
use "../../util"

class TestClean is UnitTest
  fun name(): String => "integration/clean-github-deep"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h, recover [
      "clean"
      "--bundle_dir"; Path.join(TestDir.path, "github-deep")
      "--all"
    ] end, CheckClean)

primitive CheckClean
  fun apply(h: TestHelper, ar: ActionResult) =>
    h.assert_eq[I32](0, ar.exit_code)
    h.complete(ar.exit_code == 0)
