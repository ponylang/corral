use "pony_test"
use ".."
use "../../util"

class  \nodoc\ TestInfo is UnitTest
  fun name(): String => "integration/info"
  fun apply(h: TestHelper) ? =>
    h.long_test(30_000_000_000)
    Execute(h,
      recover [
        "info"
        "--bundle_dir"; Data(h, "empty-deps")?.path
      ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](0, ar.exit_code())
        h.complete(ar.exit_code() == 0)
      })

class  \nodoc\ TestInfoWithoutBundle is UnitTest
  fun name(): String => "integration/info/without-bundle"
  fun apply(h: TestHelper) =>
    h.long_test(30_000_000_000)
    Execute(h,
      recover [
        "info"
        "--bundle_dir"; "nonexistant!"
      ] end,
      {(h: TestHelper, ar: ActionResult) =>
        h.assert_eq[I32](1, ar.exit_code())
        h.complete(ar.exit_code() == 1)
      })
