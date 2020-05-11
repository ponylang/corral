use "files"
use "ponytest"
use ".."
use "../../util"

class TestClean is UnitTest
  var data: (DataClone | DataNone) = DataNone

  fun name(): String => "integration/clean/github-deep"

  fun ref set_up(h: TestHelper val) ? =>
    data = DataClone(h, "github-deep")?

  fun tear_down(h: TestHelper val) => data.cleanup(h)

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    Execute(h,
      recover [
        "clean"
        "--bundle_dir"; data.dir()
        "--all"
      ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](0, ar.exit_code())
        h.complete(ar.exit_code() == 0)
      })
